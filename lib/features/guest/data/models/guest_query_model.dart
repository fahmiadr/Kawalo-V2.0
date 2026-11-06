import 'package:equatable/equatable.dart';

/// Model kontrak request query untuk endpoint REST API backend
/// `GET /v1/guests` sesuai skema `GetGuestsQueryDto`.
class GuestQueryModel extends Equatable {
  /// Membuat instance [GuestQueryModel].
  const GuestQueryModel({
    this.search,
    this.limit,
    this.offset,
    this.startDate,
    this.endDate,
    this.createdBy,
  });

  /// Kata kunci pencarian multi-kolom (nama, nomor plat, identitas,
  /// tujuan, keperluan, dll).
  final String? search;

  /// Jumlah rekor maksimal per halaman.
  final int? limit;

  /// Titik awal data untuk kebutuhan paginasi.
  final int? offset;

  /// Filter tanggal awal data tamu (ISO 8601).
  final String? startDate;

  /// Filter tanggal akhir data tamu (ISO 8601).
  final String? endDate;

  /// Filter berdasarkan email pembuat data tamu.
  final String? createdBy;

  /// Membangun map parameter query HTTP berformat snake_case sesuai
  /// kontrak backend `GetGuestsQueryDto`.
  Map<String, dynamic> toQueryParams() {
    return {
      if (search != null) 'search': search,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props =>
      [search, limit, offset, startDate, endDate, createdBy];
}
