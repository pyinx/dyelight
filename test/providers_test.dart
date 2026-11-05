import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_photo_colorizer/core/models.dart';
import 'package:ai_photo_colorizer/core/network/api_client.dart';
import 'package:ai_photo_colorizer/core/network/api_error.dart';
import 'package:ai_photo_colorizer/core/network/chat_completions_provider.dart';
import 'package:ai_photo_colorizer/core/network/images_edits_provider.dart';
import 'package:ai_photo_colorizer/core/network/images_generations_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

final _bytes = Uint8List.fromList([1, 2, 3, 4]);
final _b64 = base64Encode(_bytes);
final _req = EditRequest(
  imageBytes: Uint8List(8),
  mimeType: 'image/jpeg',
  prompt: 'warm',
);
const _settings = AppSettings();

({Dio dio, DioAdapter adapter}) _make() {
  final dio = createDio(_settings, 'k');
  final adapter = DioAdapter(dio: dio);
  return (dio: dio, adapter: adapter);
}

void main() {
  test('normalizeBaseUrl trims spaces and trailing slashes', () {
    expect(
      normalizeBaseUrl(' http://192.168.1.2:8080/v1// '),
      'http://192.168.1.2:8080/v1',
    );
  });

  group('ImagesGenerationsProvider', () {
    test('sends JSON with data-URL image and reads b64_json', () async {
      final m = _make();
      m.adapter.onPost(
        '/images/generations',
        (s) => s.reply(200, {
          'data': [
            {'b64_json': _b64},
          ],
        }),
        data: Matchers.any,
      );
      final r = await ImagesGenerationsProvider(
        m.dio,
        _settings,
      ).edit(_req, CancelToken());
      expect(r.bytes, _bytes);
    });

    test('request body carries model, prompt, image data URL', () async {
      final m = _make();
      Object? body;
      m.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            body = o.data;
            h.next(o);
          },
        ),
      );
      m.adapter.onPost(
        '/images/generations',
        (s) => s.reply(200, {
          'data': [
            {'b64_json': _b64},
          ],
        }),
        data: Matchers.any,
      );
      await ImagesGenerationsProvider(
        m.dio,
        _settings,
      ).edit(_req, CancelToken());
      final map = body! as Map;
      expect(map['prompt'], 'warm');
      expect(map['model'], _settings.model);
      expect(map['image'], startsWith('data:image/jpeg;base64,'));
      expect(map['response_format'], 'b64_json');
    });
  });

  group('ImagesEditsProvider', () {
    test('reads b64_json', () async {
      final m = _make();
      m.adapter.onPost(
        '/images/edits',
        (s) => s.reply(200, {
          'data': [
            {'b64_json': _b64},
          ],
        }),
        data: Matchers.any,
      );
      final r = await ImagesEditsProvider(
        m.dio,
        _settings,
      ).edit(_req, CancelToken());
      expect(r.bytes, _bytes);
    });

    test('empty data => badResponse', () async {
      final m = _make();
      m.adapter.onPost(
        '/images/edits',
        (s) => s.reply(200, {'data': []}),
        data: Matchers.any,
      );
      expect(
        ImagesEditsProvider(m.dio, _settings).edit(_req, CancelToken()),
        throwsA(
          isA<ApiError>().having(
            (e) => e.type,
            'type',
            ApiErrorType.badResponse,
          ),
        ),
      );
    });

    test('400 => safety with server message', () async {
      final m = _make();
      m.adapter.onPost(
        '/images/edits',
        (s) => s.reply(400, {
          'error': {'message': 'blocked by policy'},
        }),
        data: Matchers.any,
      );
      expect(
        ImagesEditsProvider(m.dio, _settings).edit(_req, CancelToken()),
        throwsA(
          isA<ApiError>()
              .having((e) => e.type, 'type', ApiErrorType.safety)
              .having((e) => e.message, 'message', 'blocked by policy'),
        ),
      );
    });

    test('401 => auth', () async {
      final m = _make();
      m.adapter.onPost(
        '/images/edits',
        (s) => s.reply(401, {'error': 'no'}),
        data: Matchers.any,
      );
      expect(
        ImagesEditsProvider(m.dio, _settings).edit(_req, CancelToken()),
        throwsA(
          isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.auth),
        ),
      );
    });

    test('500 => badResponse', () async {
      final m = _make();
      m.adapter.onPost(
        '/images/edits',
        (s) => s.reply(500, 'oops'),
        data: Matchers.any,
      );
      expect(
        ImagesEditsProvider(m.dio, _settings).edit(_req, CancelToken()),
        throwsA(
          isA<ApiError>()
              .having((e) => e.type, 'type', ApiErrorType.badResponse)
              .having((e) => e.statusCode, 'status', 500),
        ),
      );
    });

    test('timeout => timeout', () async {
      final m = _make();
      m.adapter.onPost(
        '/images/edits',
        (s) => s.throws(
          408,
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: RequestOptions(),
          ),
        ),
        data: Matchers.any,
      );
      expect(
        ImagesEditsProvider(m.dio, _settings).edit(_req, CancelToken()),
        throwsA(
          isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.timeout),
        ),
      );
    });
  });

  group('ChatCompletionsProvider.extractImageRef', () {
    Map<String, dynamic> msg(Map<String, dynamic> m) => {
      'choices': [
        {'message': m},
      ],
    };

    test('prefers message.images', () {
      expect(
        ChatCompletionsProvider.extractImageRef(
          msg({
            'content': 'see http://x/y.png',
            'images': [
              {
                'image_url': {'url': 'data:image/png;base64,AAAA'},
              },
            ],
          }),
        ),
        'data:image/png;base64,AAAA',
      );
    });

    test('finds data URL in content', () {
      expect(
        ChatCompletionsProvider.extractImageRef(
          msg({'content': 'here ![img](data:image/png;base64,QUJD) done'}),
        ),
        'data:image/png;base64,QUJD',
      );
    });

    test('finds http URL in content', () {
      expect(
        ChatCompletionsProvider.extractImageRef(
          msg({'content': 'result: https://cdn.example.com/a.png'}),
        ),
        'https://cdn.example.com/a.png',
      );
    });

    test('returns null when nothing found', () {
      expect(
        ChatCompletionsProvider.extractImageRef(msg({'content': 'sorry'})),
        isNull,
      );
      expect(ChatCompletionsProvider.extractImageRef({'x': 1}), isNull);
    });
  });

  test('ChatCompletionsProvider decodes data URL end to end', () async {
    final m = _make();
    m.adapter.onPost(
      '/chat/completions',
      (s) => s.reply(200, {
        'choices': [
          {
            'message': {'content': 'data:image/png;base64,$_b64'},
          },
        ],
      }),
      data: Matchers.any,
    );
    final r = await ChatCompletionsProvider(
      m.dio,
      _settings,
    ).edit(_req, CancelToken());
    expect(r.bytes, _bytes);
  });

  group('testConnection', () {
    test('model listed', () async {
      final m = _make();
      m.adapter.onGet(
        '/models',
        (s) => s.reply(200, {
          'data': [
            {'id': 'gpt-image-1'},
          ],
        }),
      );
      final r = await ImagesEditsProvider(m.dio, _settings).testConnection();
      expect((r.reachable, r.authOk, r.modelListed), (true, true, true));
    });

    test('404 => reachable, no list', () async {
      final m = _make();
      m.adapter.onGet('/models', (s) => s.reply(404, 'nf'));
      final r = await ImagesEditsProvider(m.dio, _settings).testConnection();
      expect((r.reachable, r.authOk, r.modelListed), (true, true, null));
    });

    test('401 => auth failed', () async {
      final m = _make();
      m.adapter.onGet('/models', (s) => s.reply(401, {'error': 'bad key'}));
      final r = await ImagesEditsProvider(m.dio, _settings).testConnection();
      expect((r.reachable, r.authOk), (true, false));
    });
  });
}
