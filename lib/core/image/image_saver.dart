import 'dart:typed_data';

import 'package:gal/gal.dart';

enum SaveOutcome { saved, noAccess, failed }

class ImageSaver {
  const ImageSaver();

  Future<SaveOutcome> saveToGallery(Uint8List bytes) async {
    try {
      var access = await Gal.hasAccess();
      if (!access) access = await Gal.requestAccess();
      if (!access) return SaveOutcome.noAccess;
      await Gal.putImageBytes(
        bytes,
        name: 'colorized_${DateTime.now().millisecondsSinceEpoch}',
      );
      return SaveOutcome.saved;
    } on GalException catch (e) {
      return e.type == GalExceptionType.accessDenied
          ? SaveOutcome.noAccess
          : SaveOutcome.failed;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }
}
