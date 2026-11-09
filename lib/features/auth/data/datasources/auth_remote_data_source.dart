import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_response_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/logout_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/refresh_token_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/switch_group_request_model.dart';

/// Kontrak DataSource jarak jauh untuk autentikasi dan otorisasi.
abstract class AuthRemoteDataSource {
  /// Mengirim permintaan login dengan kredensial [LoginRequestModel].
  Future<LoginResponseModel> login(LoginRequestModel request);

  /// Mengirim permintaan pencabutan token sesi [LogoutRequestModel].
  Future<void> logout(LogoutRequestModel request);

  /// Memperbarui token autentikasi sesi [RefreshTokenRequestModel].
  Future<AuthTokensModel> refreshToken(
    RefreshTokenRequestModel request, {
    AppCancellationToken? cancelToken,
  });

  /// Mengaktifkan grup kerja baru pengguna [SwitchGroupRequestModel].
  Future<LoginResponseModel> switchGroup(SwitchGroupRequestModel request);
}

/// Implementasi [AuthRemoteDataSource] yang berkomunikasi dengan REST API.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// Membuat instance [AuthRemoteDataSourceImpl].
  const AuthRemoteDataSourceImpl({required this.apiClient});

  /// Client HTTP terpusat dengan interceptor keamanan.
  final ApiClient apiClient;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await apiClient.post(
      '/v1/auth/login',
      body: request.toJson(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return LoginResponseModel.fromJson(rawData);
  }

  @override
  Future<void> logout(LogoutRequestModel request) async {
    await apiClient.post('/v1/auth/logout', body: request.toJson());
  }

  @override
  Future<AuthTokensModel> refreshToken(
    RefreshTokenRequestModel request, {
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.post(
      '/v1/auth/refresh',
      body: request.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return AuthTokensModel.fromJson(rawData);
  }

  @override
  Future<LoginResponseModel> switchGroup(
    SwitchGroupRequestModel request,
  ) async {
    final response = await apiClient.post(
      '/v1/auth/switch-group',
      body: request.toJson(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return LoginResponseModel.fromJson(rawData);
  }
}
