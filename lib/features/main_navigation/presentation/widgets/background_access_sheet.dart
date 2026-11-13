import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/background_access_cubit.dart';

/// Asks once, right after login, for what keeps the PTT service alive in the
/// background. Android only; it never navigates, so the auth flow stays with
/// `AppRouter`.
class BackgroundAccessSheet extends StatelessWidget {
  const BackgroundAccessSheet({super.key});

  // A new `MainNavigationScreen` (switch group) must not ask again in the
  // same run when the sheet was closed with the system back button.
  static bool _shownThisRun = false;

  @visibleForTesting
  static void resetForTest() => _shownThisRun = false;

  static Future<void> maybeShow(
    BuildContext context, {
    BackgroundAccessCubit Function()? createCubit,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android || _shownThisRun) {
      return;
    }
    final cubit = (createCubit ?? BackgroundAccessCubit.new)();
    try {
      await cubit.load();
      if (!context.mounted || !cubit.state.shouldPrompt) return;
      _shownThisRun = true;
      await showAppBottomSheet<void>(
        context: context,
        barrierDismissible: false,
        enableDrag: false,
        child: BlocProvider.value(
          value: cubit,
          child: const BackgroundAccessSheet(),
        ),
      );
    } finally {
      unawaited(cubit.close());
    }
  }

  static const Map<BackgroundAccessItem, (String, String)> _labels = {
    BackgroundAccessItem.notifications: (
      'Notifikasi',
      'Menampilkan siapa yang sedang bicara dan tombol Bicara di notifikasi.',
    ),
    BackgroundAccessItem.microphone: (
      'Mikrofon',
      'Untuk bicara lewat walkie-talkie.',
    ),
    BackgroundAccessItem.battery: (
      'Tanpa batasan baterai',
      'Agar Android tidak menghentikan Kawalo saat ponsel tidak dipakai.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<BackgroundAccessCubit, BackgroundAccessState>(
      builder: (context, state) {
        final grants = state.status?.grants ?? const {};
        final cubit = context.read<BackgroundAccessCubit>();
        return SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.space300,
              right: AppSpacing.space300,
              top: AppSpacing.space100,
              bottom: AppSpacing.space300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Agar Kawalo tetap aktif',
                  style: theme.typography.emphasized.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                AppSpacing.vGap50,
                Text(
                  'Walkie-talkie tetap menerima suara saat layar mati atau '
                  'aplikasi ditutup dari daftar aplikasi terbaru. Untuk itu '
                  'Kawalo butuh izin berikut.',
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGap200,
                for (final item in BackgroundAccessItem.values)
                  _AccessRow(
                    title: _labels[item]!.$1,
                    description: _labels[item]!.$2,
                    grant: grants[item] ?? BackgroundAccessGrant.refused,
                  ),
                AppSpacing.vGap100,
                Text(
                  'Izin yang ditolak dapat diubah nanti di Pengaturan Android.',
                  style: theme.typeScale.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGap300,
                AppButton(
                  size: AppButtonSize.md,
                  enabled: !state.requesting,
                  onPressed: () async {
                    await cubit.requestAll();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(state.requesting ? 'Meminta izin...' : 'Izinkan'),
                ),
                AppSpacing.vGap100,
                AppButton(
                  style: AppButtonColor.tonal,
                  size: AppButtonSize.md,
                  enabled: !state.requesting,
                  onPressed: () async {
                    await cubit.skip();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Lewati'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.title,
    required this.description,
    required this.grant,
  });

  final String title;
  final String description;
  final BackgroundAccessGrant grant;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final (icon, color, status) = switch (grant) {
      BackgroundAccessGrant.granted => (
        KawaloVectors.checkmarkCircle01Filled,
        colorScheme.primary,
        'Sudah diizinkan',
      ),
      BackgroundAccessGrant.askable => (
        KawaloVectors.radioButtonUnchecked,
        colorScheme.onSurfaceVariant,
        'Belum diizinkan',
      ),
      BackgroundAccessGrant.refused => (
        KawaloVectors.alertCircle,
        colorScheme.onSurfaceVariant,
        'Ditolak',
      ),
    };

    return Semantics(
      container: true,
      label: '$title, $status. $description',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSvgIcon(icon, size: 22, color: color),
            AppSpacing.hGap150,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.typography.emphasized.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.vGap25,
                  Text(
                    description,
                    style: theme.typeScale.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGap100,
            Text(
              status,
              style: theme.typeScale.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
