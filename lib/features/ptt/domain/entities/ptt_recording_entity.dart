import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum PttTranscriptSource {
  device,
  server;

  /// Unknown values map to null so a newer server never breaks the list.
  static PttTranscriptSource? tryParse(String? value) => switch (value) {
    'device' => device,
    'server' => server,
    _ => null,
  };
}

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
    this.speakerAvatarUrl,
    this.transcript,
    this.transcriptLocale,
    this.transcriptSource,
    this.transcriptStatus,
    this.waveform,
  });

  final String id;
  final String speakerId;
  final String speakerName;
  final String speakerRole;

  /// The API identifies people by email elsewhere (incident `senderId`), so
  /// this is what "is it me" is compared against, not [speakerId].
  final String? speakerEmail;
  final String? speakerAvatarUrl;
  final DateTime startedAt;
  final Duration duration;
  final int sizeBytes;
  final String? transcript;
  final String? transcriptLocale;
  final PttTranscriptSource? transcriptSource;

  /// Raw server status (`done`, `no_speech`, ...); kept for logic only, the UI
  /// never shows it.
  final String? transcriptStatus;

  /// Loudness bars `0..255` measured by the server over the whole turn; null
  /// for turns recorded before it kept them.
  final Uint8List? waveform;

  /// Trimmed transcript, or null when there is nothing worth showing.
  String? get displayTranscript {
    final text = transcript?.trim();
    return text == null || text.isEmpty ? null : text;
  }

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
    speakerAvatarUrl,
    startedAt,
    duration,
    sizeBytes,
    transcript,
    transcriptLocale,
    transcriptSource,
    transcriptStatus,
    waveform,
  ];
}
