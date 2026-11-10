import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

/// Request model of `AcknowledgeGuestUseCase`.
class AcknowledgeGuestParams extends Equatable {
  /// Creates an [AcknowledgeGuestParams].
  const AcknowledgeGuestParams({
    required this.id,
    required this.session,
    required this.item,
    this.qrUid,
    this.cancelToken,
  });

  /// Identifier of the guest to confirm.
  final String id;

  /// Session of the user confirming the visit.
  final AuthSessionEntity? session;

  /// Target guest, used for the authorization and state checks.
  final GuestItemEntity? item;

  /// Optional guest QR code.
  final String? qrUid;

  /// Cancels the in-flight request.
  final AppCancellationToken? cancelToken;

  static final RegExp _idRegex = RegExp(r'^[a-zA-Z0-9_-]+$');

  /// Whether [id] has a format the API accepts.
  bool get isValidId => id.isNotEmpty && _idRegex.hasMatch(id);

  /// Whether [session] may confirm [item] (see
  /// [GuestItemEntity.canBeAcknowledgedBySession]).
  bool get isAuthorized {
    final target = item;
    if (target == null || target.id != id) return false;
    return target.canBeAcknowledgedBySession(session);
  }

  @override
  List<Object?> get props => [id, session, item, qrUid, cancelToken];
}
