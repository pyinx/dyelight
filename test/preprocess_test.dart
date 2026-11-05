import 'dart:typed_data';

import 'package:ai_photo_colorizer/core/image/preprocess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _png(int w, int h) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

void main() {
  test('downscales long edge to the cap, keeping aspect ratio', () async {
    final r = await preprocessImage(_png(4000, 2000), maxLongEdge: 2048);
    expect(r.width, 2048);
    expect(r.height, 1024);
    final back = img.decodeJpg(r.bytes)!;
    expect(back.width, 2048);
  });

  test('portrait images are capped on height', () async {
    final r = await preprocessImage(_png(1000, 3000), maxLongEdge: 2048);
    expect(r.height, 2048);
    expect(r.width, 683);
  });

  test('never upscales small images', () async {
    final r = await preprocessImage(_png(300, 200));
    expect((r.width, r.height), (300, 200));
  });

  test('throws on corrupt input', () async {
    expect(
      preprocessImage(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
  });
}
