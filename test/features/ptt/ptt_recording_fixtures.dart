import 'dart:typed_data';

import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';

PttRecordingEntity recording(
  String id, {
  String name = 'Budi',
  String? email = 'budi@kawalo.id',
  DateTime? startedAt,
  Duration duration = const Duration(seconds: 12),
  String? transcript,
  PttTranscriptSource? transcriptSource = PttTranscriptSource.server,
  String? transcriptStatus,
  String? speakerId,
  String role = 'GUARD',
  Uint8List? waveform,
  String? avatarUrl,
}) => PttRecordingEntity(
  id: id,
  speakerId: speakerId ?? 'usr_$id',
  speakerName: name,
  speakerRole: role,
  speakerEmail: email,
  speakerAvatarUrl: avatarUrl,
  startedAt: startedAt ?? DateTime(2026, 11, 11, 9, 30),
  duration: duration,
  sizeBytes: 24000,
  transcript: transcript,
  transcriptLocale: transcript == null ? null : 'id-ID',
  transcriptSource: transcript == null ? null : transcriptSource,
  transcriptStatus: transcriptStatus,
  waveform: waveform,
);

/// [admin] is the ADMIN role (with the flag). [role] and [allowAdmin]
/// override them, e.g. a GUARD that still carries `allowAdmin`.
AuthSessionEntity session({
  bool admin = false,
  String email = 'admin@kawalo.id',
  String? role,
  bool? allowAdmin,
}) => AuthSessionEntity(
  userId: 'usr_me',
  email: email,
  name: 'Saya',
  allowAdmin: allowAdmin ?? admin,
  allowPatrol: false,
  allowMonPatrol: false,
  role: role ?? (admin ? 'ADMIN' : 'GUARD'),
);
