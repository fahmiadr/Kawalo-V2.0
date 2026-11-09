import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';

/// Value object untuk parameter query daftar insiden (filter & paginasi).
class IncidentQueryParams extends Equatable {
  /// Membuat instance [IncidentQueryParams].
  const IncidentQueryParams({
    this.groupId,
    this.status,
    this.search,
    this.startDate,
    this.endDate,
    this.limit,
    this.offset,
    this.cancelToken,
    this.isRefresh = false,
  });

  /// ID grup aktif untuk pemfilteran insiden (opsional).
  final String? groupId;

  /// Filter status siklus hidup insiden (opsional).
  final IncidentStatus? status;

  /// Kata kunci pencarian judul atau deskripsi insiden (opsional).
  final String? search;

  /// Filter tanggal mulai dalam format ISO 8601 (opsional).
  final String? startDate;

  /// Filter tanggal akhir dalam format ISO 8601 (opsional).
  final String? endDate;

  /// Jumlah data per halaman untuk infinite scroll.
  final int? limit;

  /// Titik awal data untuk kebutuhan infinite scroll.
  final int? offset;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Penanda apakah request dipicu dari pull-to-refresh.
  final bool isRefresh;

  @override
  List<Object?> get props => [
    groupId,
    status,
    search,
    startDate,
    endDate,
    limit,
    offset,
    cancelToken,
    isRefresh,
  ];
}
