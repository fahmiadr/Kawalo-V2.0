import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/home/data/datasources/home_layout_remote_data_source.dart';
import 'package:kawalo_mobile/features/home/data/models/home_layout_model.dart';
import 'package:kawalo_mobile/features/home/data/repositories/home_layout_repository_impl.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements HomeLayoutRemoteDataSource {}

/// In-memory stand-in for the secure storage entry.
class _FakeStorage extends Fake implements SecureStorageService {
  final values = <String, String>{};

  @override
  Future<void> saveHomeLayout(String scope, String json) async =>
      values[scope] = json;

  @override
  Future<String?> getHomeLayout(String scope) async => values[scope];
}

const _scope = 'u1@g1';
const _custom = HomeLayout(order: [HomeCard.inc, HomeCard.sos]);
const _customModel = HomeLayoutModel(order: ['inc', 'sos']);

void main() {
  late _MockRemote remote;
  late _FakeStorage storage;
  late HomeLayoutRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(const HomeLayoutModel()));

  setUp(() {
    remote = _MockRemote();
    storage = _FakeStorage();
    repository = HomeLayoutRepositoryImpl(
      remoteDataSource: remote,
      storage: storage,
    );
  });

  bool pending() =>
      (jsonDecode(storage.values[_scope]!) as Map)['pending'] as bool;

  test('load returns the server layout and caches it', () async {
    when(remote.get).thenAnswer((_) async => _customModel);

    expect(await repository.load(_scope), _custom);
    expect(await repository.cached(_scope), _custom);
    expect(pending(), isFalse);
  });

  test('load falls back to the cache, then to the default', () async {
    when(remote.get).thenThrow(const ServerException('Not found', 404));

    expect(await repository.load(_scope), HomeLayout.fallback);
    expect(await repository.cached(_scope), isNull);

    storage.values[_scope] = jsonEncode({
      'layout': _customModel.toJson(),
      'pending': false,
    });
    expect(await repository.load(_scope), _custom);
  });

  test('a failed save stays local and is resent by the next load', () async {
    when(() => remote.put(any())).thenThrow(const NoInternetException());

    expect(await repository.save(_scope, _custom), _custom);
    expect(pending(), isTrue);

    when(() => remote.put(any())).thenAnswer((_) async => _customModel);
    expect(await repository.load(_scope), _custom);
    expect(pending(), isFalse);
    verifyNever(remote.get);
  });

  test('a 422 is not resent', () async {
    when(
      () => remote.put(any()),
    ).thenThrow(const ServerException('Tidak valid', 422, 'VALIDATION_ERROR'));

    await repository.save(_scope, _custom);
    expect(pending(), isFalse);
  });
}
