import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';

PttRecordingEntity recording(
  String id, {
  String name = 'Budi',
  String? email = 'budi@kawalo.id',
  DateTime? startedAt,
  Duration duration = const Duration(seconds: 12),
}) => PttRecordingEntity(
  id: id,
  speakerId: 'usr_$id',
  speakerName: name,
  speakerRole: 'GUARD',
  speakerEmail: email,
  startedAt: startedAt ?? DateTime(2026, 11, 11, 9, 30),
  duration: duration,
  sizeBytes: 24000,
);

AuthSessionEntity session({
  bool admin = false,
  String email = 'admin@kawalo.id',
}) => AuthSessionEntity(
  userId: 'usr_me',
  email: email,
  name: 'Saya',
  allowAdmin: admin,
  allowPatrol: false,
  allowMonPatrol: false,
  role: admin ? 'ADMIN' : 'GUARD',
);
