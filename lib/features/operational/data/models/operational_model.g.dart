// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operational_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DutyTimelineModel _$DutyTimelineModelFromJson(Map<String, dynamic> json) =>
    DutyTimelineModel(
      id: json['id'] as String,
      journeyUid: json['journey_uid'] as String?,
      duty: json['duty'] as String?,
      state: json['state'] as String?,
      dutyDt: json['duty_dt'] as String?,
      stateDt: json['state_dt'] as String?,
    );

OperationalModel _$OperationalModelFromJson(Map<String, dynamic> json) =>
    OperationalModel(
      id: json['id'] as String,
      userEmail: json['user_email'] as String,
      totalActivities: json['total_activities'] == null
          ? 0
          : const IntFromNumConverter().fromJson(json['total_activities']),
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map(
                  (e) => DutyTimelineModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userName: json['user_name'] as String?,
      userProfilePic: json['user_profile_pic'] as String?,
      groupName: json['group_name'] as String?,
      latestDuty: json['latest_duty'] as String?,
      latestState: json['latest_state'] as String?,
      latestDutyDt: json['latest_duty_dt'] as String?,
      latestStateDt: json['latest_state_dt'] as String?,
      dutyDate: json['duty_date'] as String?,
    );
