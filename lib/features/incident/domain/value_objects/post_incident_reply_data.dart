import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Value object payload data untuk mengirimkan balasan/pesan pada thread
/// insiden.
///
/// Murni data transfer domain tanpa ketergantungan pada UI atau framework
/// transport.
class PostIncidentReplyData extends Equatable {
  /// Membuat instance [PostIncidentReplyData].
  const PostIncidentReplyData({
    required this.incidentId,
    required this.message,
    this.photos = const [],
    this.cancelToken,
  });

  /// ID insiden yang dibalas.
  final String incidentId;

  /// Pesan balasan teks.
  final String message;

  /// Daftar URL foto lampiran balasan (maksimal 2).
  final List<String> photos;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  @override
  List<Object?> get props => [incidentId, message, photos, cancelToken];
}
