import 'package:dio/dio.dart';

import '../models.dart';
import 'openai_provider_base.dart';

/// `POST {base}/images/edits` (multipart).
class ImagesEditsProvider extends OpenAiProviderBase {
  ImagesEditsProvider(super.dio, super.settings, {super.downloader});

  @override
  Future<EditResult> edit(EditRequest req, CancelToken token) =>
      guard(() async {
        final form = FormData.fromMap({
          'model': settings.model,
          'prompt': req.prompt,
          'image': MultipartFile.fromBytes(
            req.imageBytes,
            filename: req.mimeType == 'image/png' ? 'image.png' : 'image.jpg',
            contentType: DioMediaType.parse(req.mimeType),
          ),
        });
        final res = await dio.post<dynamic>(
          '/images/edits',
          data: form,
          cancelToken: token,
        );
        return imageFromData(res, token);
      });
}
