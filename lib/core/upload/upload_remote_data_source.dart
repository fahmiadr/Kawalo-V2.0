import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';

enum UploadKind { image, document }

/// `POST /v1/uploads` (multipart `file` + `kind`), returns the public URL.
class UploadRemoteDataSource {
  const UploadRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const Duration sendTimeout = Duration(minutes: 2);
  static const String imageTooLargeMessage = 'Ukuran gambar melebihi 150 KB';
  static const String documentTooLargeMessage = 'Ukuran dokumen melebihi 10 MB';
  static const String invalidResponseMessage =
      'Respons unggahan tidak valid. Silakan coba lagi.';

  Future<String> upload({
    required Uint8List bytes,
    required String filename,
    required UploadKind kind,
    required DioMediaType contentType,
    UploadProgress? onProgress,
    CancelToken? cancelToken,
  }) async {
    // A 401 is retried once: the auth interceptor refreshes the token but
    // cannot replay a FormData that was already streamed, so rebuild it.
    for (var attempt = 0; ; attempt++) {
      try {
        return await _send(
          bytes: bytes,
          filename: filename,
          kind: kind,
          contentType: contentType,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      } on AuthException {
        if (attempt >= 1) rethrow;
      }
    }
  }

  Future<String> _send({
    required Uint8List bytes,
    required String filename,
    required UploadKind kind,
    required DioMediaType contentType,
    required UploadProgress? onProgress,
    required CancelToken? cancelToken,
  }) async {
    final form = FormData.fromMap({
      'kind': kind.name,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    });
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/uploads',
        data: form,
        cancelToken: cancelToken,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: sendTimeout,
        ),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress((sent / total).clamp(0.0, 1.0));
              },
      );
      final body = response.data ?? const <String, dynamic>{};
      if (body['success'] == false) {
        throw ServerException(
          body['message']?.toString() ?? invalidResponseMessage,
          response.statusCode,
          body['error_code']?.toString(),
        );
      }
      final data = body['data'];
      final url = data is Map ? data['url'] : null;
      if (url is! String || url.isEmpty) {
        throw const ServerException(invalidResponseMessage);
      }
      return url;
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw ServerException(
          kind == UploadKind.image
              ? imageTooLargeMessage
              : documentTooLargeMessage,
          413,
        );
      }
      final mapped = NetworkErrorHandler.handleDioError(e);
      if (mapped is NoInternetException) apiClient.onConnectionFailed?.call();
      throw mapped;
    }
  }

  /// Random v4 UUID, used so stored file names never leak the original name.
  static String newUuid([Random? random]) {
    final r = random ?? Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}
