import 'dart:io';

import 'package:ai_photo_colorizer/app.dart';
import 'package:ai_photo_colorizer/features/result/compare_viewer.dart';
import 'package:ai_photo_colorizer/features/settings/settings_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'helpers.dart';

void main() {
  test('parseHeaders / formatHeaders', () {
    final h = parseHeaders('X-A: 1\nbad line\n  X-B :  two:parts \n');
    expect(h, {'X-A': '1', 'X-B': 'two:parts'});
    expect(parseHeaders(formatHeaders(h)), h);
  });

  testWidgets('CompareViewer: divider drag + semantics + long press', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      CupertinoApp(
        home: CompareViewer(original: pngBytes(), result: pngBytes()),
      ),
    );
    await tester.pump();

    SemanticsNode node() => tester.getSemantics(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.slider == true,
      ),
    );
    expect(node().value, '50%');

    final size = tester.getSize(find.byType(CompareViewer));
    await tester.dragFrom(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width * 0.2, 0),
    );
    await tester.pump();
    // Drag moves the divider right (touch slop eats a few pixels).
    final afterDrag = int.parse(node().value.replaceAll('%', ''));
    expect(afterDrag, inInclusiveRange(65, 70));

    // Assistive-technology decrement moves it back by 10 points.
    tester.semantics.performAction(
      find.semantics.byFlag(SemanticsFlag.isSlider),
      SemanticsAction.decrease,
    );
    await tester.pump();
    expect(node().value, '${afterDrag - 10}%');

    final g = await tester.startGesture(const Offset(20, 300));
    await tester.pump(const Duration(milliseconds: 700));
    await g.up();
    await tester.pump();
    handle.dispose();
  });

  testWidgets('App shows empty state and tabs', (tester) async {
    final dir = Directory.systemTemp.createTempSync('ui');
    addTearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });
    final overrides = await tester.runAsync(
      () => testOverrides(
        dir,
        (_, _) => FakeProvider((r, t) async => throw cancelled()),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(overrides: overrides!, child: const App()),
    );
    await tester.pump();
    // Create tab is the landing page with an entry for each tool.
    expect(find.text('Give every photo its light'), findsOneWidget);
    expect(find.text('Start recoloring'), findsOneWidget);
    expect(find.text('Start a collage'), findsOneWidget);
    await tester.tap(find.text('Start recoloring'));
    await tester.pumpAndSettle();
    expect(find.text('Bring your photos to life'), findsOneWidget);
    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start a collage'));
    await tester.pumpAndSettle();
    expect(find.text('Combine photos into one image'), findsOneWidget);
    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Test Connection'), findsOneWidget);
  });
}
