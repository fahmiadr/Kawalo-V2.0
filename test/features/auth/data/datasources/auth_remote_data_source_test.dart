import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/logout_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/refresh_token_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/switch_group_request_model.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthRemoteDataSourceImpl remoteDataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    remoteDataSource = AuthRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  const tEmail = 'admin@kawalo.co.id';
  const tPassword = 'password123';

  final tLoginResponse = {
    'success': true,
    'message': 'Login berhasil',
    'data': {
      'user': {
        'id': 'usr_1',
        'email': tEmail,
        'name': 'Super Admin',
        'avatar_url': null,
        'active_group': null,
        'groups': <Map<String, dynamic>>[],
      },
      'tokens': {
        'access_token': 'mock_access_jwt',
        'refresh_token': 'mock_opaque_refresh',
        'token_type': 'Bearer',
        'expires_in': 900,
      },
    },
  };

  group('AuthRemoteDataSourceImpl', () {
    test(
      'login sends POST /v1/auth/login and parses LoginResponseModel',
      () async {
        when(
          () => mockApiClient.post(
            '/v1/auth/login',
            body: {'email': tEmail, 'password': tPassword},
          ),
        ).thenAnswer((_) async => tLoginResponse);

        final result = await remoteDataSource.login(
          const LoginRequestModel(email: tEmail, password: tPassword),
        );

        expect(result.user.id, equals('usr_1'));
        expect(result.tokens.accessToken, equals('mock_access_jwt'));
        verify(
          () => mockApiClient.post(
            '/v1/auth/login',
            body: {'email': tEmail, 'password': tPassword},
          ),
        ).called(1);
      },
    );

    test('logout sends POST /v1/auth/logout with refresh_token', () async {
      when(
        () => mockApiClient.post(
          '/v1/auth/logout',
          body: {'refresh_token': 'rft_123'},
        ),
      ).thenAnswer((_) async => {'success': true, 'message': 'Berhasil'});

      await remoteDataSource.logout(
        const LogoutRequestModel(refreshToken: 'rft_123'),
      );

      verify(
        () => mockApiClient.post(
          '/v1/auth/logout',
          body: {'refresh_token': 'rft_123'},
        ),
      ).called(1);
    });

    test(
      'refreshToken sends POST /v1/auth/refresh and parses AuthTokensModel',
      () async {
        when(
          () => mockApiClient.post(
            '/v1/auth/refresh',
            body: {'refresh_token': 'rft_123'},
          ),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'message': 'Token refreshed',
            'data': {
              'access_token': 'new_access_token',
              'refresh_token': 'new_refresh_token',
              'token_type': 'Bearer',
              'expires_in': 900,
            },
          },
        );

        final result = await remoteDataSource.refreshToken(
          const RefreshTokenRequestModel(refreshToken: 'rft_123'),
        );

        expect(result.accessToken, equals('new_access_token'));
        expect(result.refreshToken, equals('new_refresh_token'));
      },
    );

    test('switchGroup sends POST /v1/auth/switch-group and parses '
        'LoginResponseModel', () async {
      when(
        () => mockApiClient.post(
          '/v1/auth/switch-group',
          body: {'group_uid': 'grp_456'},
        ),
      ).thenAnswer((_) async => tLoginResponse);

      final result = await remoteDataSource.switchGroup(
        const SwitchGroupRequestModel(groupUid: 'grp_456'),
      );

      expect(result.user.id, equals('usr_1'));
      verify(
        () => mockApiClient.post(
          '/v1/auth/switch-group',
          body: {'group_uid': 'grp_456'},
        ),
      ).called(1);
    });
  });
}
