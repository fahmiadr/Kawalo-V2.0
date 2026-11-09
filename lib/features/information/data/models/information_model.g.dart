// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'information_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InformationModel _$InformationModelFromJson(Map<String, dynamic> json) =>
    InformationModel(
      id: json['id'] as String,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      title: json['title'] as String?,
      text: json['text'] as String?,
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
      userProfilePic: json['user_profile_pic'] as String?,
      feedDt: json['feed_dt'] as String?,
      feedFile: json['feed_file'] as String?,
      feedType: json['feed_type'] as String?,
      groupName: json['group_name'] as String?,
      eventLocation: json['event_location'] as String?,
      eventStartDt: json['event_start_dt'] as String?,
      eventEndDt: json['event_end_dt'] as String?,
      eventDuration: const NullableIntFromNumConverter().fromJson(
        json['event_duration'],
      ),
      glat: const StringFromNumOrStringConverter().fromJson(json['glat']),
      glong: const StringFromNumOrStringConverter().fromJson(json['glong']),
    );
