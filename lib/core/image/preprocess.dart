import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const int kMaxLongEdge = 2048;

class PreprocessedImage {
  const PreprocessedImage(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
  String get mimeType => 'image/jpeg';
}

/// Applies EXIF orientation, scales the long edge down to [maxLongEdge]
/// (never up) and re-encodes as high-quality JPEG. Runs off the UI isolate.
Future<PreprocessedImage> preprocessImage(
  Uint8List input, {
  int maxLongEdge = kMaxLongEdge,
}) {
  return compute(_preprocess, _Args(input, maxLongEdge));
}

class _Args {
  const _Args(this.bytes, this.maxLongEdge);
  final Uint8List bytes;
  final int maxLongEdge;
}

PreprocessedImage _preprocess(_Args a) {
  final decoded = img.decodeImage(a.bytes);
  if (decoded == null) {
    throw const FormatException('Unsupported or corrupt image');
  }
  var image = img.bakeOrientation(decoded);
  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge > a.maxLongEdge) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: a.maxLongEdge,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: a.maxLongEdge,
            interpolation: img.Interpolation.average,
          );
  }
  final out = Uint8List.fromList(img.encodeJpg(image, quality: 92));
  return PreprocessedImage(out, image.width, image.height);
}
