import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:kawalo_mobile/features/schedule/data/mappers/schedule_mapper.dart';
import 'package:kawalo_mobile/features/schedule/data/models/schedule_model.dart';
import 'package:kawalo_mobile/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockRemote extends Mock implements ScheduleRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

const Map<String, Object?> _json = {
  'id': '7',
  'date': '2026-06-30',
  'shift_uid': 'shf_1',
  'shift_name': 'Shift Pagi',
  'shift_color': '#10B981',
  'start_time': '08:00',
  'end_time': '16:00',
  'location_name': 'Pos 1',
  'checkin': null,
  'checkout': null,
  'late_mins': 0,
};

ScheduleModel _model({
  String date = '2026-06-30',
  String? start = '08:00',
  String? end = '16:00',
  String? name = 'Shift Pagi',
  String id = '1',
}) => ScheduleModel(
  id: id,
  date: date,
  shiftName: name,
  startTime: start,
  endTime: end,
);

void main() {
  group('ScheduleModel', () {
    test('parses the API item and ignores fields the app does not use', () {
      final model = ScheduleModel.fromJson(_json);
      expect(model.id, '7');
      expect(model.date, '2026-06-30');
      expect(model.shiftName, 'Shift Pagi');
      expect(model.shiftColor, '#10B981');
      expect(model.startTime, '08:00');
      expect(model.endTime, '16:00');
      expect(model.locationName, 'Pos 1');
    });

    test('keeps a null location_name', () {
      final model = ScheduleModel.fromJson(
        Map<String, dynamic>.of(_json)..['location_name'] = null,
      );
      expect(model.locationName, isNull);
    });
  });

  group('ScheduleMapper', () {
    test('maps a model to an entity with a local-midnight date', () {
      final entity = ScheduleMapper.toEntity(ScheduleModel.fromJson(_json))!;
      expect(entity.id, '7');
      expect(entity.date, DateTime(2026, 6, 30));
      expect(entity.shiftName, 'Shift Pagi');
      expect(entity.locationName, 'Pos 1');
    });

    test('drops rows with an invalid calendar date or time', () {
      expect(ScheduleMapper.toEntity(_model(date: '2026-02-30')), isNull);
      expect(ScheduleMapper.toEntity(_model(date: '30/06/2026')), isNull);
      expect(ScheduleMapper.toEntity(_model(start: null)), isNull);
      expect(ScheduleMapper.toEntity(_model(end: '8:00')), isNull);
    });

    test('falls back to a generic shift name', () {
      expect(ScheduleMapper.toEntity(_model(name: '  '))!.shiftName, 'Shift');
    });

    test('orders by date, then start time, and drops unusable rows', () {
      final list = ScheduleMapper.toEntityList([
        _model(id: 'c', date: '2026-07-02'),
        _model(id: 'b', start: '14:00', end: '22:00'),
        _model(id: 'x', date: 'bad'),
        _model(id: 'a'),
      ]);
      expect(list.map((e) => e.id), ['a', 'b', 'c']);
    });
  });

  group('ScheduleRemoteDataSourceImpl', () {
    test('sends from/to as YYYY-MM-DD and parses the data list', () async {
      final api = _MockApiClient();
      when(
        () => api.get(
          '/v1/schedules/me',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': [_json],
        },
      );

      final result = await ScheduleRemoteDataSourceImpl(
        apiClient: api,
      ).getMySchedules(from: DateTime(2026, 6, 3), to: DateTime(2026, 7, 3));

      expect(result, hasLength(1));
      verify(
        () => api.get(
          '/v1/schedules/me',
          queryParameters: {'from': '2026-06-03', 'to': '2026-07-03'},
        ),
      ).called(1);
    });

    test('returns an empty list when data is not a list', () async {
      final api = _MockApiClient();
      when(
        () => api.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => {'data': null});

      final result = await ScheduleRemoteDataSourceImpl(
        apiClient: api,
      ).getMySchedules(from: DateTime(2026, 6, 3), to: DateTime(2026, 7, 3));

      expect(result, isEmpty);
    });
  });

  group('ScheduleRepositoryImpl', () {
    late _MockRemote remote;
    late _MockNetworkInfo network;
    late ScheduleRepositoryImpl repository;
    final from = DateTime(2026, 6, 30);
    final to = DateTime(2026, 7, 30);

    setUp(() {
      remote = _MockRemote();
      network = _MockNetworkInfo();
      when(() => network.isConnected).thenAnswer((_) async => true);
      repository = ScheduleRepositoryImpl(
        remoteDataSource: remote,
        networkInfo: network,
      );
    });

    test('returns mapped, ordered entities', () async {
      when(() => remote.getMySchedules(from: from, to: to)).thenAnswer(
        (_) async => [_model(id: 'b', date: '2026-07-01'), _model()],
      );

      final result = await repository.getMySchedules(from: from, to: to);

      expect(result.getOrElse((_) => []).map((e) => e.id), ['1', 'b']);
    });

    test('fails with an offline message without calling the server', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.getMySchedules(from: from, to: to);

      expect(result.getLeft().toNullable(), isA<NoInternetFailure>());
      verifyNever(
        () => remote.getMySchedules(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      );
    });

    test('maps server exceptions to a failure', () async {
      when(
        () => remote.getMySchedules(from: from, to: to),
      ).thenThrow(const ServerException('Gagal', 500));

      final result = await repository.getMySchedules(from: from, to: to);

      expect(result.isLeft(), isTrue);
    });
  });
}
