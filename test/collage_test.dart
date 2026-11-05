import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_photo_colorizer/features/collage/collage_renderer.dart';
import 'package:ai_photo_colorizer/features/collage/collage_spec.dart';
import 'package:ai_photo_colorizer/features/home/templates.dart';
import 'package:ai_photo_colorizer/state/collage_providers.dart';
import 'package:ai_photo_colorizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('layouts: slots match cells and rects stay inside the area', () {
    const area = ui.Rect.fromLTWH(10, 20, 300, 400);
    for (final l in CollageLayout.values) {
      expect(l.slots, l.cells.length);
      final rects = l.rects(area, 8);
      expect(rects, hasLength(l.slots));
      for (final r in rects) {
        expect(r.left, greaterThanOrEqualTo(area.left - 0.01));
        expect(r.right, lessThanOrEqualTo(area.right + 0.01));
        expect(r.bottom, lessThanOrEqualTo(area.bottom + 0.01));
        expect(r.width, greaterThan(0));
      }
    }
    expect(CollageLayout.grid9.slots, 9);
    expect(CollageLayout.grid4.slots, 4);
    expect(CollageLayout.leftRight.rects(area, 0)[1].left, 160);
  });

  test('smart layout fits every count 1..9 and follows orientation', () {
    const land = ui.Size(400, 300), port = ui.Size(300, 400);
    for (var n = 1; n <= 9; n++) {
      final l = smartLayout(List.filled(n, land));
      expect(l.slots, n, reason: '$n photos');
    }
    expect(smartLayout([land, land]), CollageLayout.topBottom);
    expect(smartLayout([port, land]), CollageLayout.leftRight);
    expect(smartLayout([port, port, port]), CollageLayout.threeCols);
    expect(smartLayout([port, land, land]), CollageLayout.bigLeft);
    expect(smartLayout([land, port, port]), CollageLayout.bigTop);
  });

  test('collageCells matches what the renderer places', () {
    const spec = CollageSpec(
      auto: false,
      layout: CollageLayout.grid4,
      title: 'x',
    );
    final c = collageCells(spec);
    expect(c.rects, hasLength(4));
    expect(c.size.width, kCollageBase);
    for (final r in c.rects) {
      expect(r.right, lessThanOrEqualTo(c.size.width));
      expect(r.bottom, lessThanOrEqualTo(c.size.height));
    }
    // A title pushes the grid down.
    expect(
      c.rects.first.top,
      greaterThan(collageCells(spec.copyWith(title: '')).rects.first.top),
    );
  });

  test('spec JSON round-trips and tolerates junk', () {
    const s = CollageSpec(
      layout: CollageLayout.bigLeft,
      style: CollageStyle.swiss,
      title: 't',
      ratio: 2,
      gap: 3,
    );
    final r = CollageSpec.fromJson(s.toJson());
    expect(r.layout, CollageLayout.bigLeft);
    expect(r.style, CollageStyle.swiss);
    expect(r.title, 't');
    expect(r.ratio, 2);
    expect(CollageSpec.fromJson(const {}).auto, isFalse);
    expect(CollageSpec.fromJson(const CollageSpec().toJson()).auto, isTrue);
    final bad = CollageSpec.fromJson({'layout': 'nope', 'ratio': 99});
    expect(bad.layout, const CollageSpec().layout);
    expect(bad.ratio, kCollageRatios.length - 1);
  });

  test('every style renders a PNG with the expected size', () async {
    final img = await decodeCollageImage(pngBytes(120, 80));
    for (final style in CollageStyle.values) {
      final spec = CollageSpec(
        style: style,
        layout: CollageLayout.grid4,
        title: '标题 Title',
        subtitle: 'sub',
      );
      final png = await renderCollage(spec, [img, img, img], outWidth: 540);
      final out = await decodeCollageImage(png);
      expect(out.width, 540, reason: style.name);
      final want = switch (style) {
        CollageStyle.moments => 540,
        _ => 720,
      };
      expect(out.height, want, reason: style.name);
    }
  });

  test('templates: every category has bilingual, non-empty entries', () {
    for (final c in kTemplateCategories) {
      expect(c.items, isNotEmpty);
      for (final t in c.items) {
        expect(t.zhPrompt, isNotEmpty);
        expect(t.enPrompt, isNotEmpty);
        expect(t.zh, isNotEmpty);
      }
    }
  });

  group('history + controllers', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('collage'));
    tearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('collage export is stored and can be reloaded', () async {
      final c = ProviderContainer(
        overrides: await testOverrides(
          dir,
          (_, _) => throw UnimplementedError(),
        ),
      );
      addTearDown(c.dispose);
      final n = c.read(collageProvider.notifier);
      await n.add([pngBytes(), pngBytes(), pngBytes(), pngBytes()]);
      expect(c.read(collageProvider).sources, hasLength(4));
      n.setSpec(const CollageSpec(title: 'trip'));
      final png = await n.export();
      expect(png, isNotEmpty);
      final e = c.read(historyProvider).single;
      expect(e.isCollage, isTrue);
      expect(e.sourcePaths, hasLength(4));
      expect(CollageSpec.fromJson(e.spec!).title, 'trip');
      expect(File(e.resultPath).existsSync(), isTrue);

      await c.read(historyProvider.notifier).delete(e);
      expect(File(e.sourcePaths.first).existsSync(), isFalse);
      expect(File(e.resultPath).existsSync(), isFalse);
    });

    test('add caps at nine, move/remove work, missing counts', () async {
      final c = ProviderContainer(
        overrides: await testOverrides(
          dir,
          (_, _) => throw UnimplementedError(),
        ),
      );
      addTearDown(c.dispose);
      final n = c.read(collageProvider.notifier);
      await n.add([for (var i = 0; i < 12; i++) pngBytes(8 + i, 8)]);
      expect(c.read(collageProvider).sources, hasLength(kCollageMaxPhotos));
      n.removeAt(0);
      expect(c.read(collageProvider).sources, hasLength(8));
      final second = c.read(collageProvider).sources[1];
      n.moveEarlier(1);
      expect(c.read(collageProvider).sources.first, second);
      n.setSpec(const CollageSpec(auto: false, layout: CollageLayout.grid9));
      expect(c.read(collageProvider).missing, 1);
      n.setSpec(const CollageSpec());
      expect(c.read(collageProvider).missing, 0);
      expect(c.read(collageProvider).effective.layout, CollageLayout.grid8);
      final a = c.read(collageProvider).sources[0];
      final b = c.read(collageProvider).sources[3];
      n.swap(0, 3);
      expect(c.read(collageProvider).sources[0], b);
      expect(c.read(collageProvider).sources[3], a);
    });

    test(
      'recolor entries keep working and continueFrom resets prompt',
      () async {
        final c = ProviderContainer(
          overrides: await testOverrides(
            dir,
            (_, _) => throw UnimplementedError(),
          ),
        );
        addTearDown(c.dispose);
        await c
            .read(editProvider.notifier)
            .continueFrom(pngBytes(), prompt: 'warm');
        final s = c.read(editProvider);
        expect(s.source, isNotNull);
        expect(s.auto, isFalse);
        expect(s.prompt, 'warm');
        await Hive.close();
      },
    );
  });
}
