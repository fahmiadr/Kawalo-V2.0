import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_local_data_source.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_remote_data_source.dart';
import 'package:kawalo_mobile/features/information/data/models/create_information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_request_model.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_response_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_id_params_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_query_model.dart';
import 'package:kawalo_mobile/features/information/data/models/update_information_model.dart';
import 'package:kawalo_mobile/features/information/data/repositories/information_repository_impl.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/create_information_data.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/get_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/update_information_data.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationRemoteDataSource extends Mock
    implements InformationRemoteDataSource {}

class MockInformationLocalDataSource extends Mock
    implements InformationLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockInformationRemoteDataSource mockRemoteDataSource;
  late MockInformationLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late InformationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const InformationQueryModel());
    registerFallbackValue(const InformationIdParamsModel(id: '0'));
    registerFallbackValue(const DeleteBatchInformationRequestModel(ids: ['0']));
    registerFallbackValue(const CreateInformationModel(title: 'Fallback'));
    registerFallbackValue(const CreateInformationData(title: 'Fallback'));
    registerFallbackValue(const UpdateInformationModel(title: 'Fallback'));
    registerFallbackValue(
      const UpdateInformationData(id: '0', title: 'Fallback'),
    );
    registerFallbackValue(const GetInformationParams());
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockRemoteDataSource = MockInformationRemoteDataSource();
    mockLocalDataSource = MockInformationLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    repository = InformationRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const sampleModel = InformationModel(
    id: 'info_01',
    photos: [],
    title: 'Pemeriksaan Pos Jaga',
    text: 'Aman terkendali.',
    userEmail: 'satpam@kawalo.id',
    userName: 'Budi Santoso',
    feedDt: '2026-09-20T08:00:00.000Z',
    feedType: 'GENERAL',
    groupName: 'JKN Veranda',
    glat: '-6.200000',
    glong: '106.816666',
  );

  group('InformationRepositoryImpl Tests', () {
    test('returns Right and caches data when remote fetch succeeds', () async {
      const expectedQuery = InformationQueryModel(
        search: 'Pos',
        limit: 10,
        offset: 0,
        startDate: '2026-09-01T00:00:00.000Z',
        endDate: '2026-09-20T23:59:59.000Z',
      );

      when(
        () => mockRemoteDataSource.getInformation(query: expectedQuery),
      ).thenAnswer((_) async => [sampleModel]);

      when(
        () => mockLocalDataSource.cacheInformation(any()),
      ).thenAnswer((_) async {});

      when(
        () => mockLocalDataSource.deleteOlderThan(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getInformation(
        const GetInformationParams(
          search: 'Pos',
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
        expect(resultEntity.items.first.id, 'info_01');
        expect(resultEntity.items.first.title, 'Pemeriksaan Pos Jaga');
        expect(resultEntity.isFromCache, isFalse);
      });

      verify(
        () => mockRemoteDataSource.getInformation(query: expectedQuery),
      ).called(1);
      verify(
        () => mockLocalDataSource.cacheInformation([sampleModel]),
      ).called(1);
      verify(() => mockLocalDataSource.deleteOlderThan(any())).called(1);
    });

    test(
      'falls back to cached data upon network exception and marks isFromCache',
      () async {
        when(
          () => mockRemoteDataSource.getInformation(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NoInternetException('No connection'));

        when(
          () => mockLocalDataSource.getCachedInformation(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => [sampleModel]);

        final result = await repository.getInformation(
          const GetInformationParams(search: 'Pos'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (resultEntity) {
            expect(resultEntity.items.length, 1);
            expect(resultEntity.items.first.id, 'info_01');
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
          () => mockLocalDataSource.getCachedInformation(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => [sampleModel]);

        final result = await repository.getInformation(
          const GetInformationParams(search: 'Pos'),
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
          () => mockRemoteDataSource.getInformation(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test('triggers remote fetch when offline if isRefresh is true', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => mockRemoteDataSource.getInformation(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => [sampleModel]);
      when(
        () => mockLocalDataSource.cacheInformation(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.deleteOlderThan(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getInformation(
        const GetInformationParams(search: 'Pos', isRefresh: true),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRemoteDataSource.getInformation(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('passes createdBy to localDataSource when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => mockLocalDataSource.getCachedInformation(
          search: any(named: 'search'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => [sampleModel]);

      final result = await repository.getInformation(
        const GetInformationParams(createdBy: 'satpam@kawalo.id'),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockLocalDataSource.getCachedInformation(
          createdBy: 'satpam@kawalo.id',
        ),
      ).called(1);
    });

    test('does not trigger remote fetch when offline and returns empty cache '
        'result when no data found', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => mockLocalDataSource.getCachedInformation(
          search: any(named: 'search'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final result = await repository.getInformation(
        const GetInformationParams(search: 'NonExistent'),
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left: $failure'), (
        resultEntity,
      ) {
        expect(resultEntity.items, isEmpty);
        expect(resultEntity.isFromCache, isTrue);
      });

      verifyNever(
        () => mockRemoteDataSource.getInformation(
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
          () => mockRemoteDataSource.getInformation(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NoInternetException('No connection'));

        when(
          () => mockLocalDataSource.getCachedInformation(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getInformation(
          const GetInformationParams(search: 'Pos'),
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
        final repoWithoutLocal = InformationRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repoWithoutLocal.getInformation(
          const GetInformationParams(),
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
        () => mockRemoteDataSource.getInformation(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const RequestCancelledException('Cancelled'));

      final result = await repository.getInformation(
        const GetInformationParams(),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<RequestCancelledFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });

  group('deleteInformation Tests', () {
    const tId = '101';

    test('returns Left(NoInternetFailure) when network is offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.deleteInformation(id: tId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NoInternetFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockLocalDataSource);
    });

    test(
      'calls remote delete and clears from local cache, returning Right(null)',
      () async {
        when(
          () => mockRemoteDataSource.deleteInformation(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockLocalDataSource.deleteInformation(any()),
        ).thenAnswer((_) async => true);

        final result = await repository.deleteInformation(id: tId);

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.deleteInformation(
            params: const InformationIdParamsModel(id: tId),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.deleteInformation(tId)).called(1);
      },
    );

    test(
      'returns Right(null) and completes normally when localDataSource is null',
      () async {
        final repoNoLocal = InformationRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );

        when(
          () => mockRemoteDataSource.deleteInformation(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        final result = await repoNoLocal.deleteInformation(id: tId);

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.deleteInformation(
            params: const InformationIdParamsModel(id: tId),
          ),
        ).called(1);
      },
    );

    test('returns Right(null) even when localDataSource throws '
        '(best-effort cache eviction)', () async {
      when(
        () => mockRemoteDataSource.deleteInformation(
          params: any(named: 'params'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockLocalDataSource.deleteInformation(any()),
      ).thenThrow(Exception('Isar local disk full'));

      final result = await repository.deleteInformation(id: tId);

      expect(result.isRight(), isTrue);
      verify(
        () => mockRemoteDataSource.deleteInformation(
          params: const InformationIdParamsModel(id: tId),
        ),
      ).called(1);
      verify(() => mockLocalDataSource.deleteInformation(tId)).called(1);
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(
        () => mockRemoteDataSource.deleteInformation(
          params: any(named: 'params'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const ServerException(
          'Hanya Admin atau Petugas yang dapat menghapus informasi.',
          403,
          'FORBIDDEN',
        ),
      );

      final result = await repository.deleteInformation(id: tId);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(
          failure.message,
          'Hanya Admin atau Petugas yang dapat menghapus informasi.',
        );
        expect(failure.statusCode, 403);
      }, (_) => fail('Expected Left but got Right'));
      verifyNever(() => mockLocalDataSource.deleteInformation(any()));
    });

    test(
      'returns Left(RequestCancelledFailure) when request is cancelled',
      () async {
        when(
          () => mockRemoteDataSource.deleteInformation(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException('Dibatalkan'));

        final result = await repository.deleteInformation(id: tId);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RequestCancelledFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );
  });

  group('deleteBatchInformation Tests', () {
    final tIds = ['10', '20'];
    const tResponseModel = DeleteBatchInformationResponseModel(deletedCount: 2);

    test('returns Left(NoInternetFailure) when network is disconnected without '
        'hitting remote', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.deleteBatchInformation(ids: tIds);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NoInternetFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
      verify(() => mockNetworkInfo.isConnected).called(1);
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockLocalDataSource);
    });

    test('returns Right(DeleteBatchResult) and evicts local cache on '
        'remote success', () async {
      when(
        () => mockRemoteDataSource.deleteBatchInformation(
          params: any(named: 'params'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => tResponseModel);

      when(
        () => mockLocalDataSource.deleteBatchInformation(any()),
      ).thenAnswer((_) async => 2);

      final result = await repository.deleteBatchInformation(ids: tIds);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (entity) => expect(entity, const DeleteBatchResult(deletedCount: 2)),
      );
      verify(
        () => mockRemoteDataSource.deleteBatchInformation(
          params: DeleteBatchInformationRequestModel(ids: tIds),
        ),
      ).called(1);
      verify(() => mockLocalDataSource.deleteBatchInformation(tIds)).called(1);
    });

    test('returns Right(DeleteBatchResult) even when localDataSource throws '
        '(best-effort cache eviction)', () async {
      when(
        () => mockRemoteDataSource.deleteBatchInformation(
          params: any(named: 'params'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => tResponseModel);

      when(
        () => mockLocalDataSource.deleteBatchInformation(any()),
      ).thenThrow(Exception('Isar local disk failure'));

      final result = await repository.deleteBatchInformation(ids: tIds);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (entity) => expect(entity, const DeleteBatchResult(deletedCount: 2)),
      );
      verify(
        () => mockRemoteDataSource.deleteBatchInformation(
          params: DeleteBatchInformationRequestModel(ids: tIds),
        ),
      ).called(1);
      verify(() => mockLocalDataSource.deleteBatchInformation(tIds)).called(1);
    });

    test('returns Left(ServerFailure) on ServerException without touching '
        'localDataSource', () async {
      when(
        () => mockRemoteDataSource.deleteBatchInformation(
          params: any(named: 'params'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const ServerException(
          'Hanya Admin atau Petugas yang dapat menghapus informasi.',
          403,
          'FORBIDDEN',
        ),
      );

      final result = await repository.deleteBatchInformation(ids: tIds);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(
          (failure as ServerFailure).message,
          'Hanya Admin atau Petugas yang dapat menghapus informasi.',
        );
        expect(failure.statusCode, 403);
      }, (_) => fail('Expected Left but got Right'));
      verifyNever(() => mockLocalDataSource.deleteBatchInformation(any()));
    });

    test(
      'returns Left(RequestCancelledFailure) when request is cancelled',
      () async {
        when(
          () => mockRemoteDataSource.deleteBatchInformation(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException('Dibatalkan'));

        final result = await repository.deleteBatchInformation(ids: tIds);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RequestCancelledFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    group('createInformation', () {
      const tParams = CreateInformationData(
        title: 'Pengumuman Pos Jaga',
        text: 'Instruksi keamanan malam.',
        feedType: 'GENERAL',
      );

      const tCreatedModel = InformationModel(
        id: 'new_01',
        photos: [],
        title: 'Pengumuman Pos Jaga',
        text: 'Instruksi keamanan malam.',
        feedType: 'GENERAL',
      );

      test(
        'returns Left(NoInternetFailure) when network is not connected',
        () async {
          when(
            () => mockNetworkInfo.isConnected,
          ).thenAnswer((_) async => false);

          final result = await repository.createInformation(tParams);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<NoInternetFailure>()),
            (_) => fail('Expected Left but got Right'),
          );
          verifyNever(
            () => mockRemoteDataSource.createInformation(
              data: any(named: 'data'),
              cancelToken: any(named: 'cancelToken'),
            ),
          );
        },
      );

      test(
        'returns Right(entity) and caches created model when remote succeeds',
        () async {
          when(
            () => mockRemoteDataSource.createInformation(
              data: any(named: 'data'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => tCreatedModel);
          when(
            () => mockLocalDataSource.cacheInformation(any()),
          ).thenAnswer((_) async {});

          final result = await repository.createInformation(tParams);

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right but got Left'), (entity) {
            expect(entity.id, 'new_01');
            expect(entity.title, 'Pengumuman Pos Jaga');
          });

          verify(
            () => mockRemoteDataSource.createInformation(
              data: any(named: 'data'),
            ),
          ).called(1);
          verify(
            () => mockLocalDataSource.cacheInformation([tCreatedModel]),
          ).called(1);
        },
      );

      test(
        'returns Left(RequestCancelledFailure) on RequestCancelledException',
        () async {
          when(
            () => mockRemoteDataSource.createInformation(
              data: any(named: 'data'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenThrow(const RequestCancelledException('Batal'));

          final result = await repository.createInformation(tParams);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<RequestCancelledFailure>()),
            (_) => fail('Expected Left but got Right'),
          );
        },
      );

      test('returns Left(ServerFailure) on ServerException', () async {
        when(
          () => mockRemoteDataSource.createInformation(
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const ServerException('Gagal menyimpan'));

        final result = await repository.createInformation(tParams);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('updateInformation', () {
      const tParams = UpdateInformationData(
        id: 'update_01',
        title: 'Pengumuman Pos Jaga Revisi',
        text: 'Instruksi keamanan malam diperbarui.',
        feedType: 'GENERAL',
      );

      const tUpdatedModel = InformationModel(
        id: 'update_01',
        photos: [],
        title: 'Pengumuman Pos Jaga Revisi',
        text: 'Instruksi keamanan malam diperbarui.',
        feedType: 'GENERAL',
      );

      test(
        'returns Left(NoInternetFailure) when network is not connected',
        () async {
          when(
            () => mockNetworkInfo.isConnected,
          ).thenAnswer((_) async => false);

          final result = await repository.updateInformation(tParams);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<NoInternetFailure>()),
            (_) => fail('Expected Left but got Right'),
          );
          verifyNever(
            () => mockRemoteDataSource.updateInformation(
              params: any(named: 'params'),
              data: any(named: 'data'),
              cancelToken: any(named: 'cancelToken'),
            ),
          );
        },
      );

      test(
        'returns Right(entity) and caches updated model when remote succeeds',
        () async {
          when(
            () => mockRemoteDataSource.updateInformation(
              params: any(named: 'params'),
              data: any(named: 'data'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => tUpdatedModel);
          when(
            () => mockLocalDataSource.cacheInformation(any()),
          ).thenAnswer((_) async {});

          final result = await repository.updateInformation(tParams);

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right but got Left'), (entity) {
            expect(entity.id, 'update_01');
            expect(entity.title, 'Pengumuman Pos Jaga Revisi');
          });

          verify(
            () => mockRemoteDataSource.updateInformation(
              params: const InformationIdParamsModel(id: 'update_01'),
              data: any(named: 'data'),
            ),
          ).called(1);
          verify(
            () => mockLocalDataSource.cacheInformation([tUpdatedModel]),
          ).called(1);
        },
      );

      test(
        'returns Left(RequestCancelledFailure) on RequestCancelledException',
        () async {
          when(
            () => mockRemoteDataSource.updateInformation(
              params: any(named: 'params'),
              data: any(named: 'data'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenThrow(const RequestCancelledException('Batal'));

          final result = await repository.updateInformation(tParams);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<RequestCancelledFailure>()),
            (_) => fail('Expected Left but got Right'),
          );
        },
      );

      test('returns Left(ServerFailure) on ServerException', () async {
        when(
          () => mockRemoteDataSource.updateInformation(
            params: any(named: 'params'),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const ServerException('Gagal memperbarui'));

        final result = await repository.updateInformation(tParams);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });
  });
}
