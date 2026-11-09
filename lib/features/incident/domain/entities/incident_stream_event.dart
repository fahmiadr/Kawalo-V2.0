import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';

/// Hirarki sealed class untuk seluruh event realtime yang diterima melalui SSE
/// pada layar detail insiden.
sealed class IncidentStreamEvent extends Equatable {
  const IncidentStreamEvent();
}

/// Event saat ada balasan pesan baru dari rekan satu grup atau admin.
class IncidentReplyStreamEvent extends IncidentStreamEvent {
  /// Membuat instance [IncidentReplyStreamEvent].
  const IncidentReplyStreamEvent(this.reply);

  /// Entitas pesan balasan baru.
  final IncidentReplyEntity reply;

  @override
  List<Object?> get props => [reply];
}

/// Event saat insiden berhasil diselesaikan oleh rekan atau admin,
/// mengunci thread ke status read-only.
class IncidentResolvedStreamEvent extends IncidentStreamEvent {
  /// Membuat instance [IncidentResolvedStreamEvent].
  const IncidentResolvedStreamEvent({
    required this.incidentId,
    required this.resolvedBy,
    required this.resolvedByName,
    required this.resolvedAt,
  });

  /// ID insiden yang diselesaikan.
  final String incidentId;

  /// ID pengguna yang menyelesaikan insiden.
  final String resolvedBy;

  /// Nama lengkap pengguna yang menyelesaikan insiden.
  final String resolvedByName;

  /// Waktu penyelesaian insiden.
  final DateTime resolvedAt;

  @override
  List<Object?> get props => [
    incidentId,
    resolvedBy,
    resolvedByName,
    resolvedAt,
  ];
}

/// Event saat insiden dihapus secara administratif (soft-delete) oleh admin.
class IncidentDeletedStreamEvent extends IncidentStreamEvent {
  /// Membuat instance [IncidentDeletedStreamEvent].
  const IncidentDeletedStreamEvent({
    required this.incidentId,
    required this.deletedAt,
  });

  /// ID insiden yang dihapus.
  final String incidentId;

  /// Waktu penghapusan insiden.
  final DateTime deletedAt;

  @override
  List<Object?> get props => [incidentId, deletedAt];
}

/// Event saat data layer mendeteksi buffer overflow pada server (HTTP 410 / sync_required)
/// dan telah melakukan sinkronisasi penuh untuk menyegarkan snapshot state.
class IncidentResyncedStreamEvent extends IncidentStreamEvent {
  /// Membuat instance [IncidentResyncedStreamEvent].
  const IncidentResyncedStreamEvent({
    required this.incident,
    required this.replies,
  });

  /// Snapshot data header insiden terkini.
  final IncidentEntity incident;

  /// Snapshot seluruh balasan thread insiden terkini.
  final List<IncidentReplyEntity> replies;

  @override
  List<Object?> get props => [incident, replies];
}
