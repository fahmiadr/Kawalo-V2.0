import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_management_section.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_ptt_floating_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_recent_guests_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_shortcuts_section.dart';

/// Konten tampilan dashboard utama pada tab Beranda.
///
/// Disusun secara modular, scrollable, dan adaptif mengikuti sistem
/// grid Material 3 Expressive.
class HomeDashboardView extends StatelessWidget {
  /// Membuat instance [HomeDashboardView].
  const HomeDashboardView({
    super.key,
    this.guestPages,
    this.shortcuts,
    this.managementItems,
    this.onRefresh,
    this.onAbsensiPressed,
    this.onCheckpointPressed,
    this.onEditShortcutsPressed,
    this.onEditManagementPressed,
    this.onLogoutPressed,
  });

  /// Data kustom halaman tamu terakhir (opsional).
  final List<List<RecentGuestItem>>? guestPages;

  /// Data kustom daftar pintasan (opsional).
  final List<AppShortcutItem>? shortcuts;

  /// Data kustom daftar modul manajemen (opsional).
  final List<AppShortcutItem>? managementItems;

  /// Callback ketika user melakukan swipe pull-to-refresh.
  final Future<void> Function()? onRefresh;

  /// Callback saat tombol "Absensi" ditekan.
  final VoidCallback? onAbsensiPressed;

  /// Callback saat tombol "Post to Post Checkpoint" ditekan.
  final VoidCallback? onCheckpointPressed;

  /// Callback saat tombol "Edit" pintasan ditekan.
  final VoidCallback? onEditShortcutsPressed;

  /// Callback saat tombol "Edit" manajemen ditekan.
  final VoidCallback? onEditManagementPressed;

  /// Callback saat aksi "Logout" ditekan (opsional).
  final VoidCallback? onLogoutPressed;

  Future<void> _defaultOnRefresh(BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (context.mounted) {
      AppSnackbar.show(
        context,
        message: 'Data beranda berhasil diperbarui.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator.contained(
      semanticsLabel: 'Memuat ulang data beranda',
      onRefresh: onRefresh ?? () => _defaultOnRefresh(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space200,
          vertical: AppSpacing.space150,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Bagian 1: Kartu Tamu Terakhir (Carousel) ───
                HomeRecentGuestsCard(
                  guestPages: guestPages,
                  onTapItem: (item) {
                    AppSnackbar.show(
                      context,
                      message: 'Detail tamu: ${item.identifier} '
                          '(${item.location})',
                    );
                  },
                ),

                AppSpacing.vGap200,

                // ── Bagian 2: Tombol Aksi Utama ─────────────────
                HomeQuickActions(
                  onAbsensiPressed: onAbsensiPressed,
                  onCheckpointPressed: onCheckpointPressed,
                ),

                AppSpacing.vGap300,

                // ── Bagian PTT: Walkie-Talkie Taktis ───────────
                const HomePttFloatingCard(),

                AppSpacing.vGap300,

                // ── Bagian 3: Bagian Pintasan (Shortcuts) ────────
                HomeShortcutsSection(
                  shortcuts: shortcuts,
                  onEditPressed: onEditShortcutsPressed,
                  onLogoutPressed: onLogoutPressed,
                ),

                AppSpacing.vGap300,

                // ── Bagian 4: Bagian Manajemen ───────────────────
                HomeManagementSection(
                  items: managementItems,
                  onEditPressed: onEditManagementPressed,
                ),

                // Spacing bawah ekstra agar konten tidak tertutup
                // FAB / Bottom Nav.
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
