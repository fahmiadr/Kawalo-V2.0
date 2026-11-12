import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_module.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_screen.dart';
import 'package:kawalo_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:kawalo_mobile/features/face/face_module.dart';
import 'package:kawalo_mobile/features/schedule/presentation/screens/schedule_screen.dart';

/// Komponen aksi cepat utama ("Absensi").
///
/// Menggunakan [AppButton] bertipe [AppButtonColor.elevated] dengan
/// bentuk stadium/pill dan ukuran proporsional sesuai desain Figma.
class HomeQuickActions extends StatelessWidget {
  /// Membuat instance [HomeQuickActions].
  const HomeQuickActions({super.key, this.onAbsensiPressed});

  /// Callback saat tombol "Absensi" ditekan.
  final VoidCallback? onAbsensiPressed;

  Future<void> _defaultOnAbsensi(BuildContext context) async {
    final navigator = Navigator.of(context);
    final exit = await navigator.push(
      AttendanceCheckScreen.route(
        module: context.read<AttendanceCheckModule>(),
        faceRepository: context.read<FaceModule>().repository,
      ),
    );
    switch (exit) {
      case AttendanceCheckExit.openAttendanceList:
        navigator.push(AttendanceScreen.route());
      case AttendanceCheckExit.openSchedule:
        navigator.push(ScheduleScreen.route());
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _QuickActionButton(
      iconPath: KawaloColorVectors.phoneLocation1,
      label: 'Absensi',
      semanticLabel: 'Absensi',
      onPressed:
          onAbsensiPressed ?? () => unawaited(_defaultOnAbsensi(context)),
    );
  }
}

/// Tombol individual aksi cepat menggunakan [AppButton] elevated.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.iconPath,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String iconPath;
  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final emphasizedTypeScale = AppTheme.emphasizedTypeScaleOf(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: AppButton(
        style: AppButtonColor.elevated,
        size: AppButtonSize.custom(height: 72, hPadding: AppSpacing.space200),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon.color(iconPath, size: 40),
            AppSpacing.hGapSm,
            Flexible(
              child: Text(
                label,
                style: emphasizedTypeScale.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
