import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'incident_reply_model.g.dart';

/// Server may omit `created_at`; fall back to the moment of parsing.
String _createdAtOrNow(Object? value) =>
    (value as String?) ?? DateTime.now().toIso8601String();

/// Pure DTO model untuk pesan balasan thread insiden (`IncidentReplyDto`).
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
@JsonSerializable(fieldRename: FieldRename.snake)
class IncidentReplyModel extends Equatable {
  const IncidentReplyModel({
    required this.id,
    required this.incidentId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.photos = const [],
  });

  factory IncidentReplyModel.fromJson(Map<String, dynamic> json) =>
      _$IncidentReplyModelFromJson(json);

  /// ID unik balasan.
  final String id;

  /// ID insiden terkait.
  @JsonKey(defaultValue: '')
  final String incidentId;

  /// ID pengguna pengirim.
  @JsonKey(defaultValue: '')
  final String senderId;

  /// Nama lengkap pengirim.
  @JsonKey(defaultValue: '')
  final String senderName;

  /// Role pengirim ('admin', 'guard').
  @JsonKey(defaultValue: '')
  final String senderRole;

  /// Pesan teks.
  @JsonKey(defaultValue: '')
  final String message;

  /// Daftar URL foto lampiran balasan.
  @JsonKey(defaultValue: <String>[])
  final List<String> photos;

  /// ISO 8601 timestamp saat balasan dikirimkan.
  @JsonKey(fromJson: _createdAtOrNow)
  final String createdAt;

  Map<String, dynamic> toJson() => _$IncidentReplyModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    incidentId,
    senderId,
    senderName,
    senderRole,
    message,
    photos,
    createdAt,
  ];
}
