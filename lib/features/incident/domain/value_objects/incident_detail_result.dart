import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';

/// Hasil query detail insiden yang memuat header insiden dan riwayat balasan
/// thread.
class IncidentDetailResult extends Equatable {
  /// Membuat instance [IncidentDetailResult].
  const IncidentDetailResult({required this.incident, required this.replies});

  /// Entitas utama header insiden.
  final IncidentEntity incident;

  /// Daftar riwayat pesan balasan di dalam thread insiden.
  final List<IncidentReplyEntity> replies;

  @override
  List<Object?> get props => [incident, replies];
}
