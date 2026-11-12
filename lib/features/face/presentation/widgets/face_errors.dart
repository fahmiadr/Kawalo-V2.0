import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';

/// `FACE_SERVICE_UNAVAILABLE`: the server has no face model yet, so neither
/// registration nor check-in/out can run. There is deliberately no way
/// around it.
Widget faceServiceUnavailableView({required VoidCallback onBack}) {
  return faceErrorPage(
    AppActionableErrorData(
      icon: KawaloVectors.userShield01,
      title: 'Layanan wajah belum tersedia',
      message:
          'Verifikasi wajah belum aktif di server, jadi pendaftaran wajah, '
          'check-in, dan check-out belum bisa dilakukan. Hubungi admin grup '
          'Anda.',
      primaryActionLabel: 'Kembali',
      onPrimaryAction: onBack,
    ),
  );
}

/// Camera could not be opened. [onSecondary] defaults to going back.
Widget faceCameraFaultView({
  required FaceCameraFault fault,
  required VoidCallback onRetry,
  required VoidCallback onOpenSettings,
  required VoidCallback onBack,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  final denied = fault == FaceCameraFault.permissionDenied;
  return faceErrorPage(
    AppActionableErrorData(
      icon: KawaloVectors.cameraOff01Filled,
      title: denied ? 'Izin kamera ditolak' : 'Kamera depan tidak tersedia',
      message: denied
          ? 'Kawalo memerlukan kamera depan untuk verifikasi wajah. Aktifkan '
                'izin kamera lewat pengaturan.'
          : 'Kamera tidak dapat dibuka. Tanpa kamera depan, check-in dan '
                'check-out tidak bisa dilakukan.',
      troubleshootingTips: denied
          ? const [
              'Buka Pengaturan aplikasi Kawalo.',
              'Pilih Izin, lalu Kamera.',
              'Pilih "Izinkan", lalu kembali dan ketuk Coba Lagi.',
            ]
          : const [
              'Tutup aplikasi lain yang memakai kamera.',
              'Mulai ulang aplikasi lalu coba lagi.',
            ],
      primaryActionLabel: denied ? 'Buka Pengaturan' : 'Coba Lagi',
      onPrimaryAction: denied ? onOpenSettings : onRetry,
      secondaryActionLabel: denied
          ? 'Coba Lagi'
          : (secondaryLabel ?? 'Kembali'),
      onSecondaryAction: denied ? onRetry : (onSecondary ?? onBack),
    ),
  );
}

/// An actionable error as a whole page.
Widget faceErrorPage(AppActionableErrorData data) => Scaffold(
  body: SafeArea(child: AppActionableError.view(data: data)),
);
