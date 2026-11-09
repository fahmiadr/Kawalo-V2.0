import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';

/// Ringkasan hasil pemanggilan daftar insiden beserta transparansi sumber data
/// (apakah data berasal dari cache lokal Isar atau server remote).
class IncidentListResult extends Equatable {
  /// Membuat instance [IncidentListResult].
  const IncidentListResult({required this.items, this.isFromCache = false});

  /// Daftar laporan insiden.
  final List<IncidentEntity> items;

  /// Menandakan apakah data bersumber dari cache lokal (offline).
  final bool isFromCache;

  @override
  List<Object?> get props => [items, isFromCache];
}
