import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/features/guest/presentation/qr_scan/guest_qr_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// [GuestQrScanner] backed by the `mobile_scanner` plugin.
class MobileScannerGuestQrScanner implements GuestQrScanner {
  MobileScannerGuestQrScanner()
    : _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        // The cubit applies its own debounce; plugin-side suppression would
        // also hide a legitimate re-scan after "Pindai lagi".
        detectionSpeed: DetectionSpeed.unrestricted,
      );

  final MobileScannerController _controller;

  @override
  Stream<String> get codes => _controller.barcodes.expand(
    (capture) =>
        capture.barcodes.map((barcode) => barcode.rawValue).whereType<String>(),
  );

  @override
  GuestQrTorch get torch => switch (_controller.value.torchState) {
    TorchState.on => GuestQrTorch.on,
    TorchState.off => GuestQrTorch.off,
    TorchState.auto || TorchState.unavailable => GuestQrTorch.unavailable,
  };

  @override
  GuestQrScannerFault? get fault {
    final error = _controller.value.error;
    if (error == null) return null;
    return error.errorCode == MobileScannerErrorCode.permissionDenied
        ? GuestQrScannerFault.permissionDenied
        : GuestQrScannerFault.unavailable;
  }

  @override
  Listenable get changes => _controller;

  @override
  Future<void> toggleTorch() => _controller.toggleTorch();

  @override
  Future<void> restart() async {
    await _controller.stop();
    await _controller.start();
  }

  @override
  Widget buildPreview(BuildContext context) => MobileScanner(
    controller: _controller,
    errorBuilder: (_, _) => const SizedBox.shrink(),
  );

  @override
  Future<void> dispose() async {
    unawaited(_controller.dispose());
  }
}
