import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_member_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_member_model.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_member_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockRemote extends Mock implements PttMemberRemoteDataSource {}

void main() {
  group('PttMemberRemoteDataSourceImpl', () {
    late MockApiClient api;
    late PttMemberRemoteDataSourceImpl dataSource;

    setUp(() {
      api = MockApiClient();
      dataSource = PttMemberRemoteDataSourceImpl(apiClient: api);
    });

    test('parses the snake_case member list', () async {
      when(() => api.get('/v1/ptt/members')).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'members': [
              {
                'user_id': 'usr_1',
                'name': 'Budi',
                'role': 'GUARD',
                'speaking': true,
              },
              {'user_id': 'usr_2', 'name': 'Sari', 'role': 'ADMIN'},
            ],
          },
        },
      );

      final members = await dataSource.getMembers();

      expect(members.map((m) => m.userId), ['usr_1', 'usr_2']);
      expect(members.first.speaking, isTrue);
      expect(members.last.speaking, isFalse);
    });

    test('rejects an envelope without a members list', () async {
      when(
        () => api.get('/v1/ptt/members'),
      ).thenAnswer((_) async => {'success': true, 'data': <String, dynamic>{}});

      expect(dataSource.getMembers(), throwsFormatException);
    });
  });

  group('PttMemberRepositoryImpl', () {
    late MockRemote remote;
    late PttMemberRepositoryImpl repository;

    setUp(() {
      remote = MockRemote();
      repository = PttMemberRepositoryImpl(remoteDataSource: remote);
    });

    test('maps models to entities', () async {
      when(() => remote.getMembers()).thenAnswer(
        (_) async => [
          const PttMemberModel(userId: 'usr_1', name: 'Budi', role: 'GUARD'),
        ],
      );

      final result = await repository.getMembers();

      expect(result.getOrElse((_) => throw StateError('left')), const [
        PttMemberEntity(userId: 'usr_1', name: 'Budi', role: 'GUARD'),
      ]);
    });

    test('maps an exception to a failure', () async {
      when(() => remote.getMembers()).thenThrow(const NoInternetException());

      final result = await repository.getMembers();

      expect(result.isLeft(), isTrue);
      result.match((l) => expect(l, isA<Failure>()), (_) {});
    });
  });

  group('PttMemberEntity.roleLabel', () {
    test('labels the known roles in Indonesian', () {
      expect(
        const PttMemberEntity(userId: '', name: '', role: 'admin').roleLabel,
        'Admin',
      );
      expect(
        const PttMemberEntity(
          userId: '',
          name: '',
          role: 'SUPER_ADMIN',
        ).roleLabel,
        'Admin',
      );
      expect(
        const PttMemberEntity(userId: '', name: '', role: 'GUARD').roleLabel,
        'Petugas',
      );
      expect(
        const PttMemberEntity(userId: '', name: '', role: '').roleLabel,
        'Anggota',
      );
    });
  });
}
