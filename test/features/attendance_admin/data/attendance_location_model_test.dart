import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/attendance_location_model.dart';

void main() {
  test('parses a configured point, accepting integer coordinates', () {
    final entity = const AttendanceLocationModel({
      'configured': true,
      'location_name': ' Pos Utama ',
      'glat': -6.2088,
      'glong': 106,
      'radius': 150,
      'min_radius': 10,
      'max_radius': 1000,
      'updated_by': 'admin@kawalo.id',
      'updated_at': '2026-11-12T01:00:00.000Z',
    }).toEntity();

    expect(entity.configured, isTrue);
    expect(entity.locationName, 'Pos Utama');
    expect(entity.latitude, -6.2088);
    expect(entity.longitude, 106.0);
    expect(entity.radius, 150);
    expect(entity.updatedBy, 'admin@kawalo.id');
    expect(entity.updatedAt, '2026-11-12T01:00:00.000Z');
  });

  test('an unset point has no coordinates and keeps the limits', () {
    final entity = const AttendanceLocationModel({
      'configured': false,
      'location_name': null,
      'glat': null,
      'glong': null,
      'radius': null,
      'min_radius': 10,
      'max_radius': 500,
      'updated_by': null,
      'updated_at': null,
    }).toEntity();

    expect(entity.configured, isFalse);
    expect(entity.latitude, isNull);
    expect(entity.radius, isNull);
    expect(entity.minRadius, 10);
    expect(entity.maxRadius, 500);
    expect(entity.updatedBy, isNull);
  });

  test('missing fields fall back to the documented limits', () {
    final entity = const AttendanceLocationModel({}).toEntity();

    expect(entity.configured, isFalse);
    expect(entity.minRadius, 10);
    expect(entity.maxRadius, 1000);
  });

  test('a configured flag without coordinates is treated as unset', () {
    final entity = const AttendanceLocationModel({
      'configured': true,
      'location_name': 'Pos',
      'glat': -6.2,
      'radius': 100,
    }).toEntity();

    expect(entity.configured, isFalse);
    expect(entity.locationName, isNull);
    expect(entity.radius, isNull);
  });
}
