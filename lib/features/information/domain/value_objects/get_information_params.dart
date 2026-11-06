import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Value object parameter domain untuk mengambil daftar informasi / feed.
///
/// Bertindak sebagai Query Model murni di Domain Layer yang digunakan
/// oleh UseCase dan Repository tanpa terikat ke format teknis HTTP.
class GetInformationParams extends Equatable {
  /// Membuat instance [GetInformationParams].
  const GetInformationParams({
    this.search,
    this.limit,
    this.offset,
    this.startDate,
    this.endDate,
    this.createdBy,
    this.cancelToken,
    this.isRefresh = false,
  });

  /// Kata kunci pencarian judul, isi, nama, email pembuat, atau lokasi.
  final String? search;

  /// Batas jumlah rekor data per halaman.
  final int? limit;

  /// Offset data untuk paginasi.
  final int? offset;

  /// Filter tanggal mulai (YYYY-MM-DD).
  final String? startDate;

  /// Filter tanggal akhir (YYYY-MM-DD).
  final String? endDate;

  /// Filter berdasarkan email pembuat informasi.
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
