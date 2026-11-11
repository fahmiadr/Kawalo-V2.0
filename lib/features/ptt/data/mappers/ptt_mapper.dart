import 'package:kawalo_mobile/features/ptt/data/models/ptt_event_dto.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_transcript.dart';

/// Dedicated Mapper untuk konversi dua arah DTO <-> Domain Entity PTT.
class PttMapper {
  const PttMapper._();

  static PttSpeakerEntity toSpeakerEntity(PttSpeakerDto dto) {
    return PttSpeakerEntity(userId: dto.userId, name: dto.name, role: dto.role);
  }

  static PttFloorStateEntity toFloorStateEntity(PttFloorStateDto dto) {
    final status = dto.state.toUpperCase() == 'TRANSMITTING'
        ? PttFloorStatus.transmitting
        : PttFloorStatus.idle;

    final speaker = dto.speaker != null ? toSpeakerEntity(dto.speaker!) : null;

    return PttFloorStateEntity(
      status: status,
      speaker: speaker,
      memberCount: dto.memberCount,
    );
  }

  static PttConnectionStatus toConnectionStatus(String statusStr) {
    switch (statusStr.toUpperCase()) {
      case 'CONNECTING':
        return PttConnectionStatus.connecting;
      case 'CONNECTED':
        return PttConnectionStatus.connected;
      case 'RECONNECTING':
        return PttConnectionStatus.reconnecting;
      case 'DISCONNECTED':
      default:
        return PttConnectionStatus.disconnected;
    }
  }

  /// Parses a native `transcriptReady` payload; `null` when it names no turn
  /// or no known status. An `ok` without text is downgraded to `failed` so the
  /// server still transcribes the turn.
  static PttTranscript? toTranscript(Map<dynamic, dynamic> map) {
    final requestId = map['requestId']?.toString() ?? '';
    final status = PttTranscriptStatus.tryParse(map['status']?.toString());
    if (requestId.isEmpty || status == null) return null;

    final text = map['text']?.toString().trim();
    final hasText = text != null && text.isNotEmpty;
    final ok = status == PttTranscriptStatus.ok && hasText;
    return PttTranscript(
      requestId: requestId,
      status: status == PttTranscriptStatus.ok && !hasText
          ? PttTranscriptStatus.failed
          : status,
      text: ok ? text : null,
      locale: ok ? map['locale']?.toString() : null,
      reason: map['reason']?.toString(),
    );
  }
}
