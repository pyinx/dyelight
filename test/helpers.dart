import 'dart:io';
import 'dart:typed_data';

import 'package:ai_photo_colorizer/core/models.dart';
import 'package:ai_photo_colorizer/core/network/api_error.dart';
import 'package:ai_photo_colorizer/core/network/image_edit_provider.dart';
import 'package:ai_photo_colorizer/core/storage/history_repo.dart';
import 'package:ai_photo_colorizer/core/storage/secure_store.dart';
import 'package:ai_photo_colorizer/core/storage/settings_repo.dart';
import 'package:ai_photo_colorizer/state/providers.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

Uint8List pngBytes([int w = 64, int h = 48]) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

class FakeSecureStore extends SecureStore {
  FakeSecureStore() : super();
  @override
  Future<String> readApiKey() async => 'test-key';
  @override
  Future<void> writeApiKey(String key) async {}
}

class FakeProvider implements ImageEditProvider {
  FakeProvider(this.onEdit);
  final Future<EditResult> Function(EditRequest, CancelToken) onEdit;
  @override
  Future<EditResult> edit(EditRequest r, CancelToken t) => onEdit(r, t);
  @override
  Future<ConnectionReport> testConnection() async =>
      const ConnectionReport(reachable: true, authOk: true);
}

Future<List<Override>> testOverrides(
  Directory dir,
  ProviderFactory factory,
) async {
  await Hive.close(); // boxes are cached by name across tests
  Hive.init(dir.path);
  final sb = await Hive.openBox<dynamic>('settings');
  final hb = await Hive.openBox<dynamic>('history');
  return [
    settingsRepoProvider.overrideWithValue(SettingsRepo(sb)),
    historyRepoProvider.overrideWithValue(
      HistoryRepo(hb, Directory('${dir.path}/history')),
    ),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    providerFactoryProvider.overrideWithValue(factory),
    endpointDetectorProvider.overrideWithValue(
      (_, _) async => EndpointStyle.imagesEdits,
    ),
  ];
}

ApiError cancelled() => const ApiError(ApiErrorType.cancelled);
