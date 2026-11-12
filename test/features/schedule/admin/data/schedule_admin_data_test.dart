import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/datasources/schedule_admin_remote_data_source.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/mappers/schedule_admin_mapper.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/models/schedule_admin_models.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/repositories/schedule_admin_repository_impl.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockRemote extends Mock implements ScheduleAdminRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

final _entry = ScheduleEntry(
  email: 'budi@contoh.id',
  shiftUid: 'shf_1',
  date: DateTime(2026, 11, 11),
);

void main() {
  group('ManagedScheduleModel + mapper', () {
    test('parses an attended row', () {
      final model = ManagedScheduleModel.fromJson(const {
        'id': 12,
        'date': '2026-11-10',
        'email': 'Budi@Contoh.id',
        'name': ' Budi ',
        'is_member': true,
        'shift_uid': 'shf_1',
        'shift_name': 'Shift Pagi',
        'shift_color': '#3B82F6',
        'start_time': '07:00',
        'end_time': '15:00',
        'location_name': null,
        'checkin': '07:04',
        'checkout': 'N/A',
        'late_mins': 4,
        'locked': true,
      });
      final e = ScheduleAdminMapper.toEntity(model);

      expect(e.id, '12');
      expect(e.date, DateTime(2026, 11, 10));
      expect(e.email, 'budi@contoh.id');
      expect(e.name, 'Budi');
      expect(e.locked, isTrue);
      expect(e.checkin, '07:04');
      expect(e.checkout, isNull, reason: 'legacy N/A means not attended');
      expect(e.lateMins, 4);
    });

    test('keeps rows whose shift or member is gone', () {
      final e = ScheduleAdminMapper.toEntity(
        ManagedScheduleModel.fromJson(const {
          'id': '3',
          'date': '2026-11-12',
          'email': 'x@contoh.id',
          'name': 'X',
          'is_member': false,
          'shift_uid': null,
          'shift_name': null,
          'locked': false,
        }),
      );

      expect(e.isMember, isFalse);
      expect(e.shiftUid, isNull);
      expect(e.lateMins, 0);
    });

    test('request body uses snake_case keys and a plain date', () {
      expect(scheduleEntryToJson(_entry), {
        'email': 'budi@contoh.id',
        'shift_uid': 'shf_1',
        'date': '2026-11-11',
      });
    });

    test('bulk result reads skipped items', () {
      final r = BulkScheduleResultModel.fromJson(const {
        'created': 10,
        'replaced': 1,
        'skipped': 1,
        'skipped_items': [
          {'index': 3, 'reason': 'Sudah ada'},
        ],
      });
      final entity = ScheduleAdminMapper.toBulk(r);

      expect(entity.created, 10);
      expect(entity.replaced, 1);
      expect(entity.skippedItems.single.index, 3);
      expect(entity.skippedItems.single.reason, 'Sudah ada');
    });
  });

  group('ScheduleAdminRemoteDataSourceImpl', () {
    late _MockApiClient api;
    late ScheduleAdminRemoteDataSourceImpl source;

    setUp(() {
      api = _MockApiClient();
      source = ScheduleAdminRemoteDataSourceImpl(apiClient: api);
    });

    test('lists with range and optional email', () async {
      when(
        () => api.get(
          '/v1/schedules',
          queryParameters: any<Map<String, dynamic>?>(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => {'data': <Object>[]});

      await source.getSchedules(
        from: DateTime(2026, 11),
        to: DateTime(2026, 12, 6),
        email: 'a@b.id',
      );

      verify(
        () => api.get(
          '/v1/schedules',
          queryParameters: {
            'from': '2026-11-01',
            'to': '2026-12-06',
            'email': 'a@b.id',
          },
        ),
      ).called(1);
    });

    test('create sends overwrite with the entry', () async {
      when(
        () => api.post('/v1/schedules', body: any<Object?>(named: 'body')),
      ).thenAnswer((_) async => {});

      await source.create(_entry, overwrite: true);

      verify(
        () => api.post(
          '/v1/schedules',
          body: {
            'email': 'budi@contoh.id',
            'shift_uid': 'shf_1',
            'date': '2026-11-11',
            'overwrite': true,
          },
        ),
      ).called(1);
    });

    test('bulk posts every item', () async {
      when(
        () => api.post('/v1/schedules/bulk', body: any<Object?>(named: 'body')),
      ).thenAnswer(
        (_) async => {
          'data': {'created': 1, 'skipped': 0},
        },
      );

      final r = await source.createBulk([_entry], overwrite: false);

      expect(r.created, 1);
      final body =
          verify(
                () => api.post(
                  '/v1/schedules/bulk',
                  body: captureAny<Object?>(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(body['overwrite'], isFalse);
      expect((body['items'] as List).length, 1);
    });

    test('delete sends the ids as the body', () async {
      when(
        () => api.delete('/v1/schedules', body: any<Object?>(named: 'body')),
      ).thenAnswer(
        (_) async => {
          'data': {'deleted_count': 2, 'skipped_count': 1},
        },
      );

      final r = await source.deleteMany(['1', '2', '3']);

      expect(r.deletedCount, 2);
      expect(r.skippedCount, 1);
      verify(
        () => api.delete(
          '/v1/schedules',
          body: {
            'ids': ['1', '2', '3'],
          },
        ),
      ).called(1);
    });
  });

  group('ScheduleAdminRepositoryImpl', () {
    late _MockRemote remote;
    late _MockNetworkInfo network;
    late ScheduleAdminRepositoryImpl repository;

    setUpAll(() => registerFallbackValue(_entry));

    setUp(() {
      remote = _MockRemote();
      network = _MockNetworkInfo();
      when(() => network.isConnected).thenAnswer((_) async => true);
      repository = ScheduleAdminRepositoryImpl(
        remoteDataSource: remote,
        networkInfo: network,
      );
    });

    test('offline fails without calling the server', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.create(_entry);

      expect(result.getLeft().toNullable(), isA<NoInternetFailure>());
      verifyZeroInteractions(remote);
    });

    test('a 409 keeps the server message and status code', () async {
      when(
        () => remote.create(any(), overwrite: any(named: 'overwrite')),
      ).thenThrow(
        const ServerException(
          'Personil sudah punya jadwal shift lain pada tanggal ini.',
          409,
        ),
      );

      final failure = (await repository.create(_entry)).getLeft().toNullable();

      expect(failure?.statusCode, 409);
      expect(failure?.message, contains('shift lain'));
    });

    test('update and bulk map to entities', () async {
      when(() => remote.update(any(), any())).thenAnswer((_) async {});
      when(
        () => remote.createBulk(any(), overwrite: any(named: 'overwrite')),
      ).thenAnswer(
        (_) async => const BulkScheduleResultModel(
          created: 2,
          replaced: 0,
          skipped: 0,
          skippedItems: [],
        ),
      );

      expect(
        await repository.update('5', _entry),
        const Right<Failure, Unit>(unit),
      );
      final bulk = (await repository.createBulk([_entry, _entry])).toNullable();
      expect(bulk?.created, 2);
    });
  });
}
