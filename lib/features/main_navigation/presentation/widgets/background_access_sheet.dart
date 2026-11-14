import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/background_access_cubit.dart';

/// Asks once, right after login, for what keeps the PTT service alive in the
/// background, and can be reopened from "Akun". Android only; it never
/// navigates, so the auth flow stays with `AppRouter`.
class BackgroundAccessSheet extends StatelessWidget {
  const BackgroundAccessSheet({super.key});

  // A new `MainNavigationScreen` (switch group) must not ask again in the
  // same run when the sheet was closed with the system back button.
  static bool _shownThisRun = false;

  @visibleForTesting
  static void resetForTest() => _shownThisRun = false;

  static bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.android;

  /// The automatic prompt after login: only when something is still askable
  /// and the user has not chosen "Nanti saja".
  static Future<void> maybeShow(
    BuildContext context, {
    BackgroundAccessCubit Function()? createCubit,
  }) async {
    if (!isSupported || _shownThisRun) return;
    final cubit = (createCubit ?? BackgroundAccessCubit.new)();
    try {
      await cubit.load();
      if (!context.mounted || !cubit.state.shouldPrompt) return;
      _shownThisRun = true;
      await _present(context, cubit, dismissible: false);
    } finally {
      unawaited(cubit.close());
    }
  }

  /// Opened on request from "Akun", whatever the current state.
  static Future<void> show(
    BuildContext context, {
    BackgroundAccessCubit Function()? createCubit,
  }) async {
    if (!isSupported) return;
    final cubit = (createCubit ?? BackgroundAccessCubit.new)();
    try {
      await cubit.load();
      if (!context.mounted || cubit.state.status == null) return;
      await _present(context, cubit, dismissible: true);
    } finally {
      unawaited(cubit.close());
    }
  }

  static Future<void> _present(
    BuildContext context,
    BackgroundAccessCubit cubit, {
    required bool dismissible,
  }) => showAppBottomSheet<void>(
    context: context,
    barrierDismissible: dismissible,
    enableDrag: dismissible,
    child: BlocProvider.value(
      value: cubit,
      child: const BackgroundAccessSheet(),
    ),
  );

  static const Map<BackgroundAccessItem, (IconData, String, String)> _labels = {
    BackgroundAccessItem.notifications: (
      Icons.notifications_none_rounded,
      'Notifikasi',
      'Nama rekan yang bicara tampil di layar kunci',
    ),
    BackgroundAccessItem.microphone: (
      Icons.mic_none_rounded,
      'Mikrofon',
      'Untuk bicara lewat walkie-talkie',
    ),
    BackgroundAccessItem.battery: (
      Icons.battery_std_outlined,
      'Baterai',
      'Agar walkie-talkie tidak dimatikan sistem',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);

    return BlocBuilder<BackgroundAccessCubit, BackgroundAccessState>(
      builder: (context, state) {
        final grants = state.status?.grants ?? const {};
        final cubit = context.read<BackgroundAccessCubit>();
        return SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Agar walkie-talkie tetap aktif',
                  style: TextStyle(
                    color: tones.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Saat HP terkunci atau app ditutup, Anda tetap bisa '
                  'mendengar rekan.',
                  style: TextStyle(color: tones.ink2, fontSize: 15),
                ),
                const SizedBox(height: 12),
                for (final item in BackgroundAccessItem.values) ...[
                  _AccessRow(
                    icon: _labels[item]!.$1,
                    title: _labels[item]!.$2,
                    description: _labels[item]!.$3,
                    grant: grants[item] ?? BackgroundAccessGrant.refused,
                    onRequest: state.requesting
                        ? null
                        : () => unawaited(cubit.request(item)),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Izin yang ditolak dapat diubah nanti di Pengaturan Android.',
                  style: TextStyle(color: tones.ink2, fontSize: 13),
                ),
                const SizedBox(height: 12),
                AppTaskButton(
                  label: 'Lanjutkan',
                  size: AppTaskButtonSize.medium,
                  isLoading: state.requesting,
                  onPressed: () async {
                    await cubit.requestAll();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
                AppTaskButton(
                  label: 'Nanti saja',
                  size: AppTaskButtonSize.medium,
                  variant: AppTaskButtonVariant.secondary,
                  onPressed: state.requesting
                      ? null
                      : () async {
                          await cubit.skip();
                          if (context.mounted) Navigator.of(context).pop();
                        },
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
    required this.icon,
    required this.title,
    required this.description,
    required this.grant,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final BackgroundAccessGrant grant;
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final trailing = switch (grant) {
      BackgroundAccessGrant.granted => const AppStatusPill(
        label: 'Diizinkan',
        kind: AppStatusKind.ok,
      ),
      BackgroundAccessGrant.refused => const AppStatusPill(label: 'Ditolak'),
      BackgroundAccessGrant.askable => AppTaskButton(
        label: 'Izinkan',
        size: AppTaskButtonSize.small,
        semanticLabel: 'Izinkan $title',
        onPressed: onRequest,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tones.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tones.ptt.soft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: tones.ptt.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tones.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: tones.ink2, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
