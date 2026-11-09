import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_text_link.dart';
import 'package:kawalo_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/app_shortcut_card.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_screen.dart';
import 'package:kawalo_mobile/features/operational/presentation/screens/operational_screen.dart';

export 'package:kawalo_mobile/core/widgets/app_text_link.dart';
export 'package:kawalo_mobile/features/home/presentation/widgets/app_shortcut_card.dart';

/// Komponen bagian "Pintasan" pada Beranda yang memuat header
/// dan daftar kartu pintasan.
class HomeShortcutsSection extends StatelessWidget {
  /// Membuat instance [HomeShortcutsSection].
  const HomeShortcutsSection({
    super.key,
    this.shortcuts,
    this.onEditPressed,
    this.onAddPressed,
    this.onLogoutPressed,
    this.showAddCard = true,
  });

  /// Daftar item pintasan kustom (opsional).
  final List<AppShortcutItem>? shortcuts;

  /// Callback saat tombol "Edit" ditekan.
  final VoidCallback? onEditPressed;

  /// Callback saat kartu "Tambah Pintasan" ditekan.
  final VoidCallback? onAddPressed;

  /// Callback saat aksi "Logout" ditekan (opsional).
  final VoidCallback? onLogoutPressed;

  /// Menentukan apakah kartu "Tambah Pintasan" ditampilkan di akhir grid.
  final bool showAddCard;

  static List<AppShortcutItem> _getDefaultShortcuts(
    BuildContext context, {
    VoidCallback? onLogoutPressed,
  }) {
    return [
      AppShortcutItem(
        title: 'Jadwal Kerja',
        subtitle: 'Masuk 30 Jun 2026 08:00',
        iconPath: KawaloColorVectors.calendar2,
        onTap: () {
          AppSnackbar.show(
            context,
            message: 'Membuka Jadwal Kerja...',
          );
        },
      ),
      AppShortcutItem(
        title: 'Data Tamu',
        iconPath: KawaloColorVectors.guestValidation,
        onTap: () {
          Navigator.of(context).push(
            AppPageRoute.slideFade<void>(
              builder: (_) => const GuestScreen(),
            ),
          );
        },
      ),
      AppShortcutItem(
        title: 'Data Absensi',
        subtitle: 'Check-in/Check-out',
        iconPath: KawaloColorVectors.checklist2,
        onTap: () {
          Navigator.of(context).push(
            AppPageRoute.slideFade<void>(
              builder: (_) => const AttendanceScreen(),
            ),
          );
        },
      ),
      AppShortcutItem(
        title: 'Data Patroli',
        subtitle: 'Post Checkpoint',
        iconPath: KawaloColorVectors.location2,
        onTap: () {
          AppSnackbar.show(
            context,
            message: 'Membuka Data Patroli...',
          );
        },
      ),
      AppShortcutItem(
        title: 'Aktifitas Operasional',
        iconPath: KawaloColorVectors.patrol2,
        onTap: () {
          Navigator.of(context).push(
            AppPageRoute.slideFade<void>(
              builder: (_) => const OperationalScreen(),
            ),
          );
        },
      ),
      AppShortcutItem(
        title: 'Insiden',
        subtitle: 'Laporan Kejadian',
        badgeText: 'BARU!',
        iconPath: KawaloColorVectors.incident1,
        onTap: () {
          Navigator.of(context).push(IncidentScreen.route());
        },
      ),
      AppShortcutItem(
        title: 'Logout',
        subtitle: 'Keluar Akun',
        iconPath: KawaloColorVectors.logout,
        onTap: onLogoutPressed ??
            () async {
              final confirmed = await showAppConfirmationDialog(
                context: context,
                title: 'Keluar dari akun?',
                message: 'Sesi Anda akan berakhir. Anda perlu masuk kembali '
                    'untuk mengakses aplikasi.',
                confirmText: 'Keluar',
              );

              if ((confirmed ?? false) && context.mounted) {
                try {
                  context.read<AuthBloc>().add(const LogoutRequested());
                } on Object catch (_) {
                  Navigator.of(context).pushAndRemoveUntil<void>(
                    AppPageRoute.fade<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = shortcuts ??
        _getDefaultShortcuts(
          context,
          onLogoutPressed: onLogoutPressed,
        );
    final totalCount = showAddCard ? items.length + 1 : items.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header Bagian Pintasan ─────────────────────────────────────────
        AppTextLink(
          title: 'Pintasan',
          linkText: 'Edit',
          semanticLabel: 'Edit susunan pintasan',
          onPressed: onEditPressed ??
              () {
                AppSnackbar.show(
                  context,
                  message: 'Fitur pengaturan pintasan segera hadir.',
                );
              },
        ),

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
              itemCount: totalCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.space150,
                mainAxisSpacing: AppSpacing.space200,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: (context, index) {
                if (index < items.length) {
                  return AppShortcutCard(item: items[index]);
                }
                return AppAddShortcutCard(
                  onPressed: onAddPressed ??
                      () {
                        AppSnackbar.show(
                          context,
                          message: 'Fitur Tambah Pintasan segera hadir.',
                        );
                      },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
