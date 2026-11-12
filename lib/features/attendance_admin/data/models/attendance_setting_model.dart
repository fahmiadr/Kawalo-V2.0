import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';

/// `data` of `GET/PUT /attendance/settings`. Hand-written because the server
/// owns the shape; range fields fall back to the documented limits.
class AttendanceSettingModel {
  const AttendanceSettingModel(this.json);

  final Map<String, dynamic> json;

  int _int(String key, int fallback) =>
      (json[key] as num?)?.toInt() ?? fallback;

  String? _string(String key) {
    final value = json[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  AttendanceSettingEntity toEntity() {
    final defaultPercent = _int('default_percent', 40);
    return AttendanceSettingEntity(
      faceMatchPercent: _int('face_match_percent', defaultPercent),
      defaultPercent: defaultPercent,
      minPercent: _int('min_percent', 20),
      maxPercent: _int('max_percent', 95),
      isDefault: json['is_default'] as bool? ?? true,
      updatedBy: _string('updated_by'),
      updatedAt: _string('updated_at'),
    );
  }
}
