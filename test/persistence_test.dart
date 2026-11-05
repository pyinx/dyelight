import 'dart:io';

import 'package:ai_photo_colorizer/core/models.dart';
import 'package:ai_photo_colorizer/core/storage/history_repo.dart';
import 'package:ai_photo_colorizer/core/storage/secure_store.dart';
import 'package:ai_photo_colorizer/core/storage/settings_repo.dart';
import 'package:ai_photo_colorizer/state/providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'helpers.dart';

class _Throwing extends FlutterSecureStorage {
  const _Throwing();
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw PlatformException(code: 'keystore');
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('persist'));
  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'settings written by v1.0.0 (no debug/auto fields) still load',
    () async {
      Hive.init(dir.path);
      final box = await Hive.openBox<dynamic>('settings');
      // Exactly what 1.0.x stored: no `debug`, a since-renamed-free enum name.
      await box.put('settings', {
        'providerId': 'volcengine',
        'baseUrl': 'https://ark.cn-beijing.volces.com/api/v3',
        'model': 'doubao-seedream-4-0',
        'timeoutSeconds': 90,
        'headers': {'X-A': '1'},
        'temperature': 0.5,
        'endpointStyle': 'imagesEdits',
        'localeCode': 'zh',
      });
      await Hive.close();

      Hive.init(dir.path);
      final s = SettingsRepo(await Hive.openBox<dynamic>('settings')).load();
      expect(s.providerId, 'volcengine');
      expect(s.baseUrl, 'https://ark.cn-beijing.volces.com/api/v3');
      expect(s.model, 'doubao-seedream-4-0');
      expect(s.timeoutSeconds, 90);
      expect(s.headers, {'X-A': '1'});
      expect(s.temperature, 0.5);
      expect(s.endpointStyle, EndpointStyle.imagesEdits);
      expect(s.localeCode, 'zh');
      expect(s.debug, isFalse);
    },
  );

  test('unknown future fields and endpoints are ignored, not fatal', () {
    final s = AppSettings.fromJson({
      'baseUrl': 'http://x/v1',
      'endpointStyle': 'someFutureStyle',
      'brandNewField': 1,
    });
    expect(s.baseUrl, 'http://x/v1');
    expect(s.endpointStyle, isNull);
  });

  test('history written by older versions loads without new fields', () {
    final e = HistoryEntry.fromJson({
      'id': '1',
      'createdAt': 1700000000000,
      'prompt': 'warm',
      'auto': false,
      'originalPath': '/o.jpg',
      'resultPath': '/r.png',
    });
    expect(e.name, '');
    expect(e.isCollage, isFalse);
    expect(e.sourcePaths, isEmpty);
    expect(e.prompt, 'warm');
  });

  test('an unreadable keystore means "no key", not a crash', () async {
    expect(await SecureStore(const _Throwing()).readApiKey(), '');
  });

  test('rename persists across reopen; empty name restores default', () async {
    final c = ProviderContainer(
      overrides: await testOverrides(dir, (_, _) => throw UnimplementedError()),
    );
    final repo = c.read(historyRepoProvider);
    final e = await repo.add(
      original: pngBytes(),
      result: pngBytes(),
      prompt: 'p',
      auto: false,
    );
    c.read(historyProvider.notifier).refresh();
    await c.read(historyProvider.notifier).rename(e, '  Holiday  ');
    expect(c.read(historyProvider).single.name, 'Holiday');
    c.dispose();

    final c2 = ProviderContainer(
      overrides: await testOverrides(dir, (_, _) => throw UnimplementedError()),
    );
    addTearDown(c2.dispose);
    final again = c2.read(historyProvider).single;
    expect(again.name, 'Holiday');
    await c2.read(historyProvider.notifier).rename(again, '');
    expect(c2.read(historyProvider).single.name, '');
  });

  test('HistoryFilter: kind and inclusive day range', () {
    HistoryEntry at(DateTime t, {bool collage = false}) => HistoryEntry(
      id: '${t.microsecondsSinceEpoch}',
      createdAt: t,
      prompt: '',
      auto: false,
      originalPath: '',
      resultPath: '',
      spec: collage ? const {} : null,
    );
    final mon = at(DateTime(2026, 11, 2, 23, 59));
    final tue = at(DateTime(2026, 11, 3, 0, 1), collage: true);
    expect(const HistoryFilter().matches(mon), isTrue);
    expect(const HistoryFilter(kind: true).matches(mon), isFalse);
    expect(const HistoryFilter(kind: true).matches(tue), isTrue);
    expect(const HistoryFilter(kind: false).matches(tue), isFalse);
    final f = HistoryFilter(
      from: DateTime(2026, 11, 2),
      to: DateTime(2026, 11, 2),
    );
    expect(f.matches(mon), isTrue); // last minute of the end day counts
    expect(f.matches(tue), isFalse);
    expect(HistoryFilter(from: DateTime(2026, 11, 3)).matches(mon), isFalse);
  });
}
