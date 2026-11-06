import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/create_incident_data.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';

/// Command Object untuk operasi pembuatan laporan insiden baru.
class CreateIncidentParams extends Equatable {
  /// Membuat instance [CreateIncidentParams].
  const CreateIncidentParams({
    required this.title,
    required this.groupId,
    required this.session,
    this.description,
    this.category,
    this.glat,
    this.glong,
    this.photos = const [],
    this.cancelToken,
  });

  /// Judul laporan insiden.
  final String title;

  /// ID grup tempat insiden dilaporkan.
  final String groupId;

  /// Deskripsi peristiwa insiden.
  final String? description;

  /// Kategori insiden.
  final IncidentCategory? category;

  /// Titik garis lintang GPS.
  final double? glat;

  /// Titik garis bujur GPS.
  final double? glong;

  /// Daftar URL foto bukti (maksimal 4).
  final List<String> photos;

  /// Sesi autentikasi aktif pengguna pembuat.
  final AuthSessionEntity? session;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Otorisasi domain didelegasikan langsung ke
  /// [IncidentEntity.canBeCreatedBySession].
  bool get isAuthorized => IncidentEntity.canBeCreatedBySession(session);

  /// Konversi ke Value Object repositori.
  CreateIncidentData toRepositoryData() {
    return CreateIncidentData(
      title: title,
      groupId: groupId,
      description: description,
      category: category,
      glat: glat,
      glong: glong,
      photos: photos,
      cancelToken: cancelToken,
    );
  }

  @override
  List<Object?> get props => [
        title,
        groupId,
        description,
        category,
        glat,
        glong,
        photos,
        session,
        cancelToken,
      ];
}
