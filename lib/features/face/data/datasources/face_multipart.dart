import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';

/// A [ServerException] that keeps the decoded error envelope, for error codes
/// that carry extra fields (e.g. `failed_attempts` of `FACE_NOT_MATCH`).
class ServerExceptionWithBody extends ServerException {
  ServerExceptionWithBody(ServerException source, this.body)
    : super(
        source.message,
        source.statusCode,
        source.errorCode,
        source.details,
      );

  final Map<String, dynamic> body;

  /// [key] at the top level of the envelope, else inside `details` or `data`:
  /// the server may put extras in either place.
  Object? field(String key) {
    if (body.containsKey(key)) return body[key];
    for (final nested in [body['details'], body['data']]) {
      if (nested is Map && nested.containsKey(key)) return nested[key];
    }
    return null;
  }
}

/// Upper bound for face uploads: the server runs inference before answering.
const Duration faceRequestTimeout = Duration(seconds: 60);

/// Posts a multipart form straight through dio (face photos must not go
/// through `UploadRepository`, which recompresses and serves them publicly).
///
/// A 401 is retried once with a rebuilt form: the auth interceptor refreshes
/// the token but cannot replay a FormData that was already streamed. The
/// attendance nonce survives this because the server authenticates before it
/// consumes the nonce.
Future<Map<String, dynamic>> postFaceMultipart(
  ApiClient apiClient,
  String path,
  FormData Function() buildForm,
) async {
  for (var attempt = 0; ; attempt++) {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        path,
        data: buildForm(),
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: faceRequestTimeout,
          receiveTimeout: faceRequestTimeout,
        ),
      );
      final body = response.data ?? const <String, dynamic>{};
      if (body['success'] == false) {
        throw ServerExceptionWithBody(
          ServerException(
            body['message']?.toString() ?? 'Terjadi kesalahan pada server.',
            response.statusCode,
            body['error_code']?.toString(),
            body['details'],
          ),
          body,
        );
      }
      return body;
    } on DioException catch (e) {
      final mapped = NetworkErrorHandler.handleDioError(e);
      if (mapped is AuthException && attempt == 0) continue;
      if (mapped is NoInternetException) apiClient.onConnectionFailed?.call();
      final data = e.response?.data;
      if (mapped is ServerException && data is Map<String, dynamic>) {
        throw ServerExceptionWithBody(mapped, data);
      }
      throw mapped;
    }
  }
}
