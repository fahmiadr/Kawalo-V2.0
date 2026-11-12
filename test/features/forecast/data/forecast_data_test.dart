import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/forecast/data/datasources/forecast_remote_data_source.dart';
import 'package:kawalo_mobile/features/forecast/data/mappers/forecast_mapper.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_option_models.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_preview_model.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_request_model.dart';
import 'package:kawalo_mobile/features/forecast/data/repositories/forecast_repository_impl.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockRemote extends Mock implements ForecastRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _FakeRequest extends Fake implements ForecastRequestModel {}

final _config = ForecastConfig(
  startDate: DateTime(2026, 11, 12),
  endDate: DateTime(2026, 11, 18),
  quotas: const {'s1': 2, 's2': 1},
  personnel: const ['a@x.id', 'b@x.id'],
  fillMode: ForecastFillMode.overwrite,
  maxConsecutive: 5,
);

const Map<String, dynamic> _previewJson = {
  'seed': 12345,
  'fill_mode': 'empty',
  'preview_token': 'abc',
  'existing_count': 10,
  'delete_count': 4,
  'locked_count': 3,
  'plan': [
    {'date': '2026-11-12', 'shift_uid': 's1', 'email': 'a@x.id', 'name': 'Ani'},
  ],
  'stats': {
    'total_created': 1,
    'total_days': 7,
    'total_personnel': 2,
    'total_shifts': 2,
    'total_capacity': 21,
    'per_shift': [
      {'shift_uid': 's1', 'shift_name': 'Pagi', 'created': 1, 'capacity': 14},
    ],
    'per_personnel': [
      {'email': 'a@x.id', 'name': 'Ani', 'total': 1},
    ],
    'load_min': 0,
    'load_max': 1,
    'under_staffed': [
      {
        'date': '2026-11-13',
        'shift_uid': 's1',
        'shift_name': 'Pagi',
        'short': 2,
      },
      {
        'date': '2026-11-14',
        'shift_uid': 's1',
        'shift_name': 'Pagi',
        'short': 1,
      },
    ],
    'under_staffed_total': 3,
  },
};

void main() {
  setUpAll(() => registerFallbackValue(_FakeRequest()));

  group('ForecastRequestModel', () {
    test('preview body has no seed, token or confirmation by default', () {
      final json = ForecastRequestModel(config: _config).toJson();

      expect(json, {
        'start_date': '2026-11-12',
        'end_date': '2026-11-18',
        'shifts': [
          {'shift_uid': 's1', 'quota': 2},
          {'shift_uid': 's2', 'quota': 1},
        ],
        'personnel': ['a@x.id', 'b@x.id'],
        'fill_mode': 'overwrite',
        'rest_days': {'enabled': true, 'max_consecutive': 5},
      });
    });

    test('a reshuffle sends only the new seed', () {
      final json = ForecastRequestModel(config: _config, seed: 9).toJson();

      expect(json['seed'], 9);
      expect(json.containsKey('preview_token'), isFalse);
      expect(json.containsKey('confirm_overwrite'), isFalse);
    });

    test('commit echoes seed and token and carries the confirmation', () {
      final json = ForecastRequestModel(
        config: _config,
        seed: 12345,
        previewToken: 'abc',
        confirmOverwrite: true,
      ).toJson();

      expect(json['seed'], 12345);
      expect(json['preview_token'], 'abc');
      expect(json['confirm_overwrite'], true);
    });
  });

  group('models and mapper', () {
    test('preview parses into the entity with local-midnight dates', () {
      final preview = ForecastMapper.toPreview(
        ForecastPreviewModel.fromJson(_previewJson),
      );

      expect(preview.seed, 12345);
      expect(preview.token, 'abc');
      expect(preview.existingCount, 10);
      expect(preview.deleteCount, 4);
      expect(preview.lockedCount, 3);
      expect(preview.plan.single.date, DateTime(2026, 11, 12));
      expect(preview.plan.single.name, 'Ani');
      expect(preview.stats.underStaffed.first.date, DateTime(2026, 11, 13));
      expect(preview.stats.underStaffedTotal, 3);
    });

    test('filledSlots subtracts what is still missing per shift', () {
      final stats = ForecastMapper.toPreview(
        ForecastPreviewModel.fromJson(_previewJson),
      ).stats;

      expect(stats.filledSlots(stats.perShift.single), 11);
    });

    test('missing sections do not throw', () {
      final preview = ForecastPreviewModel.fromJson(const {});

      expect(preview.plan, isEmpty);
      expect(preview.stats.perShift, isEmpty);
      expect(preview.seed, 0);
    });

    test('options keep the role upper-cased and drop rows without id', () {
      final options = ForecastMapper.toOptions(
        [
          ForecastShiftModel.fromJson(const {
            'uid': 's1',
            'name': 'Pagi',
            'start_time': '07:00',
            'end_time': '15:00',
            'color': '#3B82F6',
            'radius': 100,
          }),
          ForecastShiftModel.fromJson(const {'name': 'Tanpa uid'}),
        ],
        [
          ForecastMemberModel.fromJson(const {
            'email': 'a@x.id',
            'name': 'Ani',
            'role': ' guard ',
          }),
          ForecastMemberModel.fromJson(const {'name': 'Tanpa email'}),
        ],
      );

      expect(options.shifts.map((s) => s.uid), ['s1']);
      expect(options.people.single.role, 'GUARD');
      expect(options.people.single.isGuard, isTrue);
      expect(options.people.single.displayName, 'Ani');
    });
  });

  group('ForecastRemoteDataSourceImpl', () {
    late _MockApiClient api;
    late ForecastRemoteDataSourceImpl source;

    setUp(() {
      api = _MockApiClient();
      source = ForecastRemoteDataSourceImpl(apiClient: api);
    });

    test('preview posts to the preview endpoint', () async {
      when(
        () => api.post(any<String>(), body: any<Object?>(named: 'body')),
      ).thenAnswer((_) async => {'data': _previewJson});

      final model = await source.preview(ForecastRequestModel(config: _config));

      expect(model.token, 'abc');
      verify(
        () => api.post(
          '/v1/schedules/generate/preview',
          body: any<Object?>(named: 'body'),
        ),
      ).called(1);
    });

    test('commit reads created and deleted', () async {
      when(
        () => api.post(any<String>(), body: any<Object?>(named: 'body')),
      ).thenAnswer(
        (_) async => {
          'data': {'created': 14, 'deleted': 4},
        },
      );

      final model = await source.commit(ForecastRequestModel(config: _config));

      expect((model.created, model.deleted), (14, 4));
      verify(
        () => api.post(
          '/v1/schedules/generate',
          body: any<Object?>(named: 'body'),
        ),
      ).called(1);
    });

    test('a response without data is a server exception', () {
      when(
        () => api.post(any<String>(), body: any<Object?>(named: 'body')),
      ).thenAnswer((_) async => {'message': 'ok'});

      expect(
        () => source.preview(ForecastRequestModel(config: _config)),
        throwsA(isA<ServerException>()),
      );
    });

    test('lists read the data array and skip non-objects', () async {
      when(() => api.get('/v1/shifts')).thenAnswer(
        (_) async => {
          'data': [
            {'uid': 's1', 'name': 'Pagi'},
            'oops',
          ],
        },
      );
      when(
        () => api.get('/v1/groups/members'),
      ).thenAnswer((_) async => {'data': null});

      expect(await source.getShifts(), hasLength(1));
      expect(await source.getMembers(), isEmpty);
    });
  });

  group('ForecastRepositoryImpl', () {
    late _MockRemote remote;
    late _MockNetworkInfo network;
    late ForecastRepositoryImpl repository;

    setUp(() {
      remote = _MockRemote();
      network = _MockNetworkInfo();
      when(() => network.isConnected).thenAnswer((_) async => true);
      repository = ForecastRepositoryImpl(
        remoteDataSource: remote,
        networkInfo: network,
      );
    });

    test('offline fails without calling the server', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.preview(_config);

      expect(result.getLeft().toNullable(), isA<NoInternetFailure>());
      verifyZeroInteractions(remote);
    });

    test('loadOptions combines shifts and members', () async {
      when(() => remote.getShifts()).thenAnswer(
        (_) async => [
          const ForecastShiftModel(
            uid: 's1',
            name: 'Pagi',
            startTime: '07:00',
            endTime: '15:00',
          ),
        ],
      );
      when(() => remote.getMembers()).thenAnswer(
        (_) async => [
          const ForecastMemberModel(email: 'a@x.id', role: 'GUARD'),
        ],
      );

      final options = (await repository.loadOptions()).toNullable();

      expect(options?.shifts.single.uid, 's1');
      expect(options?.people.single.email, 'a@x.id');
    });

    test('loadOptions maps a failing request to a failure', () async {
      when(() => remote.getShifts()).thenThrow(const NoInternetException());
      when(() => remote.getMembers()).thenAnswer((_) async => []);

      final result = await repository.loadOptions();

      expect(result.getLeft().toNullable(), isA<NoInternetFailure>());
    });

    test('apply sends the seed and token of the preview', () async {
      when(() => remote.commit(any())).thenAnswer(
        (_) async => const ForecastResultModel(created: 5, deleted: 2),
      );
      final preview = ForecastMapper.toPreview(
        ForecastPreviewModel.fromJson(_previewJson),
      );

      final result = await repository.apply(
        _config,
        preview: preview,
        confirmOverwrite: true,
      );

      expect(result.toNullable(), const ForecastResult(created: 5, deleted: 2));
      final sent =
          verify(() => remote.commit(captureAny())).captured.single
              as ForecastRequestModel;
      expect(sent.seed, 12345);
      expect(sent.previewToken, 'abc');
      expect(sent.confirmOverwrite, isTrue);
    });

    test(
      'apply keeps the 409 status so the UI can ask for a new preview',
      () async {
        when(() => remote.commit(any())).thenThrow(
          const ServerException('Data jadwal berubah.', 409, 'CONFLICT_ERROR'),
        );
        final preview = ForecastMapper.toPreview(
          ForecastPreviewModel.fromJson(_previewJson),
        );

        final result = await repository.apply(
          _config,
          preview: preview,
          confirmOverwrite: true,
        );

        final failure = result.getLeft().toNullable();
        expect(failure?.statusCode, 409);
        expect(failure?.message, 'Data jadwal berubah.');
      },
    );
  });
}
