import 'dart:convert';

import 'package:dio/dio.dart';

import '../models.dart';
import 'api_error.dart';
import 'openai_provider_base.dart';

/// `POST {base}/chat/completions` with an image_url content part.
class ChatCompletionsProvider extends OpenAiProviderBase {
  ChatCompletionsProvider(super.dio, super.settings, {super.downloader});

  static final _dataUrl = RegExp(
    r'data:image/[a-zA-Z0-9.+-]+;base64,[A-Za-z0-9+/=\s]+',
  );
  static final _httpUrl = RegExp(r'https?://[^\s)\]">]+');

  @override
  Future<EditResult> edit(EditRequest req, CancelToken token) =>
      guard(() async {
        final b64 = base64Encode(req.imageBytes);
        final res = await dio.post<dynamic>(
          '/chat/completions',
          cancelToken: token,
          data: {
            'model': settings.model,
            'temperature': settings.temperature,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': req.prompt},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:${req.mimeType};base64,$b64'},
                  },
                ],
              },
            ],
          },
        );
        final url = extractImageRef(res.data);
        if (url == null) {
          final s = res.data.toString();
          throw ApiError(
            ApiErrorType.badResponse,
            message: s.length > 200 ? '${s.substring(0, 200)}…' : s,
            statusCode: res.statusCode,
          );
        }
        if (url.startsWith('data:')) return EditResult(decodeBase64(url));
        return EditResult(await fetchUrl(url, token));
      });

  /// Returns a `data:` URL or http(s) URL found in the response, or null.
  /// Order: message.images[].image_url.url, data URL in content, http URL in content.
  static String? extractImageRef(Object? body) {
    if (body is! Map) return null;
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final message = (choices.first as Map?)?['message'];
    if (message is! Map) return null;

    final images = message['images'];
    if (images is List) {
      for (final img in images) {
        final u = (img is Map && img['image_url'] is Map)
            ? (img['image_url'] as Map)['url']
            : null;
        if (u is String && u.isNotEmpty) return u;
      }
    }

    final content = message['content'];
    final text = content is String
        ? content
        : content is List
        ? content
              .map(
                (p) => p is Map
                    ? (p['text'] ??
                          (p['image_url'] is Map
                              ? (p['image_url'] as Map)['url']
                              : '') ??
                          '')
                    : '',
              )
              .join('\n')
        : '';
    return _dataUrl.firstMatch(text)?.group(0) ??
        _httpUrl.firstMatch(text)?.group(0);
  }
}
