import 'package:camera/camera.dart';
import 'package:kawalo_mobile/core/services/screen_brightness_service.dart';

/// Menyimpan status flash kamera (mode, dukungan LED fisik, tirai Screen
/// Flash) beserta logika murni siklus mode dan pemulihan kecerahan layar.
///
/// Kelas ini tidak memicu rebuild; pemanggil (State) membungkus mutasi dengan
/// `setState` agar urutan pembaruan UI tetap sama persis.
class CameraFlashController {
  CameraFlashController({required this.brightnessService});

  final ScreenBrightnessService brightnessService;

  FlashMode mode = FlashMode.off;
  bool hasPhysicalFlash = false;
  bool isScreenFlashActive = false;

  /// Kecerahan layar sebelum dinaikkan untuk Screen Flash; `null` bila tidak
  /// ada yang perlu dipulihkan.
  double? originalBrightness;

  /// Flash didukung jika kamera memiliki lampu LED fisik ATAU kamera depan
  /// yang mendukung tirai Screen Flash.
  bool isSupported({
    required bool cameraStateUnknown,
    required bool isCurrentCameraFront,
  }) {
    if (cameraStateUnknown) return true;
    return hasPhysicalFlash || isCurrentCameraFront;
  }

  /// Menguji apakah [controller] memiliki LED fisik dengan mencoba mengatur
  /// mode flash.
  Future<bool> checkPhysicalFlashSupport(CameraController controller) async {
    try {
      await controller.setFlashMode(FlashMode.auto);
      try {
        await controller.setFlashMode(FlashMode.off);
      } on Exception catch (_) {}
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Menormalkan [mode] berdasarkan ketersediaan hardware kamera aktif.
  void normalizeModeFor({required bool isFront}) {
    if (!isFront && !hasPhysicalFlash) {
      mode = FlashMode.off;
    } else if (isFront && !hasPhysicalFlash) {
      if (mode == FlashMode.torch || mode == FlashMode.auto) {
        mode = FlashMode.off;
      }
    }
  }

  /// Mode flash berikutnya dalam siklus tombol flash.
  ///
  /// Kamera depan tanpa LED fisik memakai siklus 2 mode untuk Screen Flash.
  /// Jika kamera memiliki LED fisik (depan/belakang), pakai siklus 4 mode.
  FlashMode nextMode({required bool isScreenFlashOnly}) {
    final order = isScreenFlashOnly
        ? const [FlashMode.off, FlashMode.always]
        : const [
            FlashMode.off,
            FlashMode.auto,
            FlashMode.always,
            FlashMode.torch,
          ];
    final currentIndex = order.indexOf(mode);
    final nextIndex = (currentIndex + 1) % order.length;
    return order[nextIndex];
  }

  Future<void> restoreBrightness() async {
    final original = originalBrightness;
    originalBrightness = null;
    if (original != null) {
      await brightnessService.setBrightness(original);
    } else {
      await brightnessService.resetBrightness();
    }
  }
}
