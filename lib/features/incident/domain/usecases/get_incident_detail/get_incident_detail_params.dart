import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';

/// Parameter input untuk usecase pengambilan detail insiden beserta balasan
/// thread.
class GetIncidentDetailParams extends Equatable {
  /// Membuat instance [GetIncidentDetailParams].
  const GetIncidentDetailParams({
    required this.incidentId,
    required this.session,
    this.cancelToken,
  });

  /// ID insiden yang ingin diambil detailnya.
  final String incidentId;

  /// Sesi autentikasi aktif pengguna.
  final AuthSessionEntity? session;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Verifikasi sesi: pengguna harus terautentikasi.
  bool get isAuthorized => session != null;

  @override
  List<Object?> get props => [
        incidentId,
        session,
        cancelToken,
      ];
}
