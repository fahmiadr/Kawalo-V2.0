import 'package:equatable/equatable.dart';

/// Pure DTO model untuk parameter query HTTP GET `/v1/incidents`.
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class IncidentQueryModel extends Equatable {
  /// Membuat instance [IncidentQueryModel].
  const IncidentQueryModel({
    this.groupId,
    this.status,
    this.search,
    this.startDate,
    this.endDate,
    this.limit,
    this.offset,
  });

  /// ID grup aktif (opsional, tidak dikirimkan ke query URL).
  final String? groupId;

  /// Filter status siklus hidup insiden ('OPEN', 'RESOLVED').
  final String? status;

  /// Kata kunci pencarian judul atau deskripsi insiden.
  final String? search;

  /// Filter tanggal awal (ISO 8601).
  final String? startDate;

  /// Filter tanggal akhir (ISO 8601).
  final String? endDate;

  /// Jumlah data per halaman.
  final int? limit;

  /// Titik awal data untuk kebutuhan paginasi (infinite scroll).
  final int? offset;

  /// Mengonversi parameter ke Map query parameters URL.
  Map<String, dynamic> toQueryParams() {
    return {
      if (status != null && status!.isNotEmpty) 'status': status,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (startDate != null && startDate!.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate!.isNotEmpty) 'end_date': endDate,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
  }

  @override
  List<Object?> get props => [
    groupId,
    status,
    search,
    startDate,
    endDate,
    limit,
    offset,
  ];
}
