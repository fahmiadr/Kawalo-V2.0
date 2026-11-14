import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// `FACE_SERVICE_UNAVAILABLE`: the server has no face model yet, so neither
/// registration nor check-in/out can run. There is deliberately no way
/// around it.
Widget faceServiceUnavailableView({
  required VoidCallback onBack,
  String title = 'Absensi',
}) {
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
    title: title,
    neutral: true,
    onClose: onBack,
  );
}

/// Camera could not be opened. [onSecondary] defaults to going back.
Widget faceCameraFaultView({
  required FaceCameraFault fault,
  required VoidCallback onRetry,
  required VoidCallback onOpenSettings,
  required VoidCallback onBack,
  String title = 'Absensi',
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  final denied = fault == FaceCameraFault.permissionDenied;
  return faceErrorPage(
    AppActionableErrorData(
      icon: KawaloVectors.cameraOff01Filled,
      title: denied ? 'Izin kamera dibutuhkan' : 'Kamera depan tidak tersedia',
      message: denied
          ? 'Absen memakai wajah. Izinkan kamera di Pengaturan HP, lalu '
                'kembali dan ketuk Coba Lagi.'
          : 'Kamera tidak dapat dibuka. Tanpa kamera depan, check-in dan '
                'check-out tidak bisa dilakukan.',
      troubleshootingTips: denied
          ? const []
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
    title: title,
    neutral: denied,
    onClose: onBack,
  );
}

/// An actionable error as a task screen: top bar, explanation, then the
/// primary (Absensi tone) and secondary actions in the dock.
Widget faceErrorPage(
  AppActionableErrorData data, {
  String title = 'Absensi',
  bool neutral = false,
  VoidCallback? onClose,
}) => _FaceErrorPage(
  data: data,
  title: title,
  neutral: neutral,
  onClose: onClose,
);

class _FaceErrorPage extends StatelessWidget {
  const _FaceErrorPage({
    required this.data,
    required this.title,
    required this.neutral,
    this.onClose,
  });

  final AppActionableErrorData data;
  final String title;
  final bool neutral;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final icon = data.icon;
    final primary = data.primaryActionLabel;
    final onPrimary = data.onPrimaryAction;
    final secondary = data.secondaryActionLabel;
    final onSecondary = data.onSecondaryAction;
    return TaskScaffold(
      title: title,
      onClose: onClose,
      scrollable: false,
      body: TaskMessage(
        icon: data.customIcon ?? AppSvgIcon(icon ?? KawaloVectors.alertCircle),
        title: data.title,
        message: data.message,
        kind: neutral ? TaskMessageKind.neutral : TaskMessageKind.bad,
        below: [
          if (data.troubleshootingTips.isNotEmpty)
            TaskBox(
              soft: true,
              children: [
                for (final tip in data.troubleshootingTips)
                  Text(tip, style: TextStyle(color: tones.ink2, fontSize: 14)),
              ],
            ),
        ],
      ),
      footer: [
        if (primary != null && onPrimary != null)
          taskPrimary(primary, onPrimary, tone: tones.abs),
        if (secondary != null && onSecondary != null)
          taskSecondary(secondary, onSecondary),
      ],
    );
  }
}
