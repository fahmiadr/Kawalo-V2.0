import 'package:kawalo_mobile/features/ptt/data/models/ptt_event_dto.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';

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
}
