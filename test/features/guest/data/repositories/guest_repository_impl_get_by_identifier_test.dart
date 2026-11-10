import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_remote_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_id_params_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/repositories/guest_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements GuestRemoteDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

void main() {
  late _MockRemote remote;
  late _MockNetwork network;
  late GuestRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(const GuestIdParamsModel(id: '1')));

  setUp(() {
    remote = _MockRemote();
    network = _MockNetwork();
    when(() => network.isConnected).thenAnswer((_) async => true);
    repository = GuestRepositoryImpl(
      syncStorageService: SyncStorageService(),
      remoteDataSource: remote,
      networkInfo: network,
    );
  });

  void stubGet(Future<GuestModel?> Function() answer) => when(
    () => remote.getGuest(
      params: any(named: 'params'),
      cancelToken: any(named: 'cancelToken'),
    ),
  ).thenAnswer((_) => answer());

  test('returns NoInternetFailure offline without calling the API', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);

    final result = await repository.getGuestByIdentifier('QR-1');

    expect(result.getLeft().toNullable(), isA<NoInternetFailure>());
    verifyZeroInteractions(remote);
  });

  test('maps the response to an entity', () async {
    stubGet(
      () async => const GuestModel(id: '7', guestName: 'Budi', qrUid: 'QR-1'),
    );

    final result = await repository.getGuestByIdentifier('QR-1');

    final entity = result.getRight().toNullable()!;
    expect(entity.id, '7');
    expect(entity.qrUid, 'QR-1');
    final params =
        verify(
              () => remote.getGuest(
                params: captureAny(named: 'params'),
                cancelToken: any(named: 'cancelToken'),
              ),
            ).captured.single
            as GuestIdParamsModel;
    expect(params.id, 'QR-1');
  });

  test('null data becomes a 404 ServerFailure', () async {
    stubGet(() async => null);

    final failure = (await repository.getGuestByIdentifier(
      'QR-1',
    )).getLeft().toNullable()!;

    expect(failure, isA<ServerFailure>());
    expect(failure.statusCode, 404);
  });

  test('a 404 from the server keeps its status code', () async {
    stubGet(
      () async =>
          throw const ServerException('Data tamu tidak ditemukan.', 404),
    );

    final failure = (await repository.getGuestByIdentifier(
      'QR-1',
    )).getLeft().toNullable()!;

    expect(failure.statusCode, 404);
    expect(failure.message, 'Data tamu tidak ditemukan.');
  });
}
