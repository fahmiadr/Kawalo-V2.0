import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_text_link.dart';
import 'package:kawalo_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/group/presentation/screens/personnel_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/app_shortcut_card.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_screen.dart';
import 'package:kawalo_mobile/features/operational/presentation/screens/operational_screen.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/presentation/screens/schedule_screen.dart';

export 'package:kawalo_mobile/core/widgets/app_text_link.dart';
export 'package:kawalo_mobile/features/home/presentation/widgets/app_shortcut_card.dart';

/// Komponen bagian "Pintasan" pada Beranda yang memuat header
/// dan daftar kartu pintasan.
class HomeShortcutsSection extends StatelessWidget {
  /// Membuat instance [HomeShortcutsSection].
  const HomeShortcutsSection({super.key, this.shortcuts, this.onLogoutPressed});

  /// Daftar item pintasan kustom (opsional).
  final List<AppShortcutItem>? shortcuts;

  /// Callback saat aksi "Logout" ditekan (opsional).
  final VoidCallback? onLogoutPressed;

  static List<AppShortcutItem> _getDefaultShortcuts(
    BuildContext context, {
    VoidCallback? onLogoutPressed,
    int openIncidents = 0,
    String? scheduleSubtitle,
  }) {
    return [
      AppShortcutItem(
        title: 'Jadwal Kerja',
        subtitle: scheduleSubtitle,
        iconPath: KawaloColorVectors.calendar2,
        onTap: () {
          Navigator.of(context).push(ScheduleScreen.route());
        },
      ),
      AppShortcutItem(
        title: 'Data Tamu',
        iconPath: KawaloColorVectors.guestValidation,
        onTap: () {
          Navigator.of(context).push(GuestScreen.route());
        },
      ),
      AppShortcutItem(
        title: 'Data Absensi',
        subtitle: 'Check-in/Check-out',
        iconPath: KawaloColorVectors.checklist2,
        onTap: () {
          Navigator.of(context).push(AttendanceScreen.route());
        },
      ),
      AppShortcutItem(
        title: 'Aktifitas Operasional',
        iconPath: KawaloColorVectors.patrol2,
        onTap: () {
          Navigator.of(context).push(OperationalScreen.route());
        },
      ),
      AppShortcutItem(
        title: 'Insiden',
        subtitle: 'Laporan Kejadian',
        badgeText: openIncidents > 0 ? '$openIncidents aktif' : null,
        iconPath: KawaloColorVectors.incident1,
        onTap: () {
          Navigator.of(context).push(IncidentScreen.route());
        },
      ),
      AppShortcutItem(
        title: 'Personil',
        subtitle: 'Anggota Grup',
        iconPath: KawaloColorVectors.group1,
        onTap: () {
          Navigator.of(context).push(PersonnelScreen.route());
        },
      ),
      AppShortcutItem(
        title: 'Logout',
        subtitle: 'Keluar Akun',
        iconPath: KawaloColorVectors.logout,
        onTap:
            onLogoutPressed ??
            () async {
              final confirmed = await showAppConfirmationDialog(
                context: context,
                title: 'Keluar dari akun?',
                message:
                    'Sesi Anda akan berakhir. Anda perlu masuk kembali '
                    'untuk mengakses aplikasi.',
                confirmText: 'Keluar',
              );

              if ((confirmed ?? false) && context.mounted) {
                try {
                  context.read<AuthBloc>().add(const LogoutRequested());
                } on Object catch (_) {
                  unawaited(AppRouter.of(context).toLogin());
                }
              }
            },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final incidentState = context.watch<IncidentListCubit?>()?.state;
    final openIncidents =
        incidentState?.displayedIncidents.where((i) => i.isOpen).length ?? 0;
    final scheduleState = context.watch<ScheduleCubit?>()?.state;
    final items =
        shortcuts ??
        _getDefaultShortcuts(
          context,
          onLogoutPressed: onLogoutPressed,
          openIncidents: openIncidents,
          scheduleSubtitle: switch (scheduleState) {
            ScheduleLoaded(:final schedules) => nextShiftSubtitle(
              schedules,
              DateTime.now(),
            ),
            _ => null,
          },
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header Bagian Pintasan ─────────────────────────────────────────
        const AppTextLink(title: 'Pintasan'),

        AppSpacing.vGapSm,

        // ── Grid Pintasan Adaptif ──────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
            final textScaler = MediaQuery.textScalerOf(context);
            // Non-text fixed: padding vertikal 24 + icon 40 + gap 8 = 72dp
            // Text scalable: judul 24 + subtitle 16 + buffer = 50dp
            final mainAxisExtent = 76.0 + textScaler.scale(50);

            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.space150,
                mainAxisSpacing: AppSpacing.space200,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: (context, index) =>
                  AppShortcutCard(item: items[index]),
            );
          },
        ),
      ],
    );
  }
}
