import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Repository payload to confirm a guest visit
/// (`PATCH /guests/:id/acknowledge`).
class AcknowledgeGuestData extends Equatable {
  /// Creates an [AcknowledgeGuestData].
  const AcknowledgeGuestData({required this.id, this.qrUid, this.cancelToken});

  /// Guest identifier.
  final String id;

  /// Optional guest QR code; the API prefers it over [id] when present.
  final String? qrUid;

  /// Cancels the in-flight request.
  final AppCancellationToken? cancelToken;

  @override
  List<Object?> get props => [id, qrUid, cancelToken];
}
