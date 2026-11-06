import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Value object parameter domain untuk mengambil daftar personil operasional.
///
/// Bertindak sebagai Request Model murni di Domain Layer yang digunakan
/// oleh UseCase dan Repository tanpa terikat ke format teknis HTTP.
class GetOperationalsParams extends Equatable {
  /// Membuat instance [GetOperationalsParams].
  const GetOperationalsParams({
    this.search,
    this.limit,
    this.offset,
    this.startDate,
    this.endDate,
    this.cancelToken,
    this.isRefresh = false,
  });

  /// Kata kunci pencarian nama atau email personil operasional.
  final String? search;

  /// Batas jumlah data.
  final int? limit;

  /// Offset data untuk paginasi.
  final int? offset;

  /// Filter tanggal mulai rentang waktu (ISO 8601).
  final String? startDate;

  /// Filter tanggal akhir rentang waktu (ISO 8601).
  final String? endDate;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Menandakan apakah pemanggilan berasal dari pull-to-refresh
  /// yang mewajibkan percobaan koneksi ke server remote terlebih dahulu.
  final bool isRefresh;

  @override
  List<Object?> get props => [
        search,
        limit,
        offset,
        startDate,
        endDate,
        cancelToken,
        isRefresh,
      ];
}
