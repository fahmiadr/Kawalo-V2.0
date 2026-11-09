import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_local_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_query_model.dart';
import 'package:kawalo_mobile/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRemoteDataSource extends Mock
    implements AttendanceRemoteDataSource {}

class MockAttendanceLocalDataSource extends Mock
    implements AttendanceLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockAttendanceRemoteDataSource mockRemoteDataSource;
  late MockAttendanceLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late AttendanceRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const AttendanceQueryModel());
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockRemoteDataSource = MockAttendanceRemoteDataSource();
    mockLocalDataSource = MockAttendanceLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    repository = AttendanceRepositoryImpl(
      syncStorageService: SyncStorageService(),
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const sampleModel = AttendanceModel(
    id: 'att_01',
    userEmail: 'guard@kawalo.id',
    userName: 'Guard Test',
    attendanceDt: '2026-09-20T08:00:00.000Z',
    attendanceType: 'Absen Masuk',
    category: 'MASUK',
    diffMinutes: 0,
    locationName: 'Main Gate',
  );

  group('AttendanceRepositoryImpl Tests', () {
    test('returns Right and caches data when remote fetch succeeds', () async {
      const expectedQuery = AttendanceQueryModel(
        search: 'Guard',
        limit: 10,
        offset: 0,
        startDate: '2026-09-01T00:00:00.000Z',
        endDate: '2026-09-20T23:59:59.000Z',
      );

      when(
        () => mockRemoteDataSource.getAttendances(query: expectedQuery),
      ).thenAnswer((_) async => [sampleModel]);

      when(
        () => mockLocalDataSource.cacheAttendances(any()),
      ).thenAnswer((_) async {});

      when(
        () => mockLocalDataSource.deleteOlderThan(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getAttendances(
        const GetAttendancesParams(
          search: 'Guard',
          limit: 10,
          offset: 0,
          startDate: '2026-09-01T00:00:00.000Z',
          endDate: '2026-09-20T23:59:59.000Z',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left: $failure'), (
        resultEntity,
      ) {
        expect(resultEntity.items.length, 1);
        expect(resultEntity.items.first.id, 'att_01');
        expect(resultEntity.items.first.category, 'MASUK');
        expect(resultEntity.isFromCache, isFalse);
      });

      verify(
        () => mockRemoteDataSource.getAttendances(query: expectedQuery),
      ).called(1);
      verify(
        () => mockLocalDataSource.cacheAttendances([sampleModel]),
      ).called(1);
      verify(() => mockLocalDataSource.deleteOlderThan(any())).called(1);
    });

    test(
      'falls back to cached data upon network exception and marks isFromCache',
      () async {
        when(
          () => mockRemoteDataSource.getAttendances(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NoInternetException('No connection'));

        when(
          () => mockLocalDataSource.getCachedAttendances(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => [sampleModel]);

        final result = await repository.getAttendances(
          const GetAttendancesParams(search: 'Guard'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (resultEntity) {
            expect(resultEntity.items.length, 1);
            expect(resultEntity.items.first.id, 'att_01');
            expect(resultEntity.isFromCache, isTrue);
          },
        );
      },
    );

    test(
      'does not trigger remote fetch when offline and serves cache directly',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(
          () => mockLocalDataSource.getCachedAttendances(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => [sampleModel]);

        final result = await repository.getAttendances(
          const GetAttendancesParams(search: 'Guard'),
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
          () => mockRemoteDataSource.getAttendances(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test('triggers remote fetch when offline if isRefresh is true', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => mockRemoteDataSource.getAttendances(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => [sampleModel]);
      when(
        () => mockLocalDataSource.cacheAttendances(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.deleteOlderThan(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getAttendances(
        const GetAttendancesParams(search: 'Guard', isRefresh: true),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRemoteDataSource.getAttendances(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('does not trigger remote fetch when offline and returns empty cache '
        'result when no data found', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => mockLocalDataSource.getCachedAttendances(
          search: any(named: 'search'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final result = await repository.getAttendances(
        const GetAttendancesParams(search: 'NonExistent'),
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left: $failure'), (
        resultEntity,
      ) {
        expect(resultEntity.items, isEmpty);
        expect(resultEntity.isFromCache, isTrue);
      });

      verifyNever(
        () => mockRemoteDataSource.getAttendances(
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
          () => mockRemoteDataSource.getAttendances(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NoInternetException('No connection'));

        when(
          () => mockLocalDataSource.getCachedAttendances(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getAttendances(
          const GetAttendancesParams(search: 'Guard'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (resultEntity) {
            expect(resultEntity.items, isEmpty);
            expect(resultEntity.isFromCache, isTrue);
          },
        );
      },
    );

    test(
      'returns NoInternetFailure when offline and localDataSource is null',
      () async {
        final repoWithoutLocal = AttendanceRepositoryImpl(
          syncStorageService: SyncStorageService(),
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repoWithoutLocal.getAttendances(
          const GetAttendancesParams(),
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

    test('returns RequestCancelledFailure on cancelled exception', () async {
      when(
        () => mockRemoteDataSource.getAttendances(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const RequestCancelledException('Cancelled'));

      final result = await repository.getAttendances(
        const GetAttendancesParams(),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<RequestCancelledFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
