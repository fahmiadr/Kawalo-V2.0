import 'package:equatable/equatable.dart';

/// Model kontrak request query untuk endpoint REST API backend
/// `GET /v1/information` sesuai skema `GetInformationQueryDto`.
class InformationQueryModel extends Equatable {
  /// Membuat instance [InformationQueryModel].
  const InformationQueryModel({
    this.search,
    this.limit,
    this.offset,
    this.startDate,
    this.endDate,
    this.createdBy,
  });

  /// Kata kunci pencarian multi-kolom (judul, deskripsi, pelapor, lokasi,
  /// atau tipe).
  final String? search;

  /// Jumlah rekor maksimal per halaman.
  final int? limit;

  /// Titik awal data untuk kebutuhan paginasi.
  final int? offset;

  /// Filter tanggal awal catatan informasi (ISO 8601).
  final String? startDate;

  /// Filter tanggal akhir catatan informasi (ISO 8601).
  final String? endDate;

  /// Filter berdasarkan email pembuat informasi.
  final String? createdBy;

  /// Membangun map parameter query HTTP berformat snake_case sesuai
  /// kontrak backend `GetInformationQueryDto`.
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
