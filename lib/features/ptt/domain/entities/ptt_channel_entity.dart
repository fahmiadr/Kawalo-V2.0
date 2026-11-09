import 'package:equatable/equatable.dart';

/// Status konektivitas soket latar belakang saluran PTT.
enum PttConnectionStatus { disconnected, connecting, connected, reconnecting }

/// Pure Domain Entity yang merepresentasikan sesi saluran PTT aktif.
class PttChannelEntity extends Equatable {
  const PttChannelEntity({
    required this.groupUid,
    this.connectionStatus = PttConnectionStatus.disconnected,
    this.memberCount = 1,
  });

  final String groupUid;
  final PttConnectionStatus connectionStatus;
  final int memberCount;

  PttChannelEntity copyWith({
    String? groupUid,
    PttConnectionStatus? connectionStatus,
    int? memberCount,
  }) {
    return PttChannelEntity(
      groupUid: groupUid ?? this.groupUid,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  List<Object?> get props => [groupUid, connectionStatus, memberCount];
}
