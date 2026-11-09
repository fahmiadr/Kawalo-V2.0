import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';

/// Parameter input untuk usecase berlangganan stream SSE balasan thread
/// insiden.
class WatchIncidentRepliesParams extends Equatable {
  /// Membuat instance [WatchIncidentRepliesParams].
  const WatchIncidentRepliesParams({
    required this.incidentId,
    required this.session,
    this.lastEventId,
    this.cancelToken,
  });

  /// ID insiden yang dipantau secara real-time.
  final String incidentId;

  /// Sesi autentikasi aktif pengguna.
  final AuthSessionEntity? session;

  /// ID event terakhir yang berhasil diterima (untuk pemulihan pesan
  /// tertinggal).
  final String? lastEventId;

  /// Token pembatalan stream saat layar ditutup atau backgrounded (opsional).
  final AppCancellationToken? cancelToken;

  /// Verifikasi sesi: pengguna harus terautentikasi.
  bool get isAuthorized => session != null;

  @override
  List<Object?> get props => [incidentId, session, lastEventId, cancelToken];
}
