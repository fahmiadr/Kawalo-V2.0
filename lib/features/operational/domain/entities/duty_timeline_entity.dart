import 'package:equatable/equatable.dart';

/// Entitas domain murni satu aktivitas / titik perjalanan tugas personil.
class DutyTimelineEntity extends Equatable {
  /// Membuat instance [DutyTimelineEntity].
  const DutyTimelineEntity({
    required this.id,
    this.journeyUid,
    this.duty,
    this.state,
    this.dutyDt,
    this.stateDt,
  });

  /// ID unik rekaman tugas (DutyJourneyId).
  final String id;

  /// UID rekaman tugas (DutyJourneyUID).
  final String? journeyUid;

  /// Nama / jenis tugas operasional (DutyDuty). Misal: "Patroli", "Standby".
  final String? duty;

  /// Status / kondisi tugas operasional (DutyState). Misal: "Aktif", "Selesai".
  final String? state;

  /// Waktu pelaksanaan tugas (DutyDutyDT).
  final String? dutyDt;

  /// Waktu status tugas tercatat (DutyStateDT).
  final String? stateDt;

  @override
  List<Object?> get props => [id, journeyUid, duty, state, dutyDt, stateDt];
}
