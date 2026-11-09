import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/repositories/cached_remote_fetch.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockNetworkInfo network;
  late SyncStorageService sync;
  late List<String> log;

  setUp(() {
    network = _MockNetworkInfo();
    when(() => network.isConnected).thenAnswer((_) async => true);
    sync = SyncStorageService();
    log = [];
  });

  CacheOps<int> cacheOps() => CacheOps<int>(
        read: () async {
          log.add('read');
          return [9];
        },
        write: (models) async => log.add('write'),
        deleteOlderThan: (_) async => log.add('evict'),
      );

  Future<Either<Failure, String>> run({
    required Future<List<int>> Function() remote,
    bool isRefresh = false,
    CacheOps<int>? cache,
  }) =>
      fetchRemoteWithCacheFallback<int, String>(
        isRefresh: isRefresh,
        networkInfo: network,
        syncStorageService: sync,
        syncKey: 'test',
        fetchRemote: remote,
        toResult: (models, {required isFromCache}) =>
            '${isFromCache ? 'cache' : 'remote'}:$models',
        cache: cache,
      );

  test('sukses: simpan cache, evict, dan catat sinkronisasi', () async {
    final r = await run(remote: () async => [1], cache: cacheOps());
    expect(r, const Right<Failure, String>('remote:[1]'));
    expect(log, ['write', 'evict']);
    expect(await sync.getLastSync('test'), isNotNull);
  });

  test('hasil kosong tidak ditulis ke cache', () async {
    await run(remote: () async => [], cache: cacheOps());
    expect(log, isEmpty);
  });

  test('offline tanpa refresh: dari cache tanpa memanggil remote', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);
    final r = await run(
      remote: () async => fail('remote tidak boleh dipanggil'),
      cache: cacheOps(),
    );
    expect(r, const Right<Failure, String>('cache:[9]'));
  });

  test('offline tanpa cache: Left, refresh tetap mencoba remote', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);
    expect((await run(remote: () async => [1])).isLeft(), isTrue);
    final r = await run(remote: () async => [1], isRefresh: true);
    expect(r, const Right<Failure, String>('remote:[1]'));
  });

  test('error jaringan fallback cache, AuthException tidak', () async {
    final r = await run(
      remote: () async => throw const NetworkException(),
      cache: cacheOps(),
    );
    expect(r, const Right<Failure, String>('cache:[9]'));

    final auth = await run(
      remote: () async => throw const AuthException(),
      cache: cacheOps(),
    );
    expect(auth.isLeft(), isTrue);
  });

  test('dibatalkan menjadi RequestCancelledFailure tanpa fallback', () async {
    final r = await run(
      remote: () async => throw const RequestCancelledException(),
      cache: cacheOps(),
    );
    expect(r, const Left<Failure, String>(RequestCancelledFailure()));
  });

  test('Exception non-AppException fallback cache; tanpa cache Left', () async {
    final r = await run(
      remote: () async => throw const FormatException('x'),
      cache: cacheOps(),
    );
    expect(r, const Right<Failure, String>('cache:[9]'));
    final none = await run(remote: () async => throw const FormatException());
    expect(none.isLeft(), isTrue);
  });
}
