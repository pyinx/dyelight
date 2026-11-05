import 'package:ai_photo_colorizer/core/debug_log.dart';
import 'package:ai_photo_colorizer/core/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('disabled log records nothing', () {
    final l = DebugLog()..add('x');
    expect(l.entries.value, isEmpty);
  });

  test(
    'interceptor masks the key and shortens base64; report has no key',
    () async {
      final l = DebugLog()..enabled = true;
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://h.test/v1',
          headers: {'Authorization': 'Bearer sk-supersecretvalue1234'},
        ),
      )..interceptors.add(DebugInterceptor(l));
      DioAdapter(dio: dio).onPost(
        '/images/generations',
        (s) => s.reply(200, {
          'data': [
            {'b64_json': 'A' * 5000},
          ],
        }),
        data: Matchers.any,
      );
      await dio.post<dynamic>(
        '/images/generations',
        data: {'image': 'B' * 5000},
      );
      final text = l.report(const AppSettings());
      expect(text, contains('/images/generations'));
      expect(text, isNot(contains('supersecretvalue')));
      expect(text, isNot(contains('A' * 600)));
      expect(text, isNot(contains('B' * 600)));
    },
  );
}
