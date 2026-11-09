import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';

/// Command Object untuk menghapus insiden secara administratif (soft delete).
class DeleteIncidentParams extends Equatable {
  /// Membuat instance [DeleteIncidentParams].
  const DeleteIncidentParams({
    required this.incident,
    required this.session,
    this.cancelToken,
  });

  /// Entitas insiden yang ingin dihapus.
  final IncidentEntity incident;

  /// Sesi autentikasi aktif administrator yang menghapus.
  final AuthSessionEntity? session;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Otorisasi didelegasikan ke [IncidentEntity.canBeDeletedBySession].
  bool get isAuthorized => incident.canBeDeletedBySession(session);

  @override
  List<Object?> get props => [incident, session, cancelToken];
}
