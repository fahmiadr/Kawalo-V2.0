import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_local_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_remote_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/models/checkout_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_id_params_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_query_model.dart';
import 'package:kawalo_mobile/features/guest/data/repositories/guest_repository_impl.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/acknowledge_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements GuestRemoteDataSource {}

class _MockLocal extends Mock implements GuestLocalDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockNetwork network;
  late GuestRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const GuestQueryModel());
    registerFallbackValue(const GuestIdParamsModel(id: '1'));
    registerFallbackValue(const CheckoutGuestModel());
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    network = _MockNetwork();
    when(() => network.isConnected).thenAnswer((_) async => true);
    repository = GuestRepositoryImpl(
      syncStorageService: SyncStorageService(),
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: network,
    );
  });

  group('acknowledgeGuest', () {
    const data = AcknowledgeGuestData(id: '101', qrUid: 'QR-101');
    const model = GuestModel(
      id: '101',
      guestName: 'Budi',
      guestAckDt: '2026-11-02T10:00:00.000Z',
    );

    test('returns NoInternetFailure offline without calling the API', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.acknowledgeGuest(data);

      result.fold(
        (f) => expect(f, isA<NoInternetFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyZeroInteractions(remote);
    });

    test('calls the API, caches the result and maps the entity', () async {
      when(
        () => remote.acknowledgeGuest(
          params: any(named: 'params'),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => model);
      when(() => local.cacheGuests(any())).thenAnswer((_) async {});

      final result = await repository.acknowledgeGuest(data);

      result.fold((_) => fail('Expected Right'), (entity) {
        expect(entity.id, '101');
        expect(entity.isAcknowledged, isTrue);
      });
      verify(
        () => remote.acknowledgeGuest(
          params: const GuestIdParamsModel(id: '101'),
          data: const CheckoutGuestModel(qrUid: 'QR-101'),
        ),
      ).called(1);
      verify(() => local.cacheGuests([model])).called(1);
    });

    test('maps API errors to a failure', () async {
      when(
        () => remote.acknowledgeGuest(
          params: any(named: 'params'),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const ServerException(
          'Kunjungan tamu sudah dikonfirmasi sebelumnya.',
          400,
        ),
      );

      final result = await repository.acknowledgeGuest(data);

      result.fold(
        (f) => expect(f.message, contains('sudah dikonfirmasi')),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getGuests is_active filter', () {
    setUp(() {
      when(
        () => remote.getGuests(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const []);
      when(() => local.cacheGuests(any())).thenAnswer((_) async {});
      when(() => local.deleteOlderThan(any())).thenAnswer((_) async {});
    });

    test('forwards isActive to the remote query', () async {
      await repository.getGuests(const GetGuestsParams(isActive: true));

      verify(
        () => remote.getGuests(query: const GuestQueryModel(isActive: true)),
      ).called(1);
    });

    test('applies isActive to the offline cache read', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(
        () => local.getCachedGuests(
          search: any(named: 'search'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          createdBy: any(named: 'createdBy'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => const []);

      await repository.getGuests(const GetGuestsParams(isActive: true));

      verify(
        () => local.getCachedGuests(
          search: any(named: 'search'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          createdBy: any(named: 'createdBy'),
          isActive: true,
        ),
      ).called(1);
    });
  });
}
