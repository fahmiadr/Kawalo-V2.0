import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Value object parameter domain untuk mengambil daftar data tamu.
///
/// Bertindak sebagai Request Model murni di Domain Layer yang digunakan
/// oleh UseCase dan Repository tanpa terikat ke format teknis HTTP.
class GetGuestsParams extends Equatable {
  /// Membuat instance [GetGuestsParams].
  const GetGuestsParams({
    this.search,
    this.limit,
    this.offset,
    this.startDate,
    this.endDate,
    this.createdBy,
    this.cancelToken,
    this.isRefresh = false,
  });

  /// Kata kunci pencarian nama, nomor, atau atribut tamu.
  final String? search;

  /// Batas jumlah rekor data.
  final int? limit;

  /// Offset data untuk paginasi.
  final int? offset;

  /// Filter tanggal mulai (ISO 8601).
  final String? startDate;

  /// Filter tanggal akhir (ISO 8601).
  final String? endDate;

  /// Filter berdasarkan email pembuat data tamu.
  final String? createdBy;

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
    createdBy,
    cancelToken,
    isRefresh,
  ];
}
