import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

sealed class GuestQrScanState extends Equatable {
  const GuestQrScanState();

  @override
  List<Object?> get props => const [];
}

/// Camera is live and waiting for a code.
final class GuestQrScanning extends GuestQrScanState {
  const GuestQrScanning();
}

/// A QR was read but its text cannot be a guest `qr_uid`.
final class GuestQrInvalid extends GuestQrScanState {
  const GuestQrInvalid();
}

final class GuestQrResolving extends GuestQrScanState {
  const GuestQrResolving(this.identifier);

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

final class GuestQrResolved extends GuestQrScanState {
  const GuestQrResolved(this.item);

  final GuestItemEntity item;

  @override
  List<Object?> get props => [item];
}

/// The API answers 404 both for unknown codes and for guests of another
/// group, so the two cannot be told apart.
final class GuestQrNotFound extends GuestQrScanState {
  const GuestQrNotFound(this.identifier);

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

final class GuestQrForbidden extends GuestQrScanState {
  const GuestQrForbidden(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Network or server problem; `GuestQrScanCubit.retry` repeats the lookup.
final class GuestQrFailed extends GuestQrScanState {
  const GuestQrFailed(this.identifier, this.message);

  final String identifier;
  final String message;

  @override
  List<Object?> get props => [identifier, message];
}
