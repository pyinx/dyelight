import 'package:dio/dio.dart';

import '../debug_log.dart';
import '../models.dart';

/// Trims whitespace and trailing slashes so paths can be appended safely.
String normalizeBaseUrl(String url) {
  var u = url.trim();
  while (u.endsWith('/')) {
    u = u.substring(0, u.length - 1);
  }
  return u;
}

Dio createDio(AppSettings settings, String apiKey) {
  final timeout = Duration(seconds: settings.timeoutSeconds);
  final dio = Dio(
    BaseOptions(
      baseUrl: normalizeBaseUrl(settings.baseUrl),
      connectTimeout: timeout,
      sendTimeout: timeout,
      receiveTimeout: timeout,
      headers: {
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        ...settings.headers,
      },
    ),
  );
  dio.interceptors.add(DebugInterceptor(debugLog));
  return dio;
}
