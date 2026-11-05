import 'package:ai_photo_colorizer/core/models.dart';
import 'package:ai_photo_colorizer/core/network/api_client.dart';
import 'package:ai_photo_colorizer/core/network/discovery.dart';
import 'package:ai_photo_colorizer/core/providers_preset.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

({Dio dio, DioAdapter a}) _make() {
  final dio = createDio(const AppSettings(), 'k');
  return (dio: dio, a: DioAdapter(dio: dio));
}

void main() {
  test('presets stay under 10 and have unique ids', () {
    expect(kProviderPresets.length, lessThan(10));
    expect(
      kProviderPresets.map((p) => p.id).toSet().length,
      kProviderPresets.length,
    );
    expect(presetById('openai')!.baseUrl, startsWith('https://'));
    expect(presetById(kCustomProviderId), isNull);
  });

  test('settings: old saved data without providerId becomes custom', () {
    final s = AppSettings.fromJson({'baseUrl': 'http://192.168.1.2/v1'});
    expect(s.providerId, kCustomProviderId);
    expect(s.endpointStyle, isNull);
    final r = AppSettings.fromJson(
      const AppSettings(endpointStyle: EndpointStyle.chatCompletions).toJson(),
    );
    expect(r.endpointStyle, EndpointStyle.chatCompletions);
    expect(r.copyWith(clearEndpoint: true).endpointStyle, isNull);
  });

  test('settings: debug defaults off and round-trips', () {
    expect(const AppSettings().debug, isFalse);
    expect(AppSettings.fromJson(const {}).debug, isFalse);
    expect(
      AppSettings.fromJson(const AppSettings(debug: true).toJson()).debug,
      isTrue,
    );
  });

  group('fetchModelIds', () {
    test('normalizes ids, dedupes, image models first', () async {
      final m = _make();
      m.a.onGet(
        '/models',
        (s) => s.reply(200, {
          'data': [
            {'id': 'gpt-4o'},
            {'id': 'models/gemini-2.5-flash-image'},
            {'id': 'gpt-4o'},
            {'id': 'gpt-image-1'},
          ],
        }),
      );
      expect(await fetchModelIds(m.dio), [
        'gemini-2.5-flash-image',
        'gpt-image-1',
        'gpt-4o',
      ]);
    });

    test('accepts {models:[{name}]} and bare lists', () async {
      final m = _make();
      m.a.onGet(
        '/models',
        (s) => s.reply(200, {
          'models': [
            {'name': 'a'},
          ],
        }),
      );
      expect(await fetchModelIds(m.dio), ['a']);
    });
  });

  group('detectEndpointStyle', () {
    void routes(_Mk m, int edits, int chat, [int gen = 404]) {
      m.a.onPost(
        '/images/edits',
        (s) => s.reply(edits, {}),
        data: Matchers.any,
      );
      m.a.onPost(
        '/images/generations',
        (s) => s.reply(gen, {}),
        data: Matchers.any,
      );
      m.a.onPost(
        '/chat/completions',
        (s) => s.reply(chat, {}),
        data: Matchers.any,
      );
    }

    test('only edits route exists', () async {
      final m = _make();
      routes(m, 400, 404);
      expect(await detectEndpointStyle(m.dio, 'x'), EndpointStyle.imagesEdits);
    });

    test('only chat route exists', () async {
      final m = _make();
      routes(m, 404, 400);
      expect(
        await detectEndpointStyle(m.dio, 'x'),
        EndpointStyle.chatCompletions,
      );
    });

    test('both exist: image-named model uses edits, others chat', () async {
      final m = _make();
      routes(m, 422, 400);
      expect(
        await detectEndpointStyle(m.dio, 'gpt-image-1'),
        EndpointStyle.imagesEdits,
      );
      expect(
        await detectEndpointStyle(m.dio, 'gemini-2.5-flash-image'),
        EndpointStyle.chatCompletions,
      );
      expect(
        await detectEndpointStyle(m.dio, 'gpt-4o'),
        EndpointStyle.chatCompletions,
      );
    });

    test('only generations route exists (Seedream)', () async {
      final m = _make();
      routes(m, 404, 404, 400);
      expect(
        await detectEndpointStyle(m.dio, 'doubao-seedream-4-0'),
        EndpointStyle.imagesGenerations,
      );
    });

    test('generations + chat: image model picks generations', () async {
      final m = _make();
      routes(m, 404, 400, 400);
      expect(
        await detectEndpointStyle(m.dio, 'doubao-seedream-4-0'),
        EndpointStyle.imagesGenerations,
      );
      expect(
        await detectEndpointStyle(m.dio, 'gpt-4o'),
        EndpointStyle.chatCompletions,
      );
    });

    test('neither exists => null', () async {
      final m = _make();
      routes(m, 404, 405);
      expect(await detectEndpointStyle(m.dio, 'x'), isNull);
    });
  });
}

typedef _Mk = ({Dio dio, DioAdapter a});
