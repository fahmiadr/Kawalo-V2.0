import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_query_params.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';

/// Parameter input untuk usecase pengambilan daftar insiden.
class GetIncidentsParams extends Equatable {
  /// Membuat instance [GetIncidentsParams].
  const GetIncidentsParams({
    required this.session,
    this.status,
    this.search,
    this.startDate,
    this.endDate,
    this.limit,
    this.offset,
    this.cancelToken,
    this.isRefresh = false,
  });

  /// Sesi autentikasi aktif pengguna.
  final AuthSessionEntity? session;

  /// Filter status siklus hidup insiden (opsional).
  final IncidentStatus? status;

  /// Kata kunci pencarian judul atau deskripsi insiden (opsional).
  final String? search;

  /// Tanggal awal filter rentang waktu dalam format ISO 8601 (opsional).
  final String? startDate;

  /// Tanggal akhir filter rentang waktu dalam format ISO 8601 (opsional).
  final String? endDate;

  /// Limit item per permintaan untuk infinite scroll.
  final int? limit;

  /// Titik awal data untuk kebutuhan infinite scroll.
  final int? offset;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Penanda apakah pemanggilan berasal dari pull-to-refresh.
  final bool isRefresh;

  /// Verifikasi otorisasi: pengguna harus memiliki sesi aktif dan terdaftar
  /// pada suatu grup (atau admin).
  bool get isAuthorized {
    if (session == null) return false;
    final groupUid = session?.groupUid;
    return (groupUid != null && groupUid.isNotEmpty) ||
        (session?.allowAdmin ?? false);
  }

  /// Mengonversi parameter ke Value Object repositori.
  IncidentQueryParams toQueryParams() {
    return IncidentQueryParams(
      groupId: session?.groupUid,
      status: status,
      search: search,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
      cancelToken: cancelToken,
      isRefresh: isRefresh,
    );
  }

  @override
  List<Object?> get props => [
        session,
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
