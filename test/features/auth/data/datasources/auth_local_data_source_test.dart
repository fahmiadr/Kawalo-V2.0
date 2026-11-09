import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AuthLocalDataSourceImpl localDataSource;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockStorage = MockSecureStorageService();
    localDataSource = AuthLocalDataSourceImpl(storageService: mockStorage);
  });

  const tTokens = AuthTokensModel(
    accessToken: 'test_access_token',
    refreshToken: 'test_refresh_token',
    tokenType: 'Bearer',
    expiresIn: 900,
  );

  const tUser = UserModel(
    id: 'user_1',
    email: 'admin@kawalo.co.id',
    name: 'Admin',
    groups: [],
  );

  const tSession = AuthSessionModel(
    userId: 'user_1',
    email: 'admin@kawalo.co.id',
    name: 'Admin',
    role: 'ADMIN',
    groupUid: 'grp_1',
    allowAdmin: true,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  group('AuthLocalDataSourceImpl', () {
    test(
      'saveTokens delegates writing access and refresh tokens to storage',
      () async {
        when(
          () => mockStorage.saveAccessToken(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockStorage.saveRefreshToken(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockStorage.setOnboardingCompleted(
            completed: any(named: 'completed'),
          ),
        ).thenAnswer((_) async => {});

        await localDataSource.saveTokens(tTokens);

        verify(
          () => mockStorage.saveAccessToken('test_access_token'),
        ).called(1);
        verify(
          () => mockStorage.saveRefreshToken('test_refresh_token'),
        ).called(1);
        verify(() => mockStorage.setOnboardingCompleted()).called(1);
      },
    );

    test('getAccessToken retrieves token from storage', () async {
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => 'cached_at');

      final result = await localDataSource.getAccessToken();

      expect(result, equals('cached_at'));
      verify(() => mockStorage.getAccessToken()).called(1);
    });

    test('saveUser writes serialized user data to storage', () async {
      when(() => mockStorage.saveUserData(any())).thenAnswer((_) async => {});

      await localDataSource.saveUser(tUser);

      verify(
        () => mockStorage.saveUserData(jsonEncode(tUser.toJson())),
      ).called(1);
    });

    test(
      'getUser parses and returns UserModel when valid json exists',
      () async {
        when(
          () => mockStorage.getUserData(),
        ).thenAnswer((_) async => jsonEncode(tUser.toJson()));

        final result = await localDataSource.getUser();

        expect(result, equals(tUser));
        verify(() => mockStorage.getUserData()).called(1);
      },
    );

    test('saveSession writes serialized auth session to storage', () async {
      when(
        () => mockStorage.saveAuthSession(any()),
      ).thenAnswer((_) async => {});

      await localDataSource.saveSession(tSession);

      verify(
        () => mockStorage.saveAuthSession(jsonEncode(tSession.toJson())),
      ).called(1);
    });

    test(
      'getSession parses and returns AuthSessionModel when valid json exists',
      () async {
        when(
          () => mockStorage.getAuthSession(),
        ).thenAnswer((_) async => jsonEncode(tSession.toJson()));

        final result = await localDataSource.getSession();

        expect(result, equals(tSession));
        verify(() => mockStorage.getAuthSession()).called(1);
      },
    );

    test('getSession returns null when storage session data is null', () async {
      when(() => mockStorage.getAuthSession()).thenAnswer((_) async => null);

      final result = await localDataSource.getSession();

      expect(result, isNull);
    });

    test('clearSession calls clearAuthSession on secure storage', () async {
      when(() => mockStorage.clearAuthSession()).thenAnswer((_) async => {});

      await localDataSource.clearSession();

      verify(() => mockStorage.clearAuthSession()).called(1);
    });
  });
}
