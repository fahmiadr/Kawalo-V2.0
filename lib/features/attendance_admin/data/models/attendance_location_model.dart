import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_location_entity.dart';

/// `data` of `GET/PUT /attendance/location`. Hand-written because the server
/// owns the shape; range fields fall back to the documented limits.
class AttendanceLocationModel {
  const AttendanceLocationModel(this.json);

  final Map<String, dynamic> json;

  String? _string(String key) {
    final value = json[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  AttendanceLocationEntity toEntity() {
    final latitude = (json['glat'] as num?)?.toDouble();
    final longitude = (json['glong'] as num?)?.toDouble();
    final radius = (json['radius'] as num?)?.toInt();
    // A half-filled row cannot be edited meaningfully; treat it as unset.
    final configured =
        json['configured'] == true &&
        latitude != null &&
        longitude != null &&
        radius != null;
    return AttendanceLocationEntity(
      configured: configured,
      locationName: configured ? _string('location_name') : null,
      latitude: configured ? latitude : null,
      longitude: configured ? longitude : null,
      radius: configured ? radius : null,
      minRadius: (json['min_radius'] as num?)?.toInt() ?? 10,
      maxRadius: (json['max_radius'] as num?)?.toInt() ?? 1000,
      updatedBy: _string('updated_by'),
      updatedAt: _string('updated_at'),
    );
  }
}
