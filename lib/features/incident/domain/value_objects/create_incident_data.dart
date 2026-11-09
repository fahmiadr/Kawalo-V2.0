import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';

/// Value object payload data untuk membuat insiden baru pada repositori.
///
/// Murni data transfer domain tanpa ketergantungan pada UI atau framework
/// transport.
class CreateIncidentData extends Equatable {
  /// Membuat instance [CreateIncidentData].
  const CreateIncidentData({
    required this.title,
    required this.groupId,
    this.description,
    this.category,
    this.glat,
    this.glong,
    this.photos = const [],
    this.cancelToken,
  });

  /// Judul insiden (wajib).
  final String title;

  /// ID grup tempat insiden dilaporkan (wajib).
  final String groupId;

  /// Penjelasan detail insiden (opsional).
  final String? description;

  /// Kategori klasifikasi insiden (opsional).
  final IncidentCategory? category;

  /// Titik garis lintang GPS lokasi insiden (opsional).
  final double? glat;

  /// Titik garis bujur GPS lokasi insiden (opsional).
  final double? glong;

  /// Daftar URL foto bukti insiden (maksimal 4).
  final List<String> photos;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  @override
  List<Object?> get props => [
    title,
    groupId,
    description,
    category,
    glat,
    glong,
    photos,
    cancelToken,
  ];
}
