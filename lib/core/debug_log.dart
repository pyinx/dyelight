import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';

/// In-memory request/response trace, shown in Settings when debug mode is on.
/// Never records the API key; large payloads (base64 images) are shortened.
class DebugLog {
  DebugLog({this.maxEntries = 300});

  final int maxEntries;

  /// Mirrors [AppSettings.debug]; while false, nothing is recorded.
  bool enabled = false;

  final ValueNotifier<List<String>> entries = ValueNotifier(const []);

  void add(String message) {
    if (!enabled) return;
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
    final next = [...entries.value, '[$stamp] $message'];
    entries.value = next.length > maxEntries
        ? next.sublist(next.length - maxEntries)
        : next;
  }

  void clear() => entries.value = const [];

  /// Plain-text report for pasting into a bug report. Contains no secrets.
  String report(AppSettings s, {String appVersion = ''}) => [
    'Dyelight debug report',
    if (appVersion.isNotEmpty) 'version: $appVersion',
    'provider: ${s.providerId}',
    'baseUrl: ${s.baseUrl}',
    'model: ${s.model}',
    'interface: ${s.endpointStyle?.name ?? 'undetected'}',
    'timeout: ${s.timeoutSeconds}s',
    '---',
    ...entries.value,
  ].join('\n');
}

/// App-wide instance; the settings notifier toggles [DebugLog.enabled].
final DebugLog debugLog = DebugLog();

bool _secretHeader(String name) {
  final n = name.toLowerCase();
  return n.contains('auth') ||
      n.contains('key') ||
      n.contains('token') ||
      n.contains('secret') ||
      n.contains('cookie');
}

String maskSecret(String v) {
  final parts = v.split(' ');
  final tail = parts.last;
  final shown = tail.length > 8
      ? '${tail.substring(0, 3)}…${tail.substring(tail.length - 4)}'
      : '***';
  return parts.length > 1 ? '${parts.first} $shown' : shown;
}

Object? shorten(Object? v, [int depth = 0]) {
  if (v is String) {
    return v.length > 200 ? '${v.substring(0, 80)}…(${v.length} chars)' : v;
  }
  if (v is Uint8List || (v is List && v.isNotEmpty && v.first is int)) {
    return '<binary ${(v as List).length} bytes>';
  }
  if (depth > 6) return '…';
  if (v is Map) {
    return v.map((k, x) => MapEntry(k.toString(), shorten(x, depth + 1)));
  }
  if (v is List) {
    final head = v.take(20).map((x) => shorten(x, depth + 1)).toList();
    return v.length > 20 ? [...head, '…(${v.length} items)'] : head;
  }
  if (v is FormData) {
    return {
      'form': {for (final f in v.fields) f.key: shorten(f.value)},
      'files': [
        for (final f in v.files)
          '${f.key}: ${f.value.filename} (${f.value.length} bytes)',
      ],
    };
  }
  return v;
}

String describe(Object? v, {int max = 1500}) {
  if (v == null) return '<empty>';
  String s;
  try {
    final x = shorten(v);
    s = x is String ? x : jsonEncode(x, toEncodable: (o) => o.toString());
  } catch (_) {
    s = v.toString();
  }
  return s.length > max ? '${s.substring(0, max)}…' : s;
}

class DebugInterceptor extends Interceptor {
  DebugInterceptor(this.log);
  final DebugLog log;

  static const _startKey = 'debug_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (log.enabled) {
      options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
      final headers = options.headers.map(
        (k, v) => MapEntry(k, _secretHeader(k) ? maskSecret('$v') : v),
      );
      log.add(
        '→ ${options.method} ${options.uri}\n   headers: ${describe(headers)}\n   body: ${describe(options.data)}',
      );
    }
    handler.next(options);
  }

  int _ms(RequestOptions options) {
    final s = options.extra[_startKey];
    return s is int ? DateTime.now().millisecondsSinceEpoch - s : -1;
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (log.enabled) {
      log.add(
        '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri} (${_ms(response.requestOptions)}ms)\n   body: ${describe(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (log.enabled) {
      final r = err.response;
      log.add(
        '✗ ${err.type.name} ${err.requestOptions.method} ${err.requestOptions.uri} (${_ms(err.requestOptions)}ms)'
        '${r == null ? '' : '\n   status: ${r.statusCode}\n   body: ${describe(r.data)}'}'
        '${err.message == null ? '' : '\n   message: ${err.message}'}',
      );
    }
    handler.next(err);
  }
}
