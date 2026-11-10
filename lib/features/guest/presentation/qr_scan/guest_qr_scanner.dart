import 'package:flutter/widgets.dart';

/// Camera problems the scan screen can explain to the user.
enum GuestQrScannerFault {
  /// The user refused (or revoked) the camera permission. The platform does
  /// not tell "denied" from "permanently denied", so the UI always offers the
  /// app settings next to a retry.
  permissionDenied,

  /// No usable camera, or the camera failed to start.
  unavailable,
}

enum GuestQrTorch { unavailable, off, on }

/// Seam between the scan flow and the camera plugin so tests never open a
/// camera. One instance owns one camera session.
abstract interface class GuestQrScanner {
  /// Raw text of every QR code seen by the camera. Duplicates are expected;
  /// the cubit decides what to ignore.
  Stream<String> get codes;

  GuestQrTorch get torch;

  /// Current camera problem, if any.
  GuestQrScannerFault? get fault;

  /// Notifies when [torch] or [fault] changes.
  Listenable get changes;

  Future<void> toggleTorch();

  /// Restarts the camera after a [GuestQrScannerFault], re-asking permission
  /// where the platform allows it.
  Future<void> restart();

  /// Camera preview; blank while [fault] is set.
  Widget buildPreview(BuildContext context);

  Future<void> dispose();
}
