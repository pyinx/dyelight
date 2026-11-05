import 'package:dio/dio.dart';

import '../debug_log.dart';
import '../models.dart';
import 'api_error.dart';

final _imageHint = RegExp(
  r'image|dall|flux|seedream|seededit|edit|kolors|stable|sdxl|cogview',
  caseSensitive: false,
);

bool looksLikeImageModel(String id) => _imageHint.hasMatch(id);

/// `GET /models`, normalized to bare ids, image-looking models first.
Future<List<String>> fetchModelIds(Dio dio) async {
  try {
    final res = await dio.get<dynamic>('/models');
    final d = res.data;
    final list = d is Map ? (d['data'] ?? d['models']) : d;
    final ids = <String>{};
    if (list is List) {
      for (final e in list) {
        final raw = e is Map ? (e['id'] ?? e['name']) : e;
        if (raw is String && raw.isNotEmpty) {
          ids.add(raw.startsWith('models/') ? raw.substring(7) : raw);
        }
      }
    }
    final out = ids.toList()..sort();
    return [
      ...out.where(looksLikeImageModel),
      ...out.where((m) => !looksLikeImageModel(m)),
    ];
  } on DioException catch (e) {
    throw ApiError.fromDio(e);
  }
}

const _missing = {404, 405, 501};

/// Finds which image-editing API the server speaks by sending each one an
/// empty request: a real route answers 400/401/422, a missing one 404/405.
/// No image is sent and nothing is generated. Returns null if none exists.
Future<EndpointStyle?> detectEndpointStyle(Dio dio, String model) async {
  final probe = Options(
    validateStatus: (_) => true,
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  );

  bool exists(Response<dynamic> r) {
    if (_missing.contains(r.statusCode)) return false;
    final d = r.data;
    // A catch-all SPA/relay page is not an API route.
    return !(d is String && d.toLowerCase().contains('<html'));
  }

  try {
    final edits = exists(
      await dio.post<dynamic>(
        '/images/edits',
        data: FormData.fromMap({'model': model}),
        options: probe,
      ),
    );
    final gen = exists(
      await dio.post<dynamic>(
        '/images/generations',
        data: {'model': model},
        options: probe,
      ),
    );
    final chat = exists(
      await dio.post<dynamic>(
        '/chat/completions',
        data: {'model': model, 'messages': <dynamic>[]},
        options: probe,
      ),
    );
    // An image-named model prefers an images API over chat when both exist.
    final imagey = looksLikeImageModel(model) && !model.contains('gemini');
    EndpointStyle? pick;
    if (edits && (imagey || !chat)) {
      pick = EndpointStyle.imagesEdits;
    } else if (gen && (imagey || !chat)) {
      pick = EndpointStyle.imagesGenerations;
    } else if (chat) {
      pick = EndpointStyle.chatCompletions;
    } else if (edits) {
      pick = EndpointStyle.imagesEdits;
    } else if (gen) {
      pick = EndpointStyle.imagesGenerations;
    }
    debugLog.add(
      'detect: edits=$edits generations=$gen chat=$chat model=$model → ${pick?.name ?? 'none'}',
    );
    return pick;
  } on DioException catch (e) {
    throw ApiError.fromDio(e);
  }
}
