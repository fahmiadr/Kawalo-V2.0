// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptt_recording_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PttRecordingSpeakerModel _$PttRecordingSpeakerModelFromJson(
  Map<String, dynamic> json,
) => PttRecordingSpeakerModel(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  role: json['role'] as String? ?? '',
  email: json['email'] as String?,
);

PttRecordingModel _$PttRecordingModelFromJson(Map<String, dynamic> json) =>
    PttRecordingModel(
      id: json['id'] as String,
      speaker: PttRecordingSpeakerModel.fromJson(
        json['speaker'] as Map<String, dynamic>,
      ),
      startedAt: json['started_at'] as String,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    );

PttRecordingPageModel _$PttRecordingPageModelFromJson(
  Map<String, dynamic> json,
) => PttRecordingPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => PttRecordingModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  nextBefore: json['next_before'] as String?,
);
