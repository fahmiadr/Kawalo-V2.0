// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) =>
    AttendanceModel(
      id: json['id'] as String,
      category: json['category'] as String,
      diffMinutes: json['diff_minutes'] == null
          ? 0
          : const IntFromNumConverter().fromJson(json['diff_minutes']),
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
      userProfilePic: json['user_profile_pic'] as String?,
      userDuty: json['user_duty'] as String?,
      attendanceDt: json['attendance_dt'] as String?,
      attendanceType: json['attendance_type'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      locationName: json['location_name'] as String?,
      shiftName: json['shift_name'] as String?,
      shiftColor: json['shift_color'] as String?,
      shiftTimeWindow: json['shift_time_window'] as String?,
      groupName: json['group_name'] as String?,
    );
