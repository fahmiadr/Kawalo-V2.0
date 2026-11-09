import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/group/data/datasources/group_remote_data_source.dart';
import 'package:kawalo_mobile/features/group/data/models/group_member_model.dart';
import 'package:kawalo_mobile/features/group/data/repositories/group_repository_impl.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRemoteDataSource extends Mock implements GroupRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late MockGroupRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late GroupRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockGroupRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = GroupRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
  });

  const tModels = [
    GroupMemberModel(
      email: 'member@kawalo.id',
      name: 'Member Name',
      profilePic: 'https://example.com/pic.jpg',
    ),
  ];

  const tEntities = [
    GroupMemberEntity(
      email: 'member@kawalo.id',
      name: 'Member Name',
      profilePic: 'https://example.com/pic.jpg',
    ),
  ];

  group('getMembers', () {
    test('should return NoInternetFailure when device is offline without '
        'calling remoteDataSource', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getMembers();

      expect(
        result,
        const Left<Failure, List<GroupMemberEntity>>(NoInternetFailure()),
      );
      verifyNever(
        () => mockRemoteDataSource.getMembers(
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test(
      'should return list of GroupMemberEntity when remote call succeeds',
      () async {
        when(
          () => mockRemoteDataSource.getMembers(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tModels);

        final cancelToken = MockAppCancellationToken();
        final result = await repository.getMembers(cancelToken: cancelToken);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should be Right'),
          (entities) => expect(entities, equals(tEntities)),
        );
        verify(
          () => mockRemoteDataSource.getMembers(cancelToken: cancelToken),
        ).called(1);
      },
    );

    test(
      'should proceed to remoteDataSource when networkInfo is null',
      () async {
        final repoWithoutNetwork = GroupRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
        );
        when(
          () => mockRemoteDataSource.getMembers(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tModels);

        final result = await repoWithoutNetwork.getMembers();

        expect(result.isRight(), isTrue);
        verify(() => mockRemoteDataSource.getMembers()).called(1);
      },
    );

    test(
      'should return RequestCancelledFailure on RequestCancelledException',
      () async {
        when(
          () => mockRemoteDataSource.getMembers(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException());

        final result = await repository.getMembers();

        expect(
          result,
          const Left<Failure, List<GroupMemberEntity>>(
            RequestCancelledFailure(),
          ),
        );
      },
    );

    test('should return ServerFailure on ServerException', () async {
      when(
        () => mockRemoteDataSource.getMembers(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const ServerException('API Error', 500));

      final result = await repository.getMembers();

      expect(
        result,
        const Left<Failure, List<GroupMemberEntity>>(
          ServerFailure('API Error', 500),
        ),
      );
    });
  });
}
