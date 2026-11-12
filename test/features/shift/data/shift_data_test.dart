import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/shift/data/datasources/shift_remote_data_source.dart';
import 'package:kawalo_mobile/features/shift/data/mappers/shift_mapper.dart';
import 'package:kawalo_mobile/features/shift/data/models/shift_model.dart';
import 'package:kawalo_mobile/features/shift/data/models/shift_request_model.dart';
import 'package:kawalo_mobile/features/shift/data/repositories/shift_repository_impl.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_input.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockRemote extends Mock implements ShiftRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _FakeRequest extends Fake implements ShiftRequestModel {}

class _FakeInput extends Fake implements ShiftInput {}

const Map<String, dynamic> _json = {
  'uid': '0193a1f2c3d47e8f9a0b1c2d3e4f5a6b',
  'name': 'Shift Pagi',
  'start_time': '07:00',
  'end_time': '15:00',
  'crosses_midnight': false,
  'duration_mins': 480,
  'color': '#3B82F6',
  'description': null,
  'location_name': 'Pos Utama',
  'glat': -6.2088,
  'glong': 106,
  'radius': 100,
};

const _input = ShiftInput(
  name: 'Shift Pagi',
  startTime: ShiftClock(7, 0),
  endTime: ShiftClock(15, 0),
  color: '#3B82F6',
);

ShiftModel _model({
  String uid = 'a',
  String start = '07:00',
  String end = '15:00',
  double? lat,
  double? long,
  int? radius,
}) => ShiftModel(
  uid: uid,
  name: 'Shift',
  startTime: start,
  endTime: end,
  color: '#3B82F6',
  latitude: lat,
  longitude: long,
  radius: radius,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRequest());
    registerFallbackValue(_FakeInput());
  });

  group('ShiftModel', () {
    test('parses the API item, accepting integer coordinates', () {
      final model = ShiftModel.fromJson(_json);
      expect(model.uid, '0193a1f2c3d47e8f9a0b1c2d3e4f5a6b');
      expect(model.startTime, '07:00');
      expect(model.description, isNull);
      expect(model.locationName, 'Pos Utama');
      expect(model.latitude, -6.2088);
      expect(model.longitude, 106.0);
      expect(model.radius, 100);
    });

    test('keeps null coordinates and radius', () {
      final model = ShiftModel.fromJson(
        Map<String, dynamic>.of(_json)
          ..['glat'] = null
          ..['glong'] = null
          ..['radius'] = null,
      );
      expect(model.latitude, isNull);
      expect(model.radius, isNull);
    });
  });

  group('ShiftRequestModel', () {
    test('sends optional fields as explicit nulls', () {
      expect(ShiftRequestModel.fromInput(_input).toJson(), {
        'name': 'Shift Pagi',
        'start_time': '07:00',
        'end_time': '15:00',
        'color': '#3B82F6',
        'description': null,
        'location_name': null,
        'glat': null,
        'glong': null,
        'radius': null,
      });
    });

    test('sends the location of a limited shift', () {
      const input = ShiftInput(
        name: 'Shift Malam',
        startTime: ShiftClock(22, 0),
        endTime: ShiftClock(6, 0),
        color: '#546E7A',
        description: 'Keliling',
        locationName: 'Pos',
        latitude: -6.2,
        longitude: 106.8,
        radius: 50,
      );
      final json = ShiftRequestModel.fromInput(input).toJson();
      expect(json['start_time'], '22:00');
      expect(json['end_time'], '06:00');
      expect(json['glat'], -6.2);
      expect(json['radius'], 50);
      expect(json['description'], 'Keliling');
    });
  });

  group('ShiftMapper', () {
    test('maps clocks and derives overnight and duration', () {
      final entity = ShiftMapper.toEntity(
        _model(start: '22:00', end: '06:00'),
      )!;
      expect(entity.startTime, const ShiftClock(22, 0));
      expect(entity.endsNextDay, isTrue);
      expect(entity.durationMinutes, 480);
    });

    test('keeps the location only when both coordinates exist', () {
      final located = ShiftMapper.toEntity(
        _model(lat: -6.2, long: 106.8, radius: 100),
      )!;
      expect(located.hasLocation, isTrue);
      expect(located.radius, 100);

      final half = ShiftMapper.toEntity(_model(lat: -6.2, radius: 100))!;
      expect(half.hasLocation, isFalse);
      expect(half.radius, isNull);
    });

    test('drops rows without a uid or with an unreadable clock', () {
      final list = ShiftMapper.toEntityList([
        _model(),
        _model(uid: ''),
        _model(start: '7:00'),
        _model(end: 'xx'),
      ]);
      expect(list, hasLength(1));
    });
  });

  group('ShiftRemoteDataSourceImpl', () {
    late _MockApiClient api;
    late ShiftRemoteDataSourceImpl source;

    setUp(() {
      api = _MockApiClient();
      source = ShiftRemoteDataSourceImpl(apiClient: api);
    });

    test('lists shifts from the data array', () async {
      when(() => api.get('/v1/shifts')).thenAnswer(
        (_) async => {
          'data': [_json],
        },
      );
      expect(await source.getShifts(), hasLength(1));
    });

    test('returns an empty list when data is not a list', () async {
      when(() => api.get('/v1/shifts')).thenAnswer((_) async => {'data': null});
      expect(await source.getShifts(), isEmpty);
    });

    test('creates with POST and parses the new item', () async {
      when(
        () => api.post('/v1/shifts', body: any<dynamic>(named: 'body')),
      ).thenAnswer((_) async => {'data': _json});
      final created = await source.createShift(
        ShiftRequestModel.fromInput(_input),
      );
      expect(created.name, 'Shift Pagi');
    });

    test('updates with PUT on the encoded uid', () async {
      when(
        () => api.put('/v1/shifts/abc', body: any<dynamic>(named: 'body')),
      ).thenAnswer((_) async => {'data': _json});
      await source.updateShift('abc', ShiftRequestModel.fromInput(_input));
      verify(
        () => api.put('/v1/shifts/abc', body: any<dynamic>(named: 'body')),
      ).called(1);
    });

    test('rejects a write response without an item', () async {
      when(
        () => api.post('/v1/shifts', body: any<dynamic>(named: 'body')),
      ).thenAnswer((_) async => {'data': null});
      expect(
        source.createShift(ShiftRequestModel.fromInput(_input)),
        throwsA(isA<ServerException>()),
      );
    });

    test('deletes with DELETE', () async {
      when(() => api.delete('/v1/shifts/abc')).thenAnswer((_) async => {});
      await source.deleteShift('abc');
      verify(() => api.delete('/v1/shifts/abc')).called(1);
    });
  });

  group('ShiftRepositoryImpl', () {
    late _MockRemote remote;
    late _MockNetworkInfo network;
    late ShiftRepositoryImpl repository;

    setUp(() {
      remote = _MockRemote();
      network = _MockNetworkInfo();
      when(() => network.isConnected).thenAnswer((_) async => true);
      repository = ShiftRepositoryImpl(
        remoteDataSource: remote,
        networkInfo: network,
      );
    });

    test('fails with NoInternetFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      final result = await repository.getShifts();
      expect(result.getLeft().toNullable(), isA<NoInternetFailure>());
      verifyZeroInteractions(remote);
    });

    test('returns mapped entities', () async {
      when(() => remote.getShifts()).thenAnswer((_) async => [_model()]);
      final result = await repository.getShifts();
      expect(result.getRight().toNullable(), hasLength(1));
    });

    test('keeps the status code of a server conflict', () async {
      when(() => remote.createShift(any())).thenThrow(
        const ServerException(
          'Nama shift sudah dipakai di grup ini.',
          409,
          'CONFLICT_ERROR',
        ),
      );
      final result = await repository.createShift(_input);
      final failure = result.getLeft().toNullable()!;
      expect(failure.statusCode, 409);
      expect(failure.message, 'Nama shift sudah dipakai di grup ini.');
    });

    test('delete forwards the uid', () async {
      when(() => remote.deleteShift('abc')).thenAnswer((_) async {});
      final result = await repository.deleteShift('abc');
      expect(result.isRight(), isTrue);
      verify(() => remote.deleteShift('abc')).called(1);
    });

    test('maps an unreadable write response to a failure', () async {
      when(
        () => remote.updateShift('a', any()),
      ).thenAnswer((_) async => _model(start: 'xx'));
      final result = await repository.updateShift('a', _input);
      expect(result.isLeft(), isTrue);
    });
  });
}
