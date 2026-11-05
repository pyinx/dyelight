import 'package:dio/dio.dart';

import '../models.dart';

abstract class ImageEditProvider {
  Future<EditResult> edit(EditRequest req, CancelToken token);
  Future<ConnectionReport> testConnection();
}
