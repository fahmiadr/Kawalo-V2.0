import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';

String? _str(Object? v) => v is String ? v : null;

/// Item of `GET /v1/schedules` (admin view). Hand-written JSON: the shape is
/// small and nullable fields are tolerant of legacy rows.
class ManagedScheduleModel {
  const ManagedScheduleModel({
    required this.id,
    required this.date,
    required this.email,
    required this.name,
    required this.isMember,
    required this.locked,
    this.shiftUid,
    this.shiftName,
    this.shiftColor,
    this.startTime,
    this.endTime,
    this.locationName,
    this.checkin,
    this.checkout,
    this.lateMins = 0,
    this.avatarUrl,
  });

  factory ManagedScheduleModel.fromJson(Map<String, dynamic> json) {
    final late = json['late_mins'];
    return ManagedScheduleModel(
      id: json['id'].toString(),
      date: _str(json['date']) ?? '',
      email: _str(json['email']) ?? '',
      name: _str(json['name']) ?? '',
      isMember: json['is_member'] != false,
      locked: json['locked'] == true,
      shiftUid: _str(json['shift_uid']),
      shiftName: _str(json['shift_name']),
      shiftColor: _str(json['shift_color']),
      startTime: _str(json['start_time']),
      endTime: _str(json['end_time']),
      locationName: _str(json['location_name']),
      checkin: _str(json['checkin']),
      checkout: _str(json['checkout']),
      lateMins: late is num ? late.toInt() : 0,
      avatarUrl: _str(json['avatar_url']),
    );
  }

  final String id;
  final String date;
  final String email;
  final String name;
  final bool isMember;
  final bool locked;
  final String? shiftUid;
  final String? shiftName;
  final String? shiftColor;
  final String? startTime;
  final String? endTime;
  final String? locationName;
  final String? checkin;
  final String? checkout;
  final int lateMins;
  final String? avatarUrl;
}

/// Item of `GET /v1/shifts`; only what the schedule form needs.
class ShiftOptionModel {
  const ShiftOptionModel({
    required this.uid,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.color,
    this.locationName,
  });

  factory ShiftOptionModel.fromJson(Map<String, dynamic> json) =>
      ShiftOptionModel(
        uid: json['uid'].toString(),
        name: _str(json['name']) ?? '',
        startTime: _str(json['start_time']) ?? '',
        endTime: _str(json['end_time']) ?? '',
        color: _str(json['color']),
        locationName: _str(json['location_name']),
      );

  final String uid;
  final String name;
  final String startTime;
  final String endTime;
  final String? color;
  final String? locationName;
}

class BulkScheduleResultModel {
  const BulkScheduleResultModel({
    required this.created,
    required this.replaced,
    required this.skipped,
    required this.skippedItems,
  });

  factory BulkScheduleResultModel.fromJson(Map<String, dynamic> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    final items = json['skipped_items'];
    return BulkScheduleResultModel(
      created: count('created'),
      replaced: count('replaced'),
      skipped: count('skipped'),
      skippedItems: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(
                  (e) => SkippedEntry(
                    index: (e['index'] as num?)?.toInt() ?? 0,
                    reason: _str(e['reason']) ?? '',
                    code: _str(e['code']),
                  ),
                )
                .toList()
          : const [],
    );
  }

  final int created;
  final int replaced;
  final int skipped;
  final List<SkippedEntry> skippedItems;
}

class DeleteSchedulesResultModel {
  const DeleteSchedulesResultModel({
    required this.deletedCount,
    required this.skippedCount,
  });

  factory DeleteSchedulesResultModel.fromJson(Map<String, dynamic> json) =>
      DeleteSchedulesResultModel(
        deletedCount: (json['deleted_count'] as num?)?.toInt() ?? 0,
        skippedCount: (json['skipped_count'] as num?)?.toInt() ?? 0,
      );

  final int deletedCount;
  final int skippedCount;
}

/// Request body of create/update/bulk items.
Map<String, dynamic> scheduleEntryToJson(ScheduleEntry e) => {
  'email': e.email,
  'shift_uid': e.shiftUid,
  'date': isoDate(e.date),
};

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
