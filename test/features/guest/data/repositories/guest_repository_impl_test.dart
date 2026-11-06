import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_local_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_remote_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/models/checkout_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/create_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_id_params_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_query_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/master_guest_type_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/update_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/repositories/guest_repository_impl.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/checkout_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/create_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/update_guest_data.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRemoteDataSource extends Mock implements GuestRemoteDataSource {}

class MockGuestLocalDataSource extends Mock implements GuestLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late GuestRepositoryImpl repository;
  late MockGuestRemoteDataSource mockRemoteDataSource;
  late MockGuestLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(const GuestQueryModel());
    registerFallbackValue(const GuestIdParamsModel(id: '1'));
    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      const CreateGuestModel(
        guestName: 'Fallback',
        guestDestination: 'Fallback',
        guestType: 'TAMU',
      ),
    );
    registerFallbackValue(
      const CreateGuestData(
        guestName: 'Fallback',
        guestDestination: 'Fallback',
        guestType: 'TAMU',
      ),
    );
    registerFallbackValue(
      const UpdateGuestData(
        id: '1',
      ),
    );
    registerFallbackValue(
      const UpdateGuestModel(),
    );
    registerFallbackValue(
      const CheckoutGuestData(id: '1'),
    );
    registerFallbackValue(
      const CheckoutGuestModel(),
    );
  });

  setUp(() {
    mockRemoteDataSource = MockGuestRemoteDataSource();
    mockLocalDataSource = MockGuestLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    repository = GuestRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const tGuestModel = GuestModel(
    id: 'guest_1',
    guestName: 'Budi Santoso',
    guestNumber: 'B 1234 CD',
    guestCategory: 'Tamu',
    guestDestination: 'Blok A1',
    guestToUserName: 'John Doe',
    guestPurpose: 'Kunjungan',
    guestDt: 'Hari ini, 10.00',
  );
  final tGuestList = [tGuestModel];

  group('getGuests', () {
    test(
      'should return GuestResultEntity and cache data when remote call is '
      'successful',
      () async {
        when(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tGuestList);

        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenAnswer((_) async {});

        when(
          () => mockLocalDataSource.deleteOlderThan(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getGuests(
          const GetGuestsParams(search: 'John'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should be Right'),
          (resultEntity) {
            expect(resultEntity.items.length, 1);
            expect(resultEntity.items.first.id, 'guest_1');
            expect(resultEntity.isFromCache, isFalse);
          },
        );
        verify(
          () => mockRemoteDataSource.getGuests(
            query: const GuestQueryModel(search: 'John'),
          ),
        ).called(1);
        verify(
          () => mockLocalDataSource.cacheGuests(tGuestList),
        ).called(1);
        verify(
          () => mockLocalDataSource.deleteOlderThan(any()),
        ).called(1);
      },
    );

    test(
      'should return ServerFailure when remote throws ServerException '
      'and localDataSource is null',
      () async {
        final repoNoLocal = GuestRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );
        when(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const ServerException('Server error'));

        final result = await repoNoLocal.getGuests(const GetGuestsParams());

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Server error');
          },
          (guests) => fail('Should be Left'),
        );
      },
    );

    test(
      'should fallback to cached guests when remote throws ServerException '
      'and localDataSource is present',
      () async {
        when(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const ServerException('Server error'));

        when(
          () => mockLocalDataSource.getCachedGuests(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => tGuestList);

        final result = await repository.getGuests(const GetGuestsParams());

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should be Right'),
          (resultEntity) {
            expect(resultEntity.items.length, 1);
            expect(resultEntity.items.first.id, 'guest_1');
            expect(resultEntity.isFromCache, isTrue);
          },
        );
      },
    );

    test(
      'should return cached guests when remote fails with NetworkException '
      'and period is not custom',
      () async {
        when(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NetworkException('No internet'));

        when(
          () => mockLocalDataSource.getCachedGuests(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => tGuestList);

        final result = await repository.getGuests(const GetGuestsParams());

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should be Right'),
          (resultEntity) {
            expect(resultEntity.items.length, 1);
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
          () => mockLocalDataSource.getCachedGuests(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => tGuestList);

        final result = await repository.getGuests(
          const GetGuestsParams(search: 'John'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should be Right'),
          (resultEntity) {
            expect(resultEntity.items.length, 1);
            expect(resultEntity.isFromCache, isTrue);
          },
        );

        verifyNever(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test(
      'triggers remote fetch when offline if isRefresh is true',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tGuestList);
        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.deleteOlderThan(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getGuests(
          const GetGuestsParams(
            search: 'John',
            isRefresh: true,
          ),
        );

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    test(
      'does not trigger remote fetch when offline and returns empty cache '
      'result when no data found',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(
          () => mockLocalDataSource.getCachedGuests(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getGuests(
          const GetGuestsParams(search: 'NonExistent'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (resultEntity) {
            expect(resultEntity.items, isEmpty);
            expect(resultEntity.isFromCache, isTrue);
          },
        );

        verifyNever(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test(
      'returns Right with empty items and isFromCache true when remote throws '
      'network exception and cache is empty',
      () async {
        when(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NetworkException('No internet'));

        when(
          () => mockLocalDataSource.getCachedGuests(
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getGuests(
          const GetGuestsParams(search: 'John'),
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
        final repoWithoutLocal = GuestRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repoWithoutLocal.getGuests(
          const GetGuestsParams(),
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
      'should return RequestCancelledFailure on cancelled exception',
      () async {
        when(
          () => mockRemoteDataSource.getGuests(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException('Cancelled'));

        final result = await repository.getGuests(const GetGuestsParams());

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RequestCancelledFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );
  });

  group('deleteGuest Tests', () {
    const tId = '101';

    test('returns Left(NoInternetFailure) when network is offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.deleteGuest(id: tId);

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
          () => mockRemoteDataSource.deleteGuest(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockLocalDataSource.deleteGuest(any()),
        ).thenAnswer((_) async => true);

        final result = await repository.deleteGuest(id: tId);

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.deleteGuest(
            params: const GuestIdParamsModel(id: tId),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.deleteGuest(tId)).called(1);
      },
    );

    test(
      'returns Right(null) and completes normally when localDataSource is null',
      () async {
        final repoNoLocal = GuestRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );

        when(
          () => mockRemoteDataSource.deleteGuest(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        final result = await repoNoLocal.deleteGuest(id: tId);

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.deleteGuest(
            params: const GuestIdParamsModel(id: tId),
          ),
        ).called(1);
      },
    );

    test(
      'returns Right(null) even when localDataSource throws '
      '(best-effort cache eviction)',
      () async {
        when(
          () => mockRemoteDataSource.deleteGuest(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockLocalDataSource.deleteGuest(any()),
        ).thenThrow(Exception('Isar local disk full'));

        final result = await repository.deleteGuest(id: tId);

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.deleteGuest(
            params: const GuestIdParamsModel(id: tId),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.deleteGuest(tId)).called(1);
      },
    );

    test(
      'returns Left(ServerFailure) on ServerException',
      () async {
        when(
          () => mockRemoteDataSource.deleteGuest(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(
          const ServerException(
            'Hanya Admin atau Petugas yang dapat menghapus data tamu.',
            403,
            'FORBIDDEN',
          ),
        );

        final result = await repository.deleteGuest(id: tId);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              failure.message,
              'Hanya Admin atau Petugas yang dapat menghapus data tamu.',
            );
            expect(failure.statusCode, 403);
          },
          (_) => fail('Expected Left but got Right'),
        );
        verifyNever(() => mockLocalDataSource.deleteGuest(any()));
      },
    );

    test(
      'returns Left(RequestCancelledFailure) when request is cancelled',
      () async {
        when(
          () => mockRemoteDataSource.deleteGuest(
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException('Dibatalkan'));

        final result = await repository.deleteGuest(id: tId);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RequestCancelledFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );
  });

  group('createGuest', () {
    const tData = CreateGuestData(
      guestName: 'Budi Santoso',
      guestDestination: 'Pos Satpam',
      guestType: 'TAMU',
      guestPurpose: 'Kunjungan kerja',
    );

    const tModel = CreateGuestModel(
      guestName: 'Budi Santoso',
      guestDestination: 'Pos Satpam',
      guestType: 'TAMU',
      guestPurpose: 'Kunjungan kerja',
    );

    const tCreatedModel = GuestModel(
      id: 'guest_01',
      guestName: 'Budi Santoso',
      guestDestination: 'Pos Satpam',
      guestType: 'TAMU',
      guestPurpose: 'Kunjungan kerja',
    );

    test(
      'returns Left(NoInternetFailure) when network is not connected',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repository.createGuest(tData);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NoInternetFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
        verifyNever(
          () => mockRemoteDataSource.createGuest(
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
          () => mockRemoteDataSource.createGuest(
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tCreatedModel);

        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenAnswer((_) async {});

        final result = await repository.createGuest(tData);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (entity) {
            expect(entity.id, 'guest_01');
            expect(entity.guestName, 'Budi Santoso');
          },
        );
        verify(
          () => mockRemoteDataSource.createGuest(
            data: tModel,
          ),
        ).called(1);
        verify(
          () => mockLocalDataSource.cacheGuests([tCreatedModel]),
        ).called(1);
      },
    );

    test(
      'returns Right(entity) even when localDataSource is null',
      () async {
        final repoNoLocal = GuestRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );

        when(
          () => mockRemoteDataSource.createGuest(
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tCreatedModel);

        final result = await repoNoLocal.createGuest(tData);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (entity) => expect(entity.id, 'guest_01'),
        );
      },
    );

    test(
      'returns Right(entity) when localDataSource caching throws (best-effort)',
      () async {
        when(
          () => mockRemoteDataSource.createGuest(
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tCreatedModel);

        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenThrow(Exception('Local DB disk full'));

        final result = await repository.createGuest(tData);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (entity) => expect(entity.id, 'guest_01'),
        );
      },
    );

    test(
      'returns Left(RequestCancelledFailure) when request is cancelled',
      () async {
        when(
          () => mockRemoteDataSource.createGuest(
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException('Dibatalkan'));

        final result = await repository.createGuest(tData);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RequestCancelledFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    test(
      'returns Left(ServerFailure) on AppException',
      () async {
        when(
          () => mockRemoteDataSource.createGuest(
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(
          const ServerException(
            'Tipe tamu tidak valid.',
            400,
            'BAD_REQUEST',
          ),
        );

        final result = await repository.createGuest(tData);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Tipe tamu tidak valid.');
          },
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    test(
      'forwards cancelToken to remote data source',
      () async {
        final token = MockAppCancellationToken();
        final tDataWithToken = CreateGuestData(
          guestName: tData.guestName,
          guestDestination: tData.guestDestination,
          guestType: tData.guestType,
          guestPurpose: tData.guestPurpose,
          cancelToken: token,
        );

        when(
          () => mockRemoteDataSource.createGuest(
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tCreatedModel);

        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenAnswer((_) async {});

        final result = await repository.createGuest(tDataWithToken);

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.createGuest(
            data: tModel,
            cancelToken: token,
          ),
        ).called(1);
      },
    );
  });

  group('updateGuest', () {
    const tUpdateData = UpdateGuestData(
      id: '101',
      guestName: 'Budi Santoso Update',
      guestDestination: 'Pos Satpam',
      guestType: 'TAMU',
      guestPurpose: 'Kunjungan diperpanjang',
    );

    const tUpdateParams = GuestIdParamsModel(id: '101');

    const tUpdateModel = UpdateGuestModel(
      guestName: 'Budi Santoso Update',
      guestDestination: 'Pos Satpam',
      guestType: 'TAMU',
      guestPurpose: 'Kunjungan diperpanjang',
    );

    const tUpdatedGuestModel = GuestModel(
      id: '101',
      guestName: 'Budi Santoso Update',
      guestDestination: 'Pos Satpam',
      guestType: 'TAMU',
      guestPurpose: 'Kunjungan diperpanjang',
    );

    test(
      'returns Left(NoInternetFailure) when network is not connected',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repository.updateGuest(tUpdateData);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NoInternetFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
        verifyNever(
          () => mockRemoteDataSource.updateGuest(
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
          () => mockRemoteDataSource.updateGuest(
            params: any(named: 'params'),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tUpdatedGuestModel);

        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenAnswer((_) async {});

        final result = await repository.updateGuest(tUpdateData);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (entity) {
            expect(entity.id, '101');
            expect(entity.guestName, 'Budi Santoso Update');
          },
        );
        verify(
          () => mockRemoteDataSource.updateGuest(
            params: tUpdateParams,
            data: tUpdateModel,
          ),
        ).called(1);
        verify(
          () => mockLocalDataSource.cacheGuests([tUpdatedGuestModel]),
        ).called(1);
      },
    );

    test(
      'returns Right(entity) even when localDataSource is null',
      () async {
        final repoNoLocal = GuestRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetworkInfo,
        );

        when(
          () => mockRemoteDataSource.updateGuest(
            params: any(named: 'params'),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tUpdatedGuestModel);

        final result = await repoNoLocal.updateGuest(tUpdateData);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (entity) => expect(entity.id, '101'),
        );
      },
    );

    test(
      'returns Right(entity) when localDataSource caching throws (best-effort)',
      () async {
        when(
          () => mockRemoteDataSource.updateGuest(
            params: any(named: 'params'),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tUpdatedGuestModel);

        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenThrow(Exception('Local DB disk full'));

        final result = await repository.updateGuest(tUpdateData);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (entity) => expect(entity.id, '101'),
        );
      },
    );

    test(
      'returns Left(RequestCancelledFailure) when request is cancelled',
      () async {
        when(
          () => mockRemoteDataSource.updateGuest(
            params: any(named: 'params'),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException('Dibatalkan'));

        final result = await repository.updateGuest(tUpdateData);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RequestCancelledFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    test(
      'returns Left(ServerFailure) on AppException',
      () async {
        when(
          () => mockRemoteDataSource.updateGuest(
            params: any(named: 'params'),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(
          const ServerException(
            'Data tamu tidak ditemukan.',
            404,
            'NOT_FOUND',
          ),
        );

        final result = await repository.updateGuest(tUpdateData);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Data tamu tidak ditemukan.');
          },
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    test(
      'forwards cancelToken to remote data source',
      () async {
        final token = MockAppCancellationToken();
        final tUpdateWithToken = UpdateGuestData(
          id: tUpdateData.id,
          guestName: tUpdateData.guestName,
          guestDestination: tUpdateData.guestDestination,
          guestType: tUpdateData.guestType,
          guestPurpose: tUpdateData.guestPurpose,
          cancelToken: token,
        );

        when(
          () => mockRemoteDataSource.updateGuest(
            params: any(named: 'params'),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => tUpdatedGuestModel);

        when(
          () => mockLocalDataSource.cacheGuests(any()),
        ).thenAnswer((_) async {});

        final result = await repository.updateGuest(tUpdateWithToken);

        expect(result.isRight(), isTrue);
        verify(
          () => mockRemoteDataSource.updateGuest(
            params: tUpdateParams,
            data: tUpdateModel,
            cancelToken: token,
          ),
        ).called(1);
      },
    );
  });

  group('getMasterGuestTypes', () {
    const tModels = [
      MasterGuestTypeModel(
        id: '1',
        uid: 'type_1',
        name: 'TAMU',
      ),
    ];

    const tEntities = [
      MasterGuestTypeEntity(
        id: '1',
        uid: 'type_1',
        name: 'TAMU',
      ),
    ];

    test(
      'returns Left(NoInternetFailure) when network is not connected',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repository.getMasterGuestTypes();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NoInternetFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
        verifyNever(
          () => mockRemoteDataSource.getMasterGuestTypes(
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test('returns Right(entities) when remote call succeeds', () async {
      when(
        () => mockRemoteDataSource.getMasterGuestTypes(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => tModels);

      final token = MockAppCancellationToken();
      final result = await repository.getMasterGuestTypes(cancelToken: token);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (entities) => expect(entities, equals(tEntities)),
      );
      verify(
        () => mockRemoteDataSource.getMasterGuestTypes(cancelToken: token),
      ).called(1);
    });

    test(
      'returns Left(RequestCancelledFailure) when request is cancelled',
      () async {
        when(
          () => mockRemoteDataSource.getMasterGuestTypes(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const RequestCancelledException('Dibatalkan'));

        final result = await repository.getMasterGuestTypes();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RequestCancelledFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );

    test('returns Left(ServerFailure) on ServerException', () async {
      when(
        () => mockRemoteDataSource.getMasterGuestTypes(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const ServerException('Gagal memuat tipe tamu', 500));

      final result = await repository.getMasterGuestTypes();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Gagal memuat tipe tamu');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });
  });

  group('checkoutGuest', () {
    const tCheckoutData = CheckoutGuestData(
      id: '101',
      qrUid: 'QR-101',
    );
    const tGuestModel = GuestModel(
      id: '101',
      guestName: 'Budi',
      guestOutDt: '2026-11-02T10:00:00.000Z',
    );

    test('returns Left(NoInternetFailure) when network is not connected',
        () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.checkoutGuest(tCheckoutData);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NoInternetFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
      verifyZeroInteractions(mockRemoteDataSource);
    });

    test(
        'calls remoteDataSource.checkoutGuest, caches result, and returns '
        'Right(entity)', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.checkoutGuest(
          params: any(named: 'params'),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => tGuestModel);
      when(() => mockLocalDataSource.cacheGuests(any())).thenAnswer(
        (_) async {},
      );

      final result = await repository.checkoutGuest(tCheckoutData);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (entity) {
          expect(entity.id, equals('101'));
          expect(entity.guestName, equals('Budi'));
          expect(entity.isExited, isTrue);
        },
      );
      verify(
        () => mockRemoteDataSource.checkoutGuest(
          params: const GuestIdParamsModel(id: '101'),
          data: const CheckoutGuestModel(qrUid: 'QR-101'),
        ),
      ).called(1);
      verify(() => mockLocalDataSource.cacheGuests([tGuestModel])).called(1);
    });

    test(
        'returns Left(ServerFailure) when remoteDataSource throws '
        'ServerException', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.checkoutGuest(
          params: any(named: 'params'),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const ServerException('Gagal check-out', 500));

      final result = await repository.checkoutGuest(tCheckoutData);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Gagal check-out'));
        },
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
