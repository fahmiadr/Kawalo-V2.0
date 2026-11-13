import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/auth_interceptor.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/security/ssl_pinning_helper.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    SecureStorageService? storage,
    Dio? customDio,
    Dio? customTokenDio,
    JwksService? jwksService,
  }) : storageService = storage ?? SecureStorageService(),
       _jwksService = jwksService {
    final effectiveBaseUrl = baseUrl ?? EnvConfig.apiBaseUrl;
    final baseOptions = BaseOptions(
      baseUrl: effectiveBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      sendTimeout: AppConstants.sendTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      contentType: 'application/json',
      headers: const {'Accept': 'application/json'},
    );

    dio = customDio ?? Dio(baseOptions);
    tokenDio = customTokenDio ?? Dio(baseOptions);

    // Konfigurasikan SSL Pinning pada Dio & tokenDio pada platform native
    if (!kIsWeb) {
      final expectedHost = Uri.tryParse(effectiveBaseUrl)?.host;
      bool validateCert(X509Certificate? cert, String host, int port) {
        return SslPinningHelper.validateCertificate(
          cert,
          host,
          port,
          expectedHost: expectedHost,
        );
      }

      if (customDio == null) {
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: validateCert,
        );
      }
      if (customTokenDio == null) {
        tokenDio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: validateCert,
        );
      }
    }

    authInterceptor = AuthInterceptor(
      dio: dio,
      tokenDio: tokenDio,
      storageService: storageService,
      jwksService: jwksService,
    );
    dio.interceptors.add(authInterceptor);

    final nativeTokens = storageService.nativeTokens;
    if (nativeTokens != null) {
      unawaited(nativeTokens.configure(effectiveBaseUrl).catchError((_) {}));
      // The PTT service refreshed on its own and the server refused: end the
      // session here too, exactly like a refused refresh from Dart.
      nativeTokens.onSessionEnded = () async {
        await storageService.clearAuthSession();
        authInterceptor.onSessionExpired?.call(
          SessionExpiredReason.tokenExpired,
        );
      };
    }

    if (kDebugMode) {
      dio.interceptors.add(_StreamSafeLogInterceptor());
    }
  }

  late final Dio dio;
  late final Dio tokenDio;
  late final AuthInterceptor authInterceptor;
  final SecureStorageService storageService;
  JwksService? _jwksService;

  /// Mengambil layanan JWKS yang terpasang pada interceptor
  JwksService? get jwksService => _jwksService;

  /// Menghubungkan atau memperbarui [JwksService] ke [authInterceptor]
  set jwksService(JwksService? service) {
    _jwksService = service;
    authInterceptor.jwksService = service;
  }

  /// Mengambil callback penghentian sesi dari interceptor
  SessionExpiredCallback? get onSessionExpired =>
      authInterceptor.onSessionExpired;

  /// Menetapkan callback penanganan penghentian sesi ke [authInterceptor]
  set onSessionExpired(SessionExpiredCallback? callback) {
    authInterceptor.onSessionExpired = callback;
  }

  /// Mengambil callback perputaran/rotasi token dari interceptor
  TokenRefreshedCallback? get onTokenRefreshed =>
      authInterceptor.onTokenRefreshed;

  /// Menetapkan callback penanganan perputaran token ke [authInterceptor]
  set onTokenRefreshed(TokenRefreshedCallback? callback) {
    authInterceptor.onTokenRefreshed = callback;
  }

  /// Callback ketika terjadi kegagalan koneksi fisik / soket pada request API
  VoidCallback? onConnectionFailed;

  /// Helper untuk menyegarkan sesi via single-flight refresh token
  Future<({String accessToken, String refreshToken})?> refreshAccessToken({
    String? refreshToken,
    CancelToken? cancelToken,
  }) {
    return authInterceptor.refreshAccessToken(
      customRefreshToken: refreshToken,
      cancelToken: cancelToken,
    );
  }

  /// Menutup client jaringan dan membebaskan resource soket serta
  /// in-flight cache.
  void close({bool force = false}) {
    _inFlightGetRequests.clear();
    dio.close(force: force);
    tokenDio.close(force: force);
  }

  /// Map in-flight request GET untuk single-flight deduplication.
  final Map<String, Future<Map<String, dynamic>>> _inFlightGetRequests =
      <String, Future<Map<String, dynamic>>>{};

  /// Membangun representasi kunci deterministik untuk in-flight request.
  String _buildInFlightKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return path;
    final sortedKeys = queryParameters.keys.toList()..sort();
    final queryParts = sortedKeys
        .map((k) => '$k=${queryParameters[k]}')
        .join('&');
    final separator = path.contains('?') ? '&' : '?';
    return '$path$separator$queryParts';
  }

  /// Eksekutor terpadu (DRY) untuk menangani request Dio dan pemetaan error
  /// secara seragam lintas seluruh kata kerja HTTP.
  Future<Map<String, dynamic>> _safeRequest(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data ?? <String, dynamic>{};

      // Validasi envelope backend jika terdapat key 'success' bernilai false.
      if (data['success'] == false) {
        final message =
            data['message']?.toString() ??
            'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.';
        final errorCode = data['error_code']?.toString();
        final details = data['details'];
        throw ServerException(message, response.statusCode, errorCode, details);
      }

      return data;
    } on DioException catch (e) {
      final appException = NetworkErrorHandler.handleDioError(e);
      if (appException is NoInternetException) {
        onConnectionFailed?.call();
      }
      throw appException;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    // Jika request membawa CancelToken spesifik, bypass deduplikasi agar
    // pembatalan oleh pemanggil ini tidak membatalkan pemanggil lainnya.
    if (cancelToken != null) {
      return await _safeRequest(
        () => dio.get<Map<String, dynamic>>(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );
    }

    final key = _buildInFlightKey(path, queryParameters);

    // Single-Flight: Jika request GET yang sama persis sedang berjalan,
    // gabungkan ke Future yang sama agar tidak menembak server dua kali.
    if (_inFlightGetRequests.containsKey(key)) {
      return await _inFlightGetRequests[key]!;
    }

    final future = _safeRequest(
      () => dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
    );

    _inFlightGetRequests[key] = future;
    try {
      return await future;
    } finally {
      unawaited(_inFlightGetRequests.remove(key));
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _safeRequest(
    () => dio.post<Map<String, dynamic>>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _safeRequest(
    () => dio.put<Map<String, dynamic>>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _safeRequest(
    () => dio.patch<Map<String, dynamic>>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<Map<String, dynamic>> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _safeRequest(
    () => dio.delete<Map<String, dynamic>>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  /// Melakukan HTTP GET request khusus streaming (SSE / Binary Stream).
  ///
  /// Otomatis mem-bypass request deduplication ([_inFlightGetRequests]),
  /// menetapkan `responseType: ResponseType.stream`, serta memetakan seluruh
  /// [DioException] ke [AppException] melalui [NetworkErrorHandler].
  Future<Response<ResponseBody>> getStream(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final effectiveOptions = (options ?? Options()).copyWith(
        responseType: ResponseType.stream,
      );
      return await dio.get<ResponseBody>(
        path,
        queryParameters: queryParameters,
        options: effectiveOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      final appException = NetworkErrorHandler.handleDioError(e);
      if (appException is NoInternetException) {
        onConnectionFailed?.call();
      }
      throw appException;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

/// LogInterceptor khusus yang mengabaikan pencetakan response body saat
/// request bertipe [ResponseType.stream], mencegah akumulasi memori.
class _StreamSafeLogInterceptor extends LogInterceptor {
  _StreamSafeLogInterceptor()
    : super(requestBody: true, responseBody: true, responseHeader: false);

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (response.requestOptions.responseType == ResponseType.stream) {
      final originalResponseBody = responseBody;
      responseBody = false;
      try {
        super.onResponse(response, handler);
      } finally {
        responseBody = originalResponseBody;
      }
      return;
    }
    super.onResponse(response, handler);
  }
}
