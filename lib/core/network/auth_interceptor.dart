import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/utils/jwt_utils.dart';

/// Alasan penghentian/kedaluwarsa sesi untuk feedback antarmuka pengguna.
enum SessionExpiredReason {
  /// Token kedaluwarsa atau ditolak server secara resmi (401/403/400).
  tokenExpired,

  /// Tanda tangan token tidak sah, dipalsukan, atau anomali kriptografis.
  securityAnomaly,
}

/// Tipe callback saat sesi pengguna kedaluwarsa atau terjadi anomali.
typedef SessionExpiredCallback = void Function(SessionExpiredReason reason);

/// Tipe callback saat access token baru berhasil dirotasi/diperbarui.
typedef TokenRefreshedCallback = void Function(String newToken);

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenDio,
    required this.storageService,
    this.jwksService,
    this.onSessionExpired,
    this.onTokenRefreshed,
  });

  final Dio dio;
  final Dio tokenDio;
  final SecureStorageService storageService;
  JwksService? jwksService;
  SessionExpiredCallback? onSessionExpired;
  TokenRefreshedCallback? onTokenRefreshed;

  Future<({String accessToken, String refreshToken})?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] ??= 'application/json';

    // Abaikan path autentikasi publik tanpa kredensial
    final path = options.path;
    final isAuthOrPublic =
        path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/.well-known/');

    if (isAuthOrPublic) {
      return handler.next(options);
    }

    // Khusus logout: lampirkan access token jika ada tanpa memicu
    // proaktif refresh.
    final isLogout = path.contains('/auth/logout');
    if (isLogout) {
      final accessToken = await storageService.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      return handler.next(options);
    }

    var accessToken = await storageService.getAccessToken();

    // TIER 1: Proaktif Token Refresh sebelum request dikirim
    // Cek apakah token sudah kedaluwarsa atau tersisa < 60 detik
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        JwtUtils.isExpired(accessToken)) {
      final renewed = await refreshAccessToken();
      if (renewed != null) {
        accessToken = renewed.accessToken;
      } else {
        accessToken = await storageService.getAccessToken();
        if (accessToken == null) {
          // Sesi dibersihkan secara resmi, batalkan request
          return handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                statusMessage: 'Session expired',
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        }
      }
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Jangan intercept error 401 pada endpoint refresh token atau logout
    if (err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/logout')) {
      handler.next(err);
      return;
    }

    if (err.response?.statusCode == 401) {
      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final renewedTokens = await refreshAccessToken(
            customRefreshToken: refreshToken,
          );
          if (renewedTokens != null) {
            final requestOptions = err.requestOptions;
            requestOptions.headers['Authorization'] =
                'Bearer ${renewedTokens.accessToken}';

            final response = await dio.fetch<dynamic>(requestOptions);
            return handler.resolve(response);
          }
        } on DioException catch (e) {
          return handler.next(e);
        } on Object catch (_) {
          return handler.next(err);
        }
      }
    }
    handler.next(err);
  }

  /// Menyegarkan access token via [tokenDio] terisolasi dengan
  /// *single-flight deduplication* untuk mencegah circular deadlock
  /// dan race condition.
  Future<({String accessToken, String refreshToken})?> refreshAccessToken({
    String? customRefreshToken,
    CancelToken? cancelToken,
  }) async {
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }

    _refreshFuture = _executeRefresh(
      customRefreshToken,
      cancelToken: cancelToken,
    );
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<({String accessToken, String refreshToken})?> _executeRefresh(
    String? customRefreshToken, {
    CancelToken? cancelToken,
  }) async {
    try {
      final token =
          customRefreshToken ?? await storageService.getRefreshToken();
      if (token == null || token.isEmpty) return null;

      final response = await tokenDio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refresh_token': token},
        cancelToken: cancelToken,
      );
      final responseData = response.data;
      if (responseData != null) {
        if (responseData['success'] == false) {
          await storageService.clearAuthSession();
          onSessionExpired?.call(SessionExpiredReason.tokenExpired);
          return null;
        }

        final nestedData = responseData['data'];
        if (nestedData is Map<String, dynamic>) {
          final accessToken = nestedData['access_token'] as String?;
          final newRefreshToken = nestedData['refresh_token'] as String?;
          if (accessToken != null && newRefreshToken != null) {
            // Verifikasi integritas kriptografis token baru hasil rotasi/refresh
            final verifiedPayload = await JwtUtils.verifyAndDecode(
              accessToken,
              jwksService: jwksService,
            );
            if (verifiedPayload == null) {
              await storageService.clearAuthSession();
              onSessionExpired?.call(SessionExpiredReason.securityAnomaly);
              return null;
            }

            await storageService.saveAccessToken(accessToken);
            await storageService.saveRefreshToken(newRefreshToken);
            onTokenRefreshed?.call(accessToken);
            return (accessToken: accessToken, refreshToken: newRefreshToken);
          }
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Pembatalan eksplisit oleh caller, jangan bersihkan sesi
        return null;
      }
      final statusCode = e.response?.statusCode;
      // Penolakan resmi dari server (Refresh token expired / revoked / invalid)
      if (statusCode == 401 || statusCode == 403 || statusCode == 400) {
        await storageService.clearAuthSession();
        onSessionExpired?.call(SessionExpiredReason.tokenExpired);
      }
      // Bila kendala jaringan (timeout, connection error, offline),
      // JANGAN bersihkan sesi! Pengguna tetap berhak berada di mode offline.
      return null;
    } on Object catch (_) {
      return null;
    }
  }
}
