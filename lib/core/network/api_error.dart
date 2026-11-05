import 'package:dio/dio.dart';

enum ApiErrorType { timeout, safety, auth, network, badResponse, cancelled }

class ApiError implements Exception {
  const ApiError(this.type, {this.message, this.statusCode});

  final ApiErrorType type;

  /// Server-provided or diagnostic detail, shown beneath the localized text.
  final String? message;
  final int? statusCode;

  factory ApiError.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return const ApiError(ApiErrorType.cancelled);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(ApiErrorType.timeout);
      case DioExceptionType.connectionError:
        return ApiError(ApiErrorType.network, message: e.message);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final detail = extractServerMessage(e.response?.data);
        if (code == 400) {
          return ApiError(
            ApiErrorType.safety,
            message: detail,
            statusCode: code,
          );
        }
        if (code == 401 || code == 403) {
          return ApiError(ApiErrorType.auth, message: detail, statusCode: code);
        }
        return ApiError(
          ApiErrorType.badResponse,
          message: detail,
          statusCode: code,
        );
      default:
        if (e.error is ApiError) return e.error! as ApiError;
        return ApiError(ApiErrorType.network, message: e.message);
    }
  }

  @override
  String toString() => 'ApiError($type, $statusCode, $message)';
}

/// Pulls a short human-readable message out of an error body, if any.
String? extractServerMessage(Object? data) {
  String? msg;
  if (data is Map) {
    final err = data['error'];
    if (err is Map && err['message'] is String) {
      msg = err['message'] as String;
    } else if (err is String) {
      msg = err;
    } else if (data['message'] is String) {
      msg = data['message'] as String;
    }
  } else if (data is String && data.isNotEmpty) {
    msg = data;
  }
  if (msg == null) return null;
  return msg.length > 200 ? '${msg.substring(0, 200)}…' : msg;
}
