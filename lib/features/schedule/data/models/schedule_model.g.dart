// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) =>
    ScheduleModel(
      id: json['id'] as String,
      date: json['date'] as String,
      shiftName: json['shift_name'] as String?,
      shiftColor: json['shift_color'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      locationName: json['location_name'] as String?,
    );
