import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_local_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_remote_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_query_model.dart';
import 'package:kawalo_mobile/features/operational/data/repositories/operational_repository_impl.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationalRemoteDataSource extends Mock
    implements OperationalRemoteDataSource {}

class MockOperationalLocalDataSource extends Mock
    implements OperationalLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockOperationalRemoteDataSource mockRemoteDataSource;
  late MockOperationalLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late OperationalRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const OperationalQueryModel());
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockRemoteDataSource = MockOperationalRemoteDataSource();
    mockLocalDataSource = MockOperationalLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    repository = OperationalRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const sampleOperational = OperationalModel(
    id: 'asep@kawalo.id_2026-09-10',
    userEmail: 'asep@kawalo.id',
    userName: 'Asep Sunandar',
    latestDuty: 'Patroli Sektor 1',
    latestState: 'Aktif',
    latestDutyDt: '2026-09-10 08:00',
    totalActivities: 1,
    dutyDate: '2026-09-10',
    timeline: [
      DutyTimelineModel(
        id: '101',
        journeyUid: 'JRN-01',
        duty: 'Patroli Sektor 1',
        state: 'Aktif',
        dutyDt: '2026-09-10 08:00',
      ),
    ],
  );

  group('OperationalRepositoryImpl Tests', () {
    test('getOperationals returns Right and caches data on success', () async {
      when(
        () => mockRemoteDataSource.getOperationals(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => [sampleOperational]);

      when(
        () => mockLocalDataSource.cacheOperationals(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.deleteOlderThan(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getOperationals(
        const GetOperationalsParams(
          search: 'Asep',
          startDate: '2026-09-10',
          endDate: '2026-09-10',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should return Right'), (resultEntity) {
        expect(resultEntity.items.length, 1);
        expect(resultEntity.items.first, isA<OperationalItemEntity>());
        expect(resultEntity.items.first.userEmail, sampleOperational.userEmail);
        expect(resultEntity.isFromCache, isFalse);
      });

      verify(
        () => mockLocalDataSource.cacheOperationals([sampleOperational]),
      ).called(1);
      verify(() => mockLocalDataSource.deleteOlderThan(any())).called(1);
    });

    test(
      'getOperationals falls back to cache on NoInternetException',
      () async {
        when(
          () => mockRemoteDataSource.getOperationals(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NoInternetException('No internet'));

        when(
          () => mockLocalDataSource.getCachedOperationals(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => [sampleOperational]);

        final result = await repository.getOperationals(
          const GetOperationalsParams(
            search: 'Asep',
            startDate: '2026-09-10',
            endDate: '2026-09-10',
          ),
        );

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should return Right'), (resultEntity) {
          expect(resultEntity.items.length, 1);
          expect(
            resultEntity.items.first.userEmail,
            sampleOperational.userEmail,
          );
          expect(resultEntity.isFromCache, isTrue);
        });

        verify(
          () => mockLocalDataSource.getCachedOperationals(
            search: 'Asep',
            startDate: '2026-09-10',
            endDate: '2026-09-10',
          ),
        ).called(1);
      },
    );

    test(
      'does not trigger remote fetch when offline and serves cache directly',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(
          () => mockLocalDataSource.getCachedOperationals(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => [sampleOperational]);

        final result = await repository.getOperationals(
          const GetOperationalsParams(search: 'Asep'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (resultEntity) {
            expect(resultEntity.items.length, 1);
            expect(resultEntity.isFromCache, isTrue);
          },
        );

        verifyNever(
          () => mockRemoteDataSource.getOperationals(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test('triggers remote fetch when offline if isRefresh is true', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => mockRemoteDataSource.getOperationals(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => [sampleOperational]);
      when(
        () => mockLocalDataSource.cacheOperationals(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.deleteOlderThan(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getOperationals(
        const GetOperationalsParams(search: 'Asep', isRefresh: true),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRemoteDataSource.getOperationals(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('does not trigger remote fetch when offline and returns empty cache '
        'result when no data found', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => mockLocalDataSource.getCachedOperationals(
          search: any(named: 'search'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final result = await repository.getOperationals(
        const GetOperationalsParams(search: 'NonExistent'),
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left: $failure'), (
        resultEntity,
      ) {
        expect(resultEntity.items, isEmpty);
        expect(resultEntity.isFromCache, isTrue);
      });

      verifyNever(
        () => mockRemoteDataSource.getOperationals(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test(
      'returns Right with empty items and isFromCache true when remote throws '
      'network exception and cache is empty',
      () async {
        when(
          () => mockRemoteDataSource.getOperationals(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NoInternetException('No internet'));

        when(
          () => mockLocalDataSource.getCachedOperationals(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getOperationals(
          const GetOperationalsParams(search: 'Asep'),
        );

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should return Right'), (resultEntity) {
          expect(resultEntity.items, isEmpty);
          expect(resultEntity.isFromCache, isTrue);
        });
      },
    );

    test(
      'returns NoInternetFailure when offline and localDataSource is null',
      () async {
        final repoWithoutLocal = OperationalRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repoWithoutLocal.getOperationals(
          const GetOperationalsParams(),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            equals(const NoInternetFailure.offlineNoStorage()),
          ),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    test(
      'getOperationals returns RequestCancelledFailure on cancelled',
      () async {
        when(
          () => mockRemoteDataSource.getOperationals(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException());

        final result = await repository.getOperationals(
          const GetOperationalsParams(),
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<RequestCancelledFailure>());
        }, (operationals) => fail('Should return Left'));

        verifyNever(
          () => mockLocalDataSource.getCachedOperationals(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );
      },
    );
  });
}
