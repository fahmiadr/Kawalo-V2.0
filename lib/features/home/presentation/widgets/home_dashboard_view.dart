import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_management_section.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_ptt_floating_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_recent_guests_section.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_shortcuts_section.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';

/// Konten tampilan dashboard utama pada tab Beranda.
///
/// Disusun secara modular, scrollable, dan adaptif mengikuti sistem
/// grid Material 3 Expressive. Memuat data tamu dan insiden dari cubit global
/// saat pertama tampil, dan menyegarkannya lewat pull-to-refresh.
class HomeDashboardView extends StatefulWidget {
  /// Membuat instance [HomeDashboardView].
  const HomeDashboardView({
    super.key,
    this.shortcuts,
    this.managementItems,
    this.onRefresh,
    this.onAbsensiPressed,
    this.onCheckpointPressed,
    this.onEditShortcutsPressed,
    this.onEditManagementPressed,
    this.onLogoutPressed,
  });

  /// Data kustom daftar pintasan (opsional).
  final List<AppShortcutItem>? shortcuts;

  /// Data kustom daftar modul manajemen (opsional).
  final List<AppShortcutItem>? managementItems;

  /// Menggantikan refresh bawaan (guest + insiden) bila diberikan.
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

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadInitial());
    });
  }

  Future<void> _loadInitial() async {
    final guestCubit = context.read<GuestCubit?>();
    final incidentCubit = context.read<IncidentListCubit?>();
    final scheduleCubit = context.read<ScheduleCubit?>();
    final session = context.read<UserSessionCubit?>()?.state;
    await Future.wait([
      // Always reloaded: the schedule is personal and per group, so a state
      // left by a previous session or group must not be shown.
      if (scheduleCubit != null) scheduleCubit.fetch(),
      if (guestCubit != null && guestCubit.state is GuestInitial)
        guestCubit.fetchGuests(),
      if (incidentCubit != null && incidentCubit.state is IncidentInitial)
        incidentCubit.fetchIncidents(session: session),
    ]);
  }

  /// Refreshes both lists back to their default (today) view. The cubits are
  /// shared with the guest/incident screens, so a filter set there must not
  /// leak into the Beranda summary.
  Future<void> _refresh() async {
    final guestCubit = context.read<GuestCubit?>();
    final incidentCubit = context.read<IncidentListCubit?>();
    final scheduleCubit = context.read<ScheduleCubit?>();
    final session = context.read<UserSessionCubit?>()?.state;
    final filter = AppDateFilterResult.defaultFilter();

    final results = await Future.wait([
      if (scheduleCubit != null)
        scheduleCubit
            .fetch(silent: true)
            .then((ok) => ok ? AppFetchResult.success : AppFetchResult.failure),
      if (guestCubit != null)
        guestCubit.refreshGuests(
          search: '',
          filterPeriod: filter.period,
          startDate: filter.startDate,
          endDate: filter.endDate,
          startDateIso: filter.startDateIso,
          endDateIso: filter.endDateIso,
          clearCreatorFilter: true,
        ),
      if (incidentCubit != null)
        incidentCubit.refreshIncidents(
          session: session,
          search: '',
          clearStatusFilter: true,
          filterPeriod: filter.period,
          startDate: filter.startDate,
          endDate: filter.endDate,
          startDateIso: filter.startDateIso,
          endDateIso: filter.endDateIso,
        ),
    ]);
    if (!mounted) return;

    if (results.contains(AppFetchResult.failure)) {
      AppSnackbar.show(context, message: 'Gagal memperbarui data beranda.');
    } else if (results.contains(AppFetchResult.cachedFallback)) {
      AppFetchFeedback.show(
        context,
        result: AppFetchResult.cachedFallback,
        hasData: guestCubit?.state.displayedGuests.isNotEmpty ?? false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator.contained(
      semanticsLabel: 'Memuat ulang data beranda',
      onRefresh: widget.onRefresh ?? _refresh,
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
                const HomeRecentGuestsSection(),

                AppSpacing.vGap200,

                // ── Bagian 2: Tombol Aksi Utama ─────────────────
                HomeQuickActions(
                  onAbsensiPressed: widget.onAbsensiPressed,
                  onCheckpointPressed: widget.onCheckpointPressed,
                ),

                AppSpacing.vGap300,

                // ── Bagian PTT: Walkie-Talkie Taktis ───────────
                const HomePttFloatingCard(),

                AppSpacing.vGap300,

                // ── Bagian 3: Bagian Pintasan (Shortcuts) ────────
                HomeShortcutsSection(
                  shortcuts: widget.shortcuts,
                  onEditPressed: widget.onEditShortcutsPressed,
                  onLogoutPressed: widget.onLogoutPressed,
                ),

                AppSpacing.vGap300,

                // ── Bagian 4: Bagian Manajemen ───────────────────
                HomeManagementSection(
                  items: widget.managementItems,
                  onEditPressed: widget.onEditManagementPressed,
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
