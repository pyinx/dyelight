import 'dart:io';

import 'package:ai_photo_colorizer/core/models.dart';
import 'package:ai_photo_colorizer/core/network/api_error.dart';
import 'package:ai_photo_colorizer/core/network/photo_analyzer.dart';
import 'package:ai_photo_colorizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('edit_ctrl'));
  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  Future<ProviderContainer> container(
    FakeProvider p, {
    PhotoAnalyzer? analyzer,
  }) async {
    final c = ProviderContainer(
      overrides: [
        ...await testOverrides(dir, (_, _) => p),
        if (analyzer != null) photoAnalyzerProvider.overrideWithValue(analyzer),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  const smart = (ask: 'ASK', keep: 'KEEP');

  Future<void> useVisionModel(ProviderContainer c) => c
      .read(settingsProvider.notifier)
      .update(c.read(settingsProvider).copyWith(visionModel: 'vision-1'));

  test(
    'success: sends key-bearing request, stores result and history',
    () async {
      EditRequest? seen;
      final c = await container(
        FakeProvider((r, t) async {
          seen = r;
          return EditResult(pngBytes(8, 8));
        }),
      );
      final ctrl = c.read(editProvider.notifier);
      await ctrl.setImage(pngBytes(100, 80));
      expect(c.read(editProvider).source, isNotNull);

      await ctrl.generate('make it warm');
      final s = c.read(editProvider);
      expect(s.status, EditStatus.done);
      expect(s.result, isNotNull);
      expect(seen!.prompt, 'make it warm');
      expect(seen!.mimeType, 'image/jpeg');
      expect(c.read(historyProvider), hasLength(1));
    },
  );

  test('cancel returns to idle without error', () async {
    final c = await container(
      FakeProvider((r, t) async {
        await t.whenCancel;
        throw cancelled();
      }),
    );
    final ctrl = c.read(editProvider.notifier);
    await ctrl.setImage(pngBytes());
    final fut = ctrl.generate('x');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.read(editProvider).status, EditStatus.generating);
    ctrl.cancel();
    await fut;
    expect(c.read(editProvider).status, EditStatus.idle);
    expect(c.read(editProvider).error, isNull);
    expect(c.read(historyProvider), isEmpty);
  });

  test('API error surfaces as failed state, source kept for retry', () async {
    final c = await container(
      FakeProvider((r, t) async => throw const ApiError(ApiErrorType.timeout)),
    );
    final ctrl = c.read(editProvider.notifier);
    await ctrl.setImage(pngBytes());
    await ctrl.generate('x');
    final s = c.read(editProvider);
    expect(s.status, EditStatus.failed);
    expect(s.error!.type, ApiErrorType.timeout);
    expect(s.source, isNotNull);
    ctrl.ackError();
    expect(c.read(editProvider).status, EditStatus.idle);
  });

  test('corrupt image sets imageError and keeps no source', () async {
    final c = await container(FakeProvider((r, t) async => throw cancelled()));
    await c.read(editProvider.notifier).setImage(pngBytes().sublist(0, 5));
    expect(c.read(editProvider).imageError, isTrue);
    expect(c.read(editProvider).source, isNull);
  });

  test('backToEdit keeps prompt and mode for tweak', () async {
    final c = await container(
      FakeProvider((r, t) async => EditResult(pngBytes(8, 8))),
    );
    final ctrl = c.read(editProvider.notifier);
    await ctrl.setImage(pngBytes());
    ctrl
      ..setAuto(false)
      ..setPrompt('golden hour');
    await ctrl.generate('golden hour');
    ctrl.backToEdit();
    final s = c.read(editProvider);
    expect(
      (s.status, s.auto, s.prompt, s.result),
      (EditStatus.idle, false, 'golden hour', null),
    );
    expect(s.source, isNotNull);
  });

  group('smart analysis', () {
    test('vision model brief plus keep replaces the fallback prompt', () async {
      EditRequest? asked, edited;
      final statuses = <EditStatus>[];
      final c = await container(
        FakeProvider((r, t) async {
          edited = r;
          return EditResult(pngBytes(8, 8));
        }),
        analyzer: (s, k, r, t) async {
          asked = r;
          expect(s.visionModel, 'vision-1');
          return 'warm the red coat, blur the crowd';
        },
      );
      c.listen(editProvider.select((e) => e.status), (_, n) => statuses.add(n));
      await useVisionModel(c);
      final ctrl = c.read(editProvider.notifier);
      await ctrl.setImage(pngBytes());
      await ctrl.generate('FALLBACK', analysis: smart);
      expect(asked!.prompt, 'ASK');
      expect(asked!.imageBytes, isNotEmpty);
      expect(edited!.prompt, 'warm the red coat, blur the crowd\nKEEP');
      expect(
        statuses,
        containsAllInOrder([
          EditStatus.analyzing,
          EditStatus.generating,
          EditStatus.done,
        ]),
      );
    });

    test('analysis failure falls back to the built-in prompt', () async {
      EditRequest? edited;
      final c = await container(
        FakeProvider((r, t) async {
          edited = r;
          return EditResult(pngBytes(8, 8));
        }),
        analyzer: (_, _, _, _) async =>
            throw const ApiError(ApiErrorType.badResponse, statusCode: 400),
      );
      await useVisionModel(c);
      final ctrl = c.read(editProvider.notifier);
      await ctrl.setImage(pngBytes());
      await ctrl.generate('FALLBACK', analysis: smart);
      expect(edited!.prompt, 'FALLBACK');
      expect(c.read(editProvider).status, EditStatus.done);
    });

    test('without a vision model the analyzer is not called', () async {
      EditRequest? edited;
      final c = await container(
        FakeProvider((r, t) async {
          edited = r;
          return EditResult(pngBytes(8, 8));
        }),
        analyzer: (_, _, _, _) async => fail('should not analyze'),
      );
      final ctrl = c.read(editProvider.notifier);
      await ctrl.setImage(pngBytes());
      await ctrl.generate('FALLBACK', analysis: smart);
      expect(edited!.prompt, 'FALLBACK');
    });

    test('cancel during analysis returns to idle without generating', () async {
      var generated = false;
      final c = await container(
        FakeProvider((r, t) async {
          generated = true;
          return EditResult(pngBytes(8, 8));
        }),
        analyzer: (_, _, _, t) async {
          await t.whenCancel;
          throw cancelled();
        },
      );
      await useVisionModel(c);
      final ctrl = c.read(editProvider.notifier);
      await ctrl.setImage(pngBytes());
      final fut = ctrl.generate('FALLBACK', analysis: smart);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(editProvider).status, EditStatus.analyzing);
      ctrl.cancel();
      await fut;
      expect(c.read(editProvider).status, EditStatus.idle);
      expect(generated, isFalse);
      expect(c.read(historyProvider), isEmpty);
    });
  });

  test('chatText reads string or part content and drops think blocks', () {
    Map<String, dynamic> body(Object content) => {
      'choices': [
        {
          'message': {'content': content},
        },
      ],
    };
    expect(
      chatText(body('<think>hmm</think>\n Warm the sky. ')),
      'Warm the sky.',
    );
    expect(
      chatText(
        body([
          {'type': 'text', 'text': 'a'},
          {'type': 'text', 'text': 'b'},
        ]),
      ),
      'a\nb',
    );
    expect(chatText({'error': 'x'}), '');
  });
}
