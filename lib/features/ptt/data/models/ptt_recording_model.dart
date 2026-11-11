import 'package:json_annotation/json_annotation.dart';

part 'ptt_recording_model.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class PttRecordingSpeakerModel {
  const PttRecordingSpeakerModel({
    required this.id,
    required this.name,
    required this.role,
    this.email,
  });

  factory PttRecordingSpeakerModel.fromJson(Map<String, dynamic> json) =>
      _$PttRecordingSpeakerModelFromJson(json);

  @JsonKey(defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String role;

  final String? email;
}

/// `RecordingItem` of `GET /v1/ptt/recordings`. The `audio_path` field is
/// ignored: it carries the `/api/v1` prefix that `ApiClient.baseUrl` already
/// has, so the audio URL is rebuilt from [id].
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class PttRecordingModel {
  const PttRecordingModel({
    required this.id,
    required this.speaker,
    required this.startedAt,
    required this.durationMs,
    required this.sizeBytes,
    this.transcript,
    this.transcriptLocale,
    this.transcriptSource,
    this.transcriptStatus,
  });

  factory PttRecordingModel.fromJson(Map<String, dynamic> json) =>
      _$PttRecordingModelFromJson(json);

  final String id;
  final PttRecordingSpeakerModel speaker;
  final String startedAt;

  @JsonKey(defaultValue: 0)
  final int durationMs;

  @JsonKey(defaultValue: 0)
  final int sizeBytes;

  // Absent on servers without transcription.
  final String? transcript;
  final String? transcriptLocale;
  final String? transcriptSource;
  final String? transcriptStatus;
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class PttRecordingPageModel {
  const PttRecordingPageModel({required this.items, this.nextBefore});

  factory PttRecordingPageModel.fromJson(Map<String, dynamic> json) =>
      _$PttRecordingPageModelFromJson(json);

  @JsonKey(defaultValue: <PttRecordingModel>[])
  final List<PttRecordingModel> items;

  final String? nextBefore;
}
