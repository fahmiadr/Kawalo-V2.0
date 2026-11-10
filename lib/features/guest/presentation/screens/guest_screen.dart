import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_batch_delete.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_filter_bar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_scaffold.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_selection_controller.dart';
import 'package:kawalo_mobile/features/group/presentation/group_member_filter_options.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/qr_scan/guest_qr_scanner.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_detail_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_qr_scan_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_card.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_card_skeleton.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form_dialog.dart';

/// Layar utama fitur Data Tamu.
///
/// Mengambil data dari REST API (cache lokal saat offline) dengan isolasi
/// data grup aktif multi-tenant.
///
/// Fitur:
/// - Menggunakan [AppSelectionAppBar] dengan mode seleksi kontekstual
///   M3 Expressive.
/// - Terintegrasi dengan [GuestCubit] untuk unidirectional data flow.
/// - Shimmer skeleton saat memuat data awal.
/// - Infinite scroll dengan indikator muat halaman uncontained.
/// - Bottom sheet filter waktu dengan dot badge indikator aktif.
/// - Multi-selection & batch delete dengan otorisasi berbasis peran (ABAC/RBAC).
/// - Extended FAB "Tambah tamu" untuk pembuatan data tamu baru.
class GuestScreen extends StatefulWidget {
  /// Membuat instance [GuestScreen].
  const GuestScreen({super.key, this.cubit, this.qrScannerFactory});

  /// Instance [GuestCubit] opsional untuk injeksi pengujian.
  final GuestCubit? cubit;

  /// Camera factory of the QR scanner; replaced by a fake in tests.
  final GuestQrScanner Function()? qrScannerFactory;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.guests),
    builder: (_) => const GuestScreen(),
  );

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final ListSelectionController _selection;
  bool _isDeleting = false;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = LoadMoreScrollController(
      onLoadMore: () => _resolveCubit(context).loadMoreGuests(),
    );
    _selection = ListSelectionController(onChanged: _onSelectionChanged);

    final cubit = _resolveCubit(context);
    final initialQuery = cubit.state.searchQuery ?? '';
    _isSearchExpanded = initialQuery.isNotEmpty;
    _searchController = TextEditingController(text: initialQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final currentCubit = _resolveCubit(context);
        final result = await currentCubit.fetchGuests();
        if (mounted && !_isRefreshing) {
          if (result == AppFetchResult.cachedFallback) {
            AppFetchFeedback.show(
              context,
              result: result,
              hasData: currentCubit.state.displayedGuests.isNotEmpty,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selection.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  GuestCubit _resolveCubit(BuildContext context) {
    return widget.cubit ?? context.read<GuestCubit>();
  }

  AuthSessionEntity? _resolveSession(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      final sessionCubit = listen
          ? context.watch<UserSessionCubit?>()
          : context.read<UserSessionCubit?>();
      return sessionCubit?.state;
    } on Object catch (_) {
      return null;
    }
  }

  void _showFeedback(GuestCubit cubit, AppFetchResult result) {
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: cubit.state.displayedGuests.isNotEmpty,
    );
  }

  Future<void> _handleRefresh(GuestCubit cubit) async {
    if (_selection.isSelectionMode) {
      return;
    }
    _isRefreshing = true;
    try {
      final query = _searchController.text;
      final result = await cubit.refreshGuests(
        search: query.isEmpty ? null : query,
      );
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: result,
          hasData: cubit.state.displayedGuests.isNotEmpty,
          successMessage: 'Data tamu berhasil diperbarui.',
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _onGuestTapped(GuestItemEntity item) {
    navigateToGuestDetailScreen(
      context,
      item: item,
      cubit: _resolveCubit(context),
    );
  }

  bool _canSelectOrDelete(GuestItemEntity item, AuthSessionEntity? session) {
    return item.canBeDeletedBySession(session);
  }

  void _onGuestCardTapped(
    int index,
    GuestItemEntity item,
    AuthSessionEntity? session,
  ) {
    if (_selection.isSelectionMode) {
      if (!_canSelectOrDelete(item, session)) {
        AppSnackbar.show(
          context,
          message: 'Anda hanya dapat memilih data tamu yang Anda catat.',
        );
        return;
      }

      _selection.toggle(index, item.id);
    } else {
      _onGuestTapped(item);
    }
  }

  void _onGuestCardLongPressed(
    int index,
    GuestItemEntity item,
    AuthSessionEntity? session,
  ) {
    if (_selection.isSelectionMode) return;

    if (!_canSelectOrDelete(item, session)) {
      AppSnackbar.show(
        context,
        message: 'Anda hanya dapat memilih data tamu yang Anda catat.',
      );
      return;
    }

    _selection.toggle(index, item.id);
  }

  Future<void> _onScanPressed() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    final scanned = await Navigator.of(context).push(
      GuestQrScanScreen.route(
        repository: cubit.guestRepository,
        scannerFactory: widget.qrScannerFactory,
      ),
    );
    if (scanned == null || !mounted) return;
    // The detail screen reads the guest from the list state, so a guest that
    // is outside the current page/filter is added for its actions to show up.
    if (cubit.state.displayedGuests.any((g) => g.id == scanned.id)) {
      cubit.onGuestUpdated(scanned);
    } else {
      cubit.onGuestCreated(scanned);
    }
    unawaited(
      navigateToGuestDetailScreen(context, item: scanned, cubit: cubit),
    );
  }

  Future<void> _onOpenCreateForm() async {
    if (_selection.isSelectionMode) return;
    final cubit = _resolveCubit(context);
    await GuestFormDialog.showCreate(context, guestCubit: cubit);
  }

  void _onSelectAllToggled({
    required bool selectAll,
    required List<GuestItemEntity> items,
    required AuthSessionEntity? session,
  }) {
    _selection.setAllSelected(
      selectAll: selectAll,
      ids: [for (final item in items) item.id],
      session: session,
      canSelect: (i) => _canSelectOrDelete(items[i], session),
    );
  }

  Future<void> _onDeleteSelectedPressed({
    required List<GuestItemEntity> items,
  }) {
    final selectedIds = _selection.selectedIds([
      for (final item in items) item.id,
    ]);
    return runListBatchDelete(
      context: context,
      ids: selectedIds,
      noun: 'data tamu',
      delete: () => _resolveCubit(
        context,
      ).deleteMultipleGuests(selectedIds, session: _resolveSession(context)),
      onDeleting: () => setState(() => _isDeleting = true),
      onDone: () => setState(() {
        _isDeleting = false;
        _selection.clear();
      }),
    );
  }

  void _onOpenSearch() {
    _selection.clear();
    setState(() {
      _isSearchExpanded = true;
    });
  }

  void _onCloseSearch() {
    _selection.clear();
    final hasActiveSearch =
        _searchController.text.isNotEmpty ||
        _resolveCubit(context).state.searchQuery != null &&
            _resolveCubit(context).state.searchQuery!.isNotEmpty;
    _searchController.clear();
    setState(() {
      _isSearchExpanded = false;
    });
    if (hasActiveSearch) {
      _onSearch('');
    }
  }

  Future<void> _onSearch(String query) async {
    _selection.clear();
    final currentCubit = _resolveCubit(context);
    final result = await currentCubit.fetchGuests(search: query);
    _showFeedback(currentCubit, result);
  }

  Future<void> _onFilterPressed() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    final state = cubit.state;
    final now = DateTime.now();

    final result = await showAppDateFilterBottomSheet(
      context: context,
      title: 'Tanggal',
      subtitle: 'Rentang waktu',
      scope: AppDateFilterScope.pastOnly,
      currentPeriod: state.filterPeriod,
      initialStartDate: state.startDate ?? now,
      initialEndDate: state.endDate ?? now,
    );

    if (result != null && mounted) {
      _showFeedback(cubit, await cubit.setFilter(result));
    }
  }

  Future<void> _onResetDateFilter() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    _showFeedback(cubit, await cubit.resetDateFilter());
  }

  Future<void> _onOpenCreatorPicker() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final result = await showAppUserFilterBottomSheet(
      context: context,
      onLoadUsers: () => loadGroupMemberFilterOptions(cubit.loadGroupMembers),
      selectedEmail: cubit.state.filterCreatorEmail,
      currentUserSession: session,
    );
    if (!mounted) return;
    if (result != null) {
      final fetchResult = await cubit.changeCreatorFilter(
        email: result.selectedUser?.email,
        name: result.selectedUser?.name,
      );
      _showFeedback(cubit, fetchResult);
    }
  }

  Future<void> _onResetCreatorFilter() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    _showFeedback(cubit, await cubit.changeCreatorFilter());
  }

  Future<void> _onToggleMine() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final userEmail = session?.email;
    final userName = session?.name;
    if (userEmail == null) return;
    final activeCreatorEmail = cubit.state.filterCreatorEmail;
    final isCurrentlyMine = activeCreatorEmail == userEmail;

    final fetchResult = isCurrentlyMine
        ? await cubit.changeCreatorFilter()
        : await cubit.changeCreatorFilter(email: userEmail, name: userName);
    _showFeedback(cubit, fetchResult);
  }

  Future<void> _onToggleActive() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    final isOn = cubit.state.hasActiveStatusFilter;
    _showFeedback(
      cubit,
      await cubit.changeActiveFilter(isActive: isOn ? null : true),
    );
  }

  Future<void> _resetAllFilters() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    _searchController.clear();
    _showFeedback(cubit, await cubit.resetFilters());
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context, listen: true);
    final connectivityCubit = context.watch<ConnectivityCubit?>();
    final isDeviceOffline =
        connectivityCubit?.state == ConnectivityStatus.offline;

    final consumer = BlocConsumer<GuestCubit, GuestState>(
      bloc: cubit,
      listener: (context, state) {
        if (state is GuestError) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is GuestLoaded) {
          final query = state.searchQuery ?? '';
          if (_searchController.text != query) {
            _searchController.text = query;
          }
          _selection.resync([
            for (final item in state.displayedGuests) item.id,
          ]);
        }
      },
      builder: (context, state) {
        final isOffline = isDeviceOffline;
        final currentGuests = state.displayedGuests;
        final isInitialLoading = state is GuestInitial || state is GuestLoading;

        return ListScreenScaffold(
          title: 'Data tamu',
          searchLabel: 'Cari data tamu',
          refreshLabel: 'Memuat ulang data tamu',
          greeting: state.lastSync,
          trailingActions: _isSearchExpanded
              ? const []
              : [
                  AppIconButton(
                    onPressed: isInitialLoading || isOffline
                        ? null
                        : _onScanPressed,
                    semanticLabel: 'Scan QR tamu',
                    tooltip: 'Scan QR',
                    icon: AppSvgIcon(
                      KawaloVectors.qrCodeScan,
                      size: 24,
                      color: isInitialLoading || isOffline
                          ? AppTheme.colorSchemeOf(
                              context,
                            ).onSurface.withValues(
                              alpha: AppStateLayer.disabledOpacity,
                            )
                          : AppTheme.colorSchemeOf(context).onSurface,
                    ),
                  ),
                ],
          isInitialLoading: isInitialLoading,
          isOffline: isOffline,
          isSearchExpanded: _isSearchExpanded,
          searchController: _searchController,
          onSearch: _onSearch,
          onOpenSearch: _onOpenSearch,
          onCloseSearch: _onCloseSearch,
          onRefresh: () => _handleRefresh(cubit),
          bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
          filterBar: _buildFilterBar(
            state: state,
            isLoading: isInitialLoading,
            session: session,
          ),
          body: _buildBody(context, state, cubit, session),
          selection: ListScreenSelection(
            controller: _selection,
            itemCount: currentGuests.length,
            onClear: _selection.clear,
            onAllSelected: (selectAll) {
              _onSelectAllToggled(
                selectAll: selectAll,
                items: currentGuests,
                session: session,
              );
            },
            onDelete: () => _onDeleteSelectedPressed(items: currentGuests),
            isDeleting: _isDeleting,
            deleteLabel: 'Hapus data tamu terpilih',
            deletingLabel: 'Menghapus data tamu terpilih',
            deletingMessage: 'Menghapus data tamu...',
          ),
          createLabel: 'Tamu',
          onCreate: GuestItemEntity.canBeCreatedBySession(session)
              ? _onOpenCreateForm
              : null,
          canPop: !_selection.isSelectionMode,
          onPopBlocked: _selection.clear,
        );
      },
    );

    if (connectivityCubit != null) {
      return BlocListener<ConnectivityCubit, ConnectivityStatus>(
        bloc: connectivityCubit,
        listenWhen: (previous, current) =>
            previous == ConnectivityStatus.offline &&
            current == ConnectivityStatus.online,
        listener: (context, status) {
          _handleRefresh(cubit);
        },
        child: consumer,
      );
    }

    return consumer;
  }

  Widget _buildBody(
    BuildContext context,
    GuestState state,
    GuestCubit cubit,
    AuthSessionEntity? session,
  ) {
    final isLoading = state is GuestInitial || state is GuestLoading;

    if (isLoading) {
      return _buildLoadingSkeleton();
    } else if (state is GuestLoaded) {
      if (state.displayedGuests.isEmpty) {
        if (state.hasActiveFilter) {
          return ListEmptySearchResult(
            noun: 'data tamu',
            onReset: _resetAllFilters,
          );
        } else {
          return _buildEmptyGroupState();
        }
      } else {
        return _buildGuestListView(
          guests: state.displayedGuests,
          isLoadingMore: state.isLoadingMore,
          session: session,
        );
      }
    } else if (state is GuestError) {
      if (state.displayedGuests.isNotEmpty) {
        return _buildGuestListView(
          guests: state.displayedGuests,
          isLoadingMore: false,
          session: session,
        );
      } else {
        return ListErrorState(
          noun: 'data tamu',
          message: state.message,
          onRetry: () {
            final query = _searchController.text;
            cubit.fetchGuests(search: query.isEmpty ? null : query);
          },
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFilterBar({
    required bool isLoading,
    required AuthSessionEntity? session,
    required GuestState state,
  }) {
    final colorScheme = AppTheme.of(context).colorScheme;
    return ListFilterBar(
      isLoading: isLoading,
      isDateActive: state.hasActiveDateFilter,
      dateLabel: state.filterPeriod.resolveDisplayLabel(
        startDate: state.startDate,
        endDate: state.endDate,
      ),
      onDatePressed: _onFilterPressed,
      onDateReset: _onResetDateFilter,
      chips: [
        ListCreatorFilterChip(
          session: session,
          isLoading: isLoading,
          isActive: state.hasActiveCreatorFilter,
          activeEmail: state.filterCreatorEmail,
          activeName: state.filterCreatorName ?? state.filterCreatorEmail,
          onOpenPicker: _onOpenCreatorPicker,
          onReset: _onResetCreatorFilter,
          onToggleMine: _onToggleMine,
        ),
        AppChip(
          type: AppChipType.filter,
          label: 'Masih di lokasi',
          selected: state.hasActiveStatusFilter,
          leading: state.hasActiveStatusFilter
              ? AppSvgIcon(
                  KawaloVectors.checkFilled,
                  size: 18,
                  color: isLoading
                      ? colorScheme.onSurface.withValues(
                          alpha: AppStateLayer.disabledOpacity,
                        )
                      : colorScheme.onSecondaryContainer,
                )
              : null,
          onPressed: isLoading ? null : _onToggleActive,
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListScreenSkeleton(itemBuilder: (_, _) => const GuestCardSkeleton());
  }

  Widget _buildGuestListView({
    required List<GuestItemEntity> guests,
    required bool isLoadingMore,
    required AuthSessionEntity? session,
  }) {
    final isSelection = _selection.isSelectionMode;

    return ListScreenListView(
      controller: _scrollController,
      itemCount: guests.length,
      isLoadingMore: isLoadingMore,
      itemBuilder: (context, index) {
        final item = guests[index];
        final isSelectable = _canSelectOrDelete(item, session);
        final isSelected = _selection.isSelected(index, item.id);

        return GuestCard(
          item: item,
          isSelectionMode: isSelection,
          isSelected: isSelected,
          isSelectable: isSelectable,
          onTap: () => _onGuestCardTapped(index, item, session),
          onLongPress: () => _onGuestCardLongPressed(index, item, session),
        );
      },
    );
  }

  Widget _buildEmptyGroupState() {
    return const AppEmptyState(
      icon: AppSvgIcon.color(KawaloColorVectors.guestValidation),
      title: 'Belum ada data tamu',
      description:
          'Belum ada kunjungan tamu '
          'pada hari ini.',
    );
  }
}
