import 'dart:convert';

import 'package:dio/dio.dart';

import '../models.dart';
import 'api_error.dart';

/// Asks a vision chat model about [req]'s image and returns its plain-text
/// answer to [req.prompt]. Smart mode uses it to write a photo-specific
/// edit prompt before the image model runs.
Future<String> describePhoto(
  Dio dio,
  String model,
  EditRequest req,
  CancelToken token,
) async {
  try {
    final res = await dio.post<dynamic>(
      '/chat/completions',
      cancelToken: token,
      // No temperature: some reasoning models only accept the default.
      data: {
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': req.prompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url':
                      'data:${req.mimeType};base64,${base64Encode(req.imageBytes)}',
                },
              },
            ],
          },
        ],
      },
    );
    final text = chatText(res.data);
    if (text.isEmpty) {
      throw ApiError(
        ApiErrorType.badResponse,
        message: 'Empty analysis from $model',
        statusCode: res.statusCode,
      );
    }
    return text;
  } on DioException catch (e) {
    throw ApiError.fromDio(e);
  }
}

final _think = RegExp(r'<think>[\s\S]*?</think>');

/// The assistant text of a chat completion, without `<think>` blocks.
String chatText(Object? body) {
  if (body is! Map) return '';
  final choices = body['choices'];
  if (choices is! List || choices.isEmpty) return '';
  final message = (choices.first as Map?)?['message'];
  if (message is! Map) return '';
  final content = message['content'];
  final text = content is String
      ? content
      : content is List
      ? content
            .map((p) => p is Map && p['text'] is String ? p['text'] : '')
            .join('\n')
      : '';
  return text.replaceAll(_think, '').trim();
}
