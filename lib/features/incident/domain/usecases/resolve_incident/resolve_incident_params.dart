import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';

/// Command Object untuk menyelesaikan insiden dan mengunci thread diskusi.
class ResolveIncidentParams extends Equatable {
  /// Membuat instance [ResolveIncidentParams].
  const ResolveIncidentParams({
    required this.incident,
    required this.session,
    this.cancelToken,
  });

  /// Entitas insiden yang ingin diselesaikan.
  final IncidentEntity incident;

  /// Sesi autentikasi aktif pengguna yang menyelesaikan.
  final AuthSessionEntity? session;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Otorisasi didelegasikan ke [IncidentEntity.canBeResolvedBySession].
  bool get isAuthorized => incident.canBeResolvedBySession(session);

  @override
  List<Object?> get props => [incident, session, cancelToken];
}
