import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';

abstract class PttState extends Equatable {
  const PttState({required this.channel, required this.floorState});

  final PttChannelEntity channel;
  final PttFloorStateEntity floorState;

  @override
  List<Object?> get props => [channel, floorState];
}

/// Keadaan inisial sebelum saluran diakses.
class PttInitial extends PttState {
  const PttInitial()
    : super(
        channel: const PttChannelEntity(groupUid: ''),
        floorState: const PttFloorStateEntity.idle(),
      );
}

/// Sedang melakukan handshake dan koneksi WebSocket latar belakang.
class PttConnecting extends PttState {
  const PttConnecting({required super.channel, required super.floorState});
}

/// Saluran terhubung dan siap, tidak ada yang sedang berbicara.
class PttIdle extends PttState {
  const PttIdle({required super.channel, required super.floorState});
}

/// Pengguna menekan tombol dan sedang menunggu balasan arbitrase server.
class PttRequestingFloor extends PttState {
  const PttRequestingFloor({
    required super.channel,
    required super.floorState,
    required this.requestId,
  });

  final String requestId;

  @override
  List<Object?> get props => [channel, floorState, requestId];
}

/// Hak bicara dikabulkan (Floor Granted), mikrofon aktif, mengirim audio Opus.
class PttTransmitting extends PttState {
  const PttTransmitting({
    required super.channel,
    required super.floorState,
    this.leaseTtlMs = 2000,
  });

  final int leaseTtlMs;

  @override
  List<Object?> get props => [channel, floorState, leaseTtlMs];
}

/// Pengguna lain sedang berbicara, audio langsung diputar via speaker.
class PttListening extends PttState {
  const PttListening({
    required super.channel,
    required super.floorState,
    this.preemptedBy,
  });

  final String? preemptedBy;

  @override
  List<Object?> get props => [channel, floorState, preemptedBy];
}

/// Permintaan hak bicara ditolak (Floor Denied) karena channel sibuk /
/// prioritas tidak cukup.
class PttFloorDenied extends PttState {
  const PttFloorDenied({
    required super.channel,
    required super.floorState,
    required this.reason,
  });

  final String reason;

  @override
  List<Object?> get props => [channel, floorState, reason];
}

/// Jaringan seluler terputus dan sedang mencoba menyambung ulang
/// secara otomatis.
class PttReconnecting extends PttState {
  const PttReconnecting({required super.channel, required super.floorState});
}

/// Koneksi terputus total.
class PttDisconnected extends PttState {
  const PttDisconnected({
    required super.channel,
    required super.floorState,
    this.errorMessage,
  });

  final String? errorMessage;

  @override
  List<Object?> get props => [channel, floorState, errorMessage];
}
