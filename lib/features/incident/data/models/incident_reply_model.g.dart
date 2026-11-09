// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incident_reply_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncidentReplyModel _$IncidentReplyModelFromJson(Map<String, dynamic> json) =>
    IncidentReplyModel(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: _createdAtOrNow(json['created_at']),
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
