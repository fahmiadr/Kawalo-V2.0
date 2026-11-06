import 'package:equatable/equatable.dart';

/// Model kontrak request query untuk endpoint REST API backend
/// `GET /v1/operational` sesuai skema `GetOperationalQueryDto`.
class OperationalQueryModel extends Equatable {
  /// Membuat instance [OperationalQueryModel].
  const OperationalQueryModel({
    this.search,
    this.limit,
    this.offset,
    this.startDate,
    this.endDate,
  });

  /// Kata kunci pencarian multi-kolom (nama, email, tugas, atau status).
  final String? search;

  /// Jumlah rekor maksimal per halaman.
  final int? limit;

  /// Titik awal data untuk kebutuhan paginasi.
  final int? offset;

  /// Filter tanggal awal catatan tugas operasional (ISO 8601).
  final String? startDate;

  /// Filter tanggal akhir catatan tugas operasional (ISO 8601).
  final String? endDate;

  /// Membangun map parameter query HTTP berformat snake_case sesuai
  /// kontrak backend `GetOperationalQueryDto`.
  Map<String, dynamic> toQueryParams() {
    return {
      if (search != null) 'search': search,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
  }

  @override
  List<Object?> get props => [search, limit, offset, startDate, endDate];
}
