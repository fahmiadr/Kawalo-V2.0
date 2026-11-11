import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

PttMemberEntity member(
  String id, {
  String? name,
  String role = 'GUARD',
  bool speaking = false,
}) => PttMemberEntity(
  userId: id,
  name: name ?? 'Nama $id',
  role: role,
  speaking: speaking,
);

PttIdle idleState({
  PttConnectionStatus status = PttConnectionStatus.connected,
  int? memberCount,
}) => PttIdle(
  channel: PttChannelEntity(
    groupUid: 'grp_1',
    connectionStatus: status,
    memberCount: memberCount,
  ),
  floorState: const PttFloorStateEntity.idle(),
);

PttListening listeningState({required String speakerId, int? memberCount}) =>
    PttListening(
      channel: PttChannelEntity(
        groupUid: 'grp_1',
        connectionStatus: PttConnectionStatus.connected,
        memberCount: memberCount,
      ),
      floorState: PttFloorStateEntity(
        status: PttFloorStatus.transmitting,
        speaker: PttSpeakerEntity(
          userId: speakerId,
          name: 'Pembicara',
          role: 'GUARD',
        ),
        memberCount: memberCount,
      ),
    );
