import 'package:equatable/equatable.dart';

/// One recorded PTT turn of the active group.
class PttRecordingEntity extends Equatable {
  const PttRecordingEntity({
    required this.id,
    required this.speakerId,
    required this.speakerName,
    required this.speakerRole,
    required this.startedAt,
    required this.duration,
    required this.sizeBytes,
    this.speakerEmail,
  });

  final String id;
  final String speakerId;
  final String speakerName;
  final String speakerRole;

  /// The API identifies people by email elsewhere (incident `senderId`), so
  /// this is what "is it me" is compared against, not [speakerId].
  final String? speakerEmail;
  final DateTime startedAt;
  final Duration duration;
  final int sizeBytes;

  bool isSpokenBy(String? email) {
    final mine = email?.trim().toLowerCase();
    final theirs = speakerEmail?.trim().toLowerCase();
    return mine != null && mine.isNotEmpty && theirs != null && theirs == mine;
  }

  @override
  List<Object?> get props => [
    id,
    speakerId,
    speakerName,
    speakerRole,
    speakerEmail,
    startedAt,
    duration,
    sizeBytes,
  ];
}
