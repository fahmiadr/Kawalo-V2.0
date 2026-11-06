import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/post_incident_reply_data.dart';

/// Command Object untuk mengirimkan balasan pesan atau foto pada thread
/// insiden.
class PostIncidentReplyParams extends Equatable {
  /// Membuat instance [PostIncidentReplyParams].
  const PostIncidentReplyParams({
    required this.incident,
    required this.message,
    required this.session,
    this.photos = const [],
    this.cancelToken,
  });

  /// Entitas insiden yang sedang aktif.
  final IncidentEntity incident;

  /// Pesan teks yang dikirimkan.
  final String message;

  /// Daftar URL foto bukti yang dilampirkan (maksimal 2).
  final List<String> photos;

  /// Sesi autentikasi aktif pengguna pengirim.
  final AuthSessionEntity? session;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Otorisasi didelegasikan langsung ke [IncidentEntity.canReplyBySession].
  bool get isAuthorized => incident.canReplyBySession(session);

  /// Konversi ke Value Object repositori.
  PostIncidentReplyData toRepositoryData() {
    return PostIncidentReplyData(
      incidentId: incident.id,
      message: message,
      photos: photos,
      cancelToken: cancelToken,
    );
  }

  @override
  List<Object?> get props => [
        incident,
        message,
        photos,
        session,
        cancelToken,
      ];
}
