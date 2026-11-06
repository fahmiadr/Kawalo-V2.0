import 'dart:async';

import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/utils/jwt_utils.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/mappers/auth_mapper.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/logout_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/refresh_token_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/switch_group_request_model.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    ApiClient? apiClient,
    JwksService? jwksService,
  })  : _apiClient = apiClient,
        _jwksService = jwksService ?? JwksService();

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final ApiClient? _apiClient;
  final JwksService _jwksService;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequestModel(email: email, password: password);
      final response = await remoteDataSource.login(request);
      final payload = await JwtUtils.verifyAndDecode(
        response.tokens.accessToken,
        jwksService: _jwksService,
      );
      if (payload == null) {
        throw const AuthException(
          'Gagal memverifikasi keaslian respon server. '
          'Periksa koneksi Anda atau hubungi administrator.',
        );
      }

      final sessionModel = AuthSessionModel.fromJwtPayload(payload);
      final sessionUser = response.user.toEntity();
      await localDataSource.saveTokens(response.tokens);
      await localDataSource.saveUser(response.user);
      await localDataSource.saveSession(sessionModel);
      await localDataSource.saveLastEmail(email);
      return Right(sessionUser);
    } on AppException catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final request = LogoutRequestModel(refreshToken: refreshToken);
          await remoteDataSource.logout(request).timeout(
                const Duration(seconds: 3),
              );
        } on Object catch (_) {
          // Best-effort remote revocation
        }
      }
      // Pengguna sengaja melakukan logout: bersihkan seluruh sesi dan
      // email tersimpan.
      await localDataSource.clearSession(preserveEmail: false);
      return const Right(null);
    } on AppException catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getUser();
      final accessToken = await localDataSource.getAccessToken();
      final refreshToken = await localDataSource.getRefreshToken();

      // 1. Bila data pengguna tidak ada, atau kedua token tidak ditemukan
      if (user == null || (accessToken == null && refreshToken == null)) {
        return const Right(null);
      }

      // Verifikasi kriptografis RS256 token JWT (Lapisan 1 Defense-in-Depth).
      // Gunakan checkExpiresIn: false agar integritas tanda tangan diverifikasi
      // tanpa langsung menolak token yang hanya kedaluwarsa waktu (ditangani
      // di langkah 2 & 3 via silent refresh).
      final verifiedPayload = accessToken != null
          ? await JwtUtils.verifyAndDecode(
              accessToken,
              jwksService: _jwksService,
              checkExpiresIn: false,
            )
          : null;
      if (accessToken != null && verifiedPayload == null) {
        // Token tidak valid atau dimodifikasi secara ilegal di local storage
        await localDataSource.clearSession();
        return const Right(null);
      }

      if (verifiedPayload != null) {
        final sessionModel = AuthSessionModel.fromJwtPayload(verifiedPayload);
        await localDataSource.saveSession(sessionModel);
      }

      final userEntity = user.toEntity();

      // 2. Periksa apakah accessToken masih berlaku (0ms local JWT check)
      final isAccessExpired =
          accessToken == null || JwtUtils.isExpired(accessToken);
      if (!isAccessExpired) {
        return Right(userEntity);
      }

      // 3. Bila accessToken kedaluwarsa tapi refreshToken masih ada,
      // coba refresh proaktif dengan timeout terkelola. Gunakan CancelToken
      // agar request HTTP dibatalkan secara fisik di level socket jika timeout,
      // mencegah phantom background request yang merusak rotasi sesi di server.
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final cancelToken = DioCancellationToken();
        try {
          Future<AuthTokensModel> executeRefresh() async {
            final client = _apiClient;
            if (client != null) {
              final renewed = await client.refreshAccessToken(
                refreshToken: refreshToken,
                cancelToken: cancelToken.toDio(),
              );
              if (renewed == null) {
                if (cancelToken.isCancelled) {
                  throw const AuthException('Permintaan dibatalkan.');
                }
                final stillToken = await localDataSource.getRefreshToken();
                if (stillToken == null) {
                  // Sesi dibersihkan secara resmi karena 401/403/400
                  throw const AuthException('Sesi telah kedaluwarsa.');
                }
                throw const NetworkException('Gagal menyegarkan sesi.');
              }
              return AuthTokensModel(
                accessToken: renewed.accessToken,
                refreshToken: renewed.refreshToken,
                tokenType: 'Bearer',
                expiresIn: 3600,
              );
            }
            return await remoteDataSource.refreshToken(
              RefreshTokenRequestModel(refreshToken: refreshToken),
              cancelToken: cancelToken,
            );
          }

          final newTokens = await executeRefresh().timeout(
            const Duration(seconds: 4),
            onTimeout: () {
              cancelToken.cancel('Timeout refresh token di splash screen');
              throw const TimeoutException(
                'Timeout refresh token di splash screen',
              );
            },
          );
          final newPayload = await JwtUtils.verifyAndDecode(
            newTokens.accessToken,
            jwksService: _jwksService,
          );
          if (newPayload == null) {
            // Token hasil refresh tidak valid atau tanda tangan gagal
            // diverifikasi
            await localDataSource.clearSession();
            return const Right(null);
          }

          final newSession = AuthSessionModel.fromJwtPayload(newPayload);
          await localDataSource.saveTokens(newTokens);
          await localDataSource.saveSession(newSession);
          return Right(userEntity);
        } on AppException catch (e) {
          // Bila refresh token ditolak oleh server (401 / expired / revoked)
          if (e is AuthException ||
              (e is ServerException && e.statusCode == 401)) {
            await localDataSource.clearSession();
            return const Right(null);
          }
          // Bila kendala jaringan, kembalikan cached user untuk mode offline
          return Right(userEntity);
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) {
            // Pembatalan timeout eksplisit, tetap izinkan cached user offline
            return Right(userEntity);
          }
          return Right(userEntity);
        } on Object catch (_) {
          // TimeoutException atau error lain: fallback offline aman
          return Right(userEntity);
        }
      }

      // Bila accessToken kedaluwarsa dan tidak ada refreshToken
      await localDataSource.clearSession();
      return const Right(null);
    } on AppException catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, AuthSessionEntity?>> getActiveSession() async {
    try {
      final sessionModel = await localDataSource.getSession();
      if (sessionModel == null) {
        return const Right(null);
      }
      return Right(sessionModel.toEntity());
    } on AppException catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> switchGroup({
    required String groupUid,
  }) async {
    try {
      final request = SwitchGroupRequestModel(groupUid: groupUid);
      final response = await remoteDataSource.switchGroup(request);
      final payload = await JwtUtils.verifyAndDecode(
        response.tokens.accessToken,
        jwksService: _jwksService,
      );
      if (payload == null) {
        throw const AuthException(
          'Token otentikasi tidak valid dari server',
        );
      }

      final sessionModel = AuthSessionModel.fromJwtPayload(payload);
      final sessionUser = response.user.toEntity();
      await localDataSource.saveTokens(response.tokens);
      await localDataSource.saveUser(response.user);
      await localDataSource.saveSession(sessionModel);
      return Right(sessionUser);
    } on AppException catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
