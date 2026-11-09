import 'package:equatable/equatable.dart';

/// Status pendudukan hak bicara (floor) pada saluran PTT.
enum PttFloorStatus {
  /// Saluran kosong, siap untuk transmisi.
  idle,

  /// Saluran sedang dipakai oleh seorang pembicara aktif.
  transmitting,
}

/// Representasi identitas pembicara aktif pada saluran PTT.
class PttSpeakerEntity extends Equatable {
  const PttSpeakerEntity({
    required this.userId,
    required this.name,
    required this.role,
  });

  final String userId;
  final String name;
  final String role;

  /// Memeriksa apakah pembicara memiliki wewenang administratif.
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  @override
  List<Object?> get props => [userId, name, role];
}

/// Pure Domain Entity yang merepresentasikan status floor saluran PTT saat ini.
class PttFloorStateEntity extends Equatable {
  const PttFloorStateEntity({
    required this.status,
    this.speaker,
    this.memberCount = 1,
  });

  /// Factory untuk kondisi channel IDLE tanpa pembicara aktif.
  const PttFloorStateEntity.idle({int memberCount = 1})
    : this(
        status: PttFloorStatus.idle,
        speaker: null,
        memberCount: memberCount,
      );

  final PttFloorStatus status;
  final PttSpeakerEntity? speaker;
  final int memberCount;

  /// Menandakan apakah saluran sedang ditempati oleh pembicara lain.
  bool get isOccupied =>
      status == PttFloorStatus.transmitting && speaker != null;

  @override
  List<Object?> get props => [status, speaker, memberCount];
}
