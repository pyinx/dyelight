import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models.dart';
import 'api_error.dart';
import 'image_edit_provider.dart';

/// Shared plumbing for OpenAI-compatible providers: connection test,
/// image download and DioException mapping.
abstract class OpenAiProviderBase implements ImageEditProvider {
  OpenAiProviderBase(this.dio, this.settings, {Dio? downloader})
    : downloader = downloader ?? Dio();

  final Dio dio;
  final AppSettings settings;

  /// Used for result URLs; deliberately carries no API key.
  final Dio downloader;

  Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<Uint8List> fetchUrl(String url, CancelToken token) => guard(() async {
    final res = await downloader.get<List<int>>(
      url,
      cancelToken: token,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: Duration(seconds: settings.timeoutSeconds),
      ),
    );
    return Uint8List.fromList(res.data!);
  });

  /// Reads `data[0].b64_json` (or downloads `data[0].url`) from an
  /// images-API response.
  Future<EditResult> imageFromData(
    Response<dynamic> res,
    CancelToken token,
  ) async {
    final data = res.data;
    final list = data is Map ? data['data'] : null;
    final first = list is List && list.isNotEmpty ? list.first : null;
    if (first is Map) {
      if (first['b64_json'] is String) {
        return EditResult(decodeBase64(first['b64_json'] as String));
      }
      if (first['url'] is String) {
        return EditResult(await fetchUrl(first['url'] as String, token));
      }
    }
    final s = data.toString();
    throw ApiError(
      ApiErrorType.badResponse,
      message: s.length > 200 ? '${s.substring(0, 200)}…' : s,
      statusCode: res.statusCode,
    );
  }

  Uint8List decodeBase64(String b64) {
    final cleaned = b64.contains(',') ? b64.split(',').last : b64;
    return base64Decode(cleaned.replaceAll(RegExp(r'\s'), ''));
  }

  @override
  Future<ConnectionReport> testConnection() async {
    try {
      final res = await dio.get<dynamic>('/models');
      final data = res.data;
      bool? listed;
      if (data is Map && data['data'] is List) {
        final ids = (data['data'] as List)
            .whereType<Map>()
            .map((m) => m['id']?.toString())
            .toSet();
        listed = ids.contains(settings.model);
      }
      return ConnectionReport(
        reachable: true,
        authOk: true,
        modelListed: listed,
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        return ConnectionReport(
          reachable: true,
          authOk: true,
          statusCode: code,
        );
      }
      if (code == 401 || code == 403) {
        return ConnectionReport(
          reachable: true,
          authOk: false,
          statusCode: code,
          detail: extractServerMessage(e.response?.data),
        );
      }
      if (code != null) {
        return ConnectionReport(
          reachable: true,
          authOk: true,
          statusCode: code,
          detail: extractServerMessage(e.response?.data),
        );
      }
      final err = ApiError.fromDio(e);
      return ConnectionReport(
        reachable: false,
        authOk: false,
        detail: err.type == ApiErrorType.timeout ? 'timeout' : err.message,
      );
    }
  }
}
