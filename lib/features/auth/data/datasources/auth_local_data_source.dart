import 'dart:convert';

import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(AuthTokensModel tokens);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> saveSession(AuthSessionModel session);
  Future<AuthSessionModel?> getSession();
  Future<void> saveLastEmail(String email);
  Future<String?> getLastEmail();
  Future<void> clearLastEmail();
  Future<void> clearSession({bool preserveEmail = true});
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required this.storageService});
  final SecureStorageService storageService;

  @override
  Future<void> saveTokens(AuthTokensModel tokens) async {
    await storageService.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await storageService.setOnboardingCompleted();
  }

  @override
  Future<String?> getAccessToken() => storageService.getAccessToken();

  @override
  Future<String?> getRefreshToken() => storageService.getRefreshToken();

  @override
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await storageService.saveUserData(userJson);
  }

  @override
  Future<UserModel?> getUser() async {
    final userData = await storageService.getUserData();
    if (userData != null && userData.isNotEmpty) {
      try {
        final map = jsonDecode(userData) as Map<String, dynamic>;
        return UserModel.fromJson(map);
      } on Exception catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    final sessionJson = jsonEncode(session.toJson());
    await storageService.saveAuthSession(sessionJson);
  }

  @override
  Future<AuthSessionModel?> getSession() async {
    final sessionData = await storageService.getAuthSession();
    if (sessionData != null && sessionData.isNotEmpty) {
      try {
        final map = jsonDecode(sessionData) as Map<String, dynamic>;
        return AuthSessionModel.fromJson(map);
      } on Exception catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveLastEmail(String email) =>
      storageService.saveLastEmail(email);

  @override
  Future<String?> getLastEmail() => storageService.getLastEmail();

  @override
  Future<void> clearLastEmail() => storageService.clearLastEmail();

  @override
  Future<void> clearSession({bool preserveEmail = true}) async {
    await storageService.clearAuthSession(preserveEmail: preserveEmail);
  }
}
