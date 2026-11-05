import 'dart:convert';

import 'package:dio/dio.dart';

import '../models.dart';
import 'openai_provider_base.dart';

/// `POST {base}/images/generations` with a reference `image` (JSON), as
/// Volcengine Ark Seedream and similar OpenAI-style gateways take it.
class ImagesGenerationsProvider extends OpenAiProviderBase {
  ImagesGenerationsProvider(super.dio, super.settings, {super.downloader});

  @override
  Future<EditResult> edit(EditRequest req, CancelToken token) =>
      guard(() async {
        final res = await dio.post<dynamic>(
          '/images/generations',
          cancelToken: token,
          data: {
            'model': settings.model,
            'prompt': req.prompt,
            'image':
                'data:${req.mimeType};base64,${base64Encode(req.imageBytes)}',
            'response_format': 'b64_json',
          },
        );
        return imageFromData(res, token);
      });
}
