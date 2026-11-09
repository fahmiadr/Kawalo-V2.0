import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';

/// Mengelola mode imersif layar kamera: menyembunyikan status bar, mengunci
/// orientasi UI ke portrait, dan memulihkan semuanya saat layar ditutup.
class CameraSystemUiController {
  static const Duration autoHideDelay = Duration(milliseconds: 1500);

  /// Menjadi `true` setelah [restore] dijalankan; [restore] hanya berlaku
  /// sekali.
  bool hasRestored = false;

  Timer? _autoHideTimer;

  void hideStatusBar() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom],
      ),
    );
  }

  /// Mengaktifkan mode imersif dan menyembunyikan ulang status bar
  /// [autoHideDelay] setelah sistem memunculkannya.
  void setup({required bool Function() isMounted}) {
    hideStatusBar();
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (!isMounted() || hasRestored) return;
      if (systemOverlaysAreVisible) {
        _autoHideTimer?.cancel();
        _autoHideTimer = Timer(autoHideDelay, () {
          if (!isMounted() || hasRestored) return;
          hideStatusBar();
        });
      }
    });
  }

  /// Memulihkan UI sistem; pemanggilan berikutnya diabaikan.
  ///
  /// [unlockCaptureOrientation] dan [restoreBrightness] dipanggil pada titik
  /// yang sama dengan urutan pemulihan semula.
  void restore({
    required void Function() unlockCaptureOrientation,
    required Future<void> Function() restoreBrightness,
  }) {
    if (hasRestored) return;
    hasRestored = true;
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
    try {
      unlockCaptureOrientation();
    } on Object catch (_) {}
    SystemChrome.setSystemUIChangeCallback(null);
    unawaited(AppLayout.applyPreferredOrientations());
    unawaited(restoreBrightness());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }
}
