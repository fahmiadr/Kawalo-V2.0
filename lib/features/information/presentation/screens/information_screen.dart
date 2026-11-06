import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_detail_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card_skeleton.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form_dialog.dart';

/// Halaman utama Pusat Informasi pada navigasi aplikasi Kawalo.
///
/// Menampilkan daftar feed informasi (`tkfeed`) secara responsif dan langsung
/// pada layar dengan [AppSelectionAppBar] terintegrasi yang menyinkronkan
/// tinggi dengan [AppHomeAppBar].
class InformationScreen extends StatefulWidget {
  /// Membuat instance [InformationScreen].
  const InformationScreen({
    super.key,
    this.cubit,
    this.isActive = true,
    this.hasBottomNavigationBar = true,
  });

  /// Cubit informasi opsional untuk pengujian.
  final InformationCubit? cubit;

  /// Menandakan apakah layar sedang aktif/ditampilkan (misalnya di dalam
  /// tab/IndexedStack).
  ///
  /// Bernilai `true` secara default agar kompatibel saat dibuka via routing
  /// biasa. Jika digunakan di dalam [IndexedStack], teruskan status tab aktif
  /// agar [InformationScreen] melakukan fetch data setiap kali tab dibuka.
  final bool isActive;

  /// Menandakan apakah layar memiliki bilah navigasi bawah (bottom navigation
  /// bar) di bawahnya, seperti di dalam MainNavigationScreen.
  ///
  /// Bernilai `true` secara default. Saat keyboard terbuka, tinggi bilah
  /// navigasi bawah akan dikurangkan dari padding bawah agar konten tidak
  /// terdorong terlalu jauh melebihi posisi keyboard.
  final bool hasBottomNavigationBar;

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final AppSelectionController _selectionController;
  final Set<String> _selectedIds = <String>{};
  bool _isDeleting = false;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _selectionController = AppSelectionController();
    _selectionController.addListener(_onSelectionChanged);

    final cubit = _resolveCubit(context);
    final initialQuery = cubit.state.searchQuery ?? '';
    _isSearchExpanded = initialQuery.isNotEmpty;
    _searchController = TextEditingController(text: initialQuery);

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchInitialData();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant InformationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchInitialData();
        }
      });
    }
  }

  Future<void> _fetchInitialData() async {
    final currentCubit = _resolveCubit(context);
    final result = await currentCubit.fetchInformation();
    if (mounted && !_isRefreshing) {
      if (result == AppFetchResult.cachedFallback) {
        AppFetchFeedback.show(
          context,
          result: result,
          hasData: currentCubit.state.displayedInformation.isNotEmpty,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectionController.removeListener(_onSelectionChanged);
    _selectionController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearSelection() {
    _selectionController.clear();
    _selectedIds.clear();
  }

  void _resyncSelectionIndices(List<InformationItemEntity> items) {
    if (_selectedIds.isEmpty) return;
    _selectedIds.retainAll(items.map((e) => e.id));
    _selectionController.clear();
    for (var i = 0; i < items.length; i++) {
      if (_selectedIds.contains(items[i].id)) {
        _selectionController.select(i);
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.85) {
      _resolveCubit(context).loadMoreInformation();
    }
  }

  InformationCubit _resolveCubit(BuildContext context) {
    return widget.cubit ?? context.read<InformationCubit>();
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

  /// Menentukan apakah halaman informasi sedang aktif dan dibuka oleh pengguna
  /// (berada di tab aktif dan merupakan rute teratas pada Navigator).
  bool get _isScreenOpen {
    if (!widget.isActive) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    return true;
  }

  Future<void> _handleRefresh(InformationCubit cubit) async {
    if (_selectionController.isSelectionMode) {
      return;
    }
    _isRefreshing = true;
    try {
      final query = _searchController.text;
      final result = await cubit.refreshInformation(
        search: query.isEmpty ? null : query,
      );
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: result,
          hasData: cubit.state.displayedInformation.isNotEmpty,
          successMessage: 'Data informasi berhasil diperbarui.',
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _onInformationTapped(InformationItemEntity item) {
    navigateToInformationDetailScreen(
      context,
      item: item,
      cubit: _resolveCubit(context),
    );
  }

  Future<void> _onOpenCreateForm() async {
    if (_selectionController.isSelectionMode) return;
    final cubit = _resolveCubit(context);
    await InformationFormDialog.showCreate(
      context,
      informationCubit: cubit,
    );
  }

  Future<void> _onEditInformation(InformationItemEntity item) async {
    if (_selectionController.isSelectionMode) return;
    final cubit = _resolveCubit(context);
    await InformationFormDialog.showUpdate(
      context,
      item: item,
      informationCubit: cubit,
    );
  }

  bool _canSelectOrDelete(
    InformationItemEntity item,
    AuthSessionEntity? session,
  ) {
    return item.canBeDeletedBySession(session);
  }

  void _onInformationCardTapped(
    int index,
    InformationItemEntity item,
    AuthSessionEntity? session,
  ) {
    if (_selectionController.isSelectionMode) {
      if (!_canSelectOrDelete(item, session)) {
        AppSnackbar.show(
          context,
          message: 'Anda hanya dapat memilih informasi yang Anda buat.',
        );
        return;
      }

      _toggleSelection(index, item.id);
    } else {
      _onInformationTapped(item);
    }
  }

  void _onInformationCardLongPressed(
    int index,
    InformationItemEntity item,
    AuthSessionEntity? session,
  ) {
    if (_selectionController.isSelectionMode) return;

    if (!_canSelectOrDelete(item, session)) {
      AppSnackbar.show(
        context,
        message: 'Anda hanya dapat memilih informasi yang Anda buat.',
      );
      return;
    }

    _toggleSelection(index, item.id);
  }

  void _onSelectAllToggled({
    required bool selectAll,
    required List<InformationItemEntity> items,
    required AuthSessionEntity? session,
  }) {
    _clearSelection();
    if (!selectAll) {
      return;
    }

    final isAdmin = session?.role == 'ADMIN' || session == null;
    if (isAdmin) {
      _selectionController.selectAll(items.length);
      for (final item in items) {
        _selectedIds.add(item.id);
      }
    } else {
      for (var i = 0; i < items.length; i++) {
        if (_canSelectOrDelete(items[i], session)) {
          _selectionController.select(i);
          _selectedIds.add(items[i].id);
        }
      }
    }
  }

  Future<void> _onDeleteSelectedPressed({
    required List<InformationItemEntity> items,
  }) async {
    final selectedIds = Set<String>.from(_selectedIds);
    for (final index in _selectionController.selectedIndices) {
      if (index < items.length) {
        selectedIds.add(items[index].id);
      }
    }
    if (selectedIds.isEmpty) return;

    final isDeviceOffline =
        context.read<ConnectivityCubit?>()?.state == ConnectivityStatus.offline;
    if (isDeviceOffline) {
      AppSnackbar.show(
        context,
        message: 'Tidak dapat menghapus informasi saat offline.',
      );
      return;
    }

    final count = selectedIds.length;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus $count informasi?',
      message: '$count informasi terpilih akan dihapus secara permanen.',
    );

    if (!(confirmed ?? false) || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final cubit = _resolveCubit(context);
    final result = await cubit.deleteMultipleInformation(
      selectedIds,
      session: _resolveSession(context),
    );
    if (!mounted) return;

    setState(() {
      _isDeleting = false;
      _clearSelection();
    });

    result.fold(
      (failure) {
        AppSnackbar.show(
          context,
          message: failure.message,
        );
      },
      (_) {
        AppSnackbar.show(
          context,
          message: '$count informasi berhasil dihapus.',
        );
      },
    );
  }

  void _onOpenSearch() {
    _clearSelection();
    setState(() {
      _isSearchExpanded = true;
    });
  }

  void _onCloseSearch() {
    _clearSelection();
    final hasActiveSearch = _searchController.text.isNotEmpty ||
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
    _clearSelection();
    final currentCubit = _resolveCubit(context);
    final result = await currentCubit.fetchInformation(
      search: query,
    );
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: currentCubit.state.displayedInformation.isNotEmpty,
    );
  }

  Future<void> _onFilterPressed() async {
    _clearSelection();
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
      final fetchResult = await cubit.setFilter(result);
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: fetchResult,
          hasData: cubit.state.displayedInformation.isNotEmpty,
        );
      }
    }
  }

  Future<void> _onResetDateFilter() async {
    _clearSelection();
    final cubit = _resolveCubit(context);
    final fetchResult = await cubit.resetDateFilter();
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedInformation.isNotEmpty,
      );
    }
  }

  Future<void> _onOpenAuthorPicker() async {
    _clearSelection();
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final result = await showAppUserFilterBottomSheet(
      context: context,
      onLoadUsers: cubit.loadGroupMembers,
      selectedEmail: cubit.state.filterAuthorEmail,
      currentUserSession: session,
    );
    if (!mounted) return;
    if (result != null) {
      final fetchResult = await cubit.changeAuthorFilter(
        email: result.selectedUser?.email,
        name: result.selectedUser?.name,
      );
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: fetchResult,
          hasData: cubit.state.displayedInformation.isNotEmpty,
        );
      }
    }
  }

  Future<void> _onResetAuthorFilter() async {
    _clearSelection();
    final cubit = _resolveCubit(context);
    final fetchResult = await cubit.changeAuthorFilter();
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedInformation.isNotEmpty,
      );
    }
  }

  Future<void> _onToggleMine() async {
    _clearSelection();
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final userEmail = session?.email;
    final userName = session?.name;
    if (userEmail == null) return;
    final activeAuthorEmail = cubit.state.filterAuthorEmail;
    final isCurrentlyMine = activeAuthorEmail == userEmail;

    final fetchResult = isCurrentlyMine
        ? await cubit.changeAuthorFilter()
        : await cubit.changeAuthorFilter(
            email: userEmail,
            name: userName,
          );
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedInformation.isNotEmpty,
      );
    }
  }

  Future<void> _resetAllFilters() async {
    _clearSelection();
    final cubit = _resolveCubit(context);
    _searchController.clear();
    final fetchResult = await cubit.resetFilters();
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedInformation.isNotEmpty,
      );
    }
  }

  void _toggleSelection(int index, String id) {
    _selectionController.toggle(index);
    if (_selectionController.isSelected(index)) {
      _selectedIds.add(id);
    } else {
      _selectedIds.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context, listen: true);
    final connectivityCubit = context.watch<ConnectivityCubit?>();
    final isDeviceOffline =
        connectivityCubit?.state == ConnectivityStatus.offline;

    final consumer = BlocConsumer<InformationCubit, InformationState>(
      bloc: cubit,
      listener: (context, state) {
        if (state is InformationError) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is InformationLoaded) {
          final query = state.searchQuery ?? '';
          if (_searchController.text != query) {
            _searchController.text = query;
          }
          _resyncSelectionIndices(state.displayedInformation);
        }
      },
      builder: (context, state) {
        final greeting = state.lastSync;

        final isOffline = isDeviceOffline;
        final currentInfo = state.displayedInformation;
        final isInitialLoading =
            state is InformationInitial || state is InformationLoading;

        return _buildScaffold(
          context: context,
          greeting: greeting,
          cubit: cubit,
          session: session,
          currentInformation: currentInfo,
          isOffline: isOffline,
          isInitialLoading: isInitialLoading,
          filterBar: _buildFilterBar(
            context: context,
            state: state,
            isLoading: isInitialLoading,
            session: session,
          ),
          bodyContent: _buildBody(
            context,
            state,
            cubit,
            session,
            isOffline: isOffline,
          ),
        );
      },
    );

    if (connectivityCubit != null) {
      final isScreenOpen = _isScreenOpen;

      return BlocListener<ConnectivityCubit, ConnectivityStatus>(
        bloc: connectivityCubit,
        listenWhen: (previous, current) =>
            isScreenOpen &&
            previous == ConnectivityStatus.offline &&
            current == ConnectivityStatus.online,
        listener: (context, status) {
          if (!_isScreenOpen) {
            return;
          }
          _handleRefresh(cubit);
        },
        child: consumer,
      );
    }

    return consumer;
  }

  Widget _buildBody(
    BuildContext context,
    InformationState state,
    InformationCubit cubit,
    AuthSessionEntity? session, {
    bool isOffline = false,
  }) {
    final isLoading =
        state is InformationInitial || state is InformationLoading;

    if (isLoading) {
      return _buildLoadingSkeleton();
    } else if (state is InformationLoaded) {
      if (state.displayedInformation.isEmpty) {
        if (state.hasActiveFilter) {
          return _buildEmptySearchResult(context);
        } else {
          return _buildEmptyGroupState(context);
        }
      } else {
        return _buildInformationListView(
          information: state.displayedInformation,
          isLoadingMore: state.isLoadingMore,
          session: session,
          isOffline: isOffline,
        );
      }
    } else if (state is InformationError) {
      if (state.displayedInformation.isNotEmpty) {
        return _buildInformationListView(
          information: state.displayedInformation,
          isLoadingMore: false,
          session: session,
          isOffline: isOffline,
        );
      } else {
        return _buildErrorState(context, state.message, cubit);
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFilterBar({
    required BuildContext context,
    required bool isLoading,
    required AuthSessionEntity? session,
    required InformationState state,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = session?.role == 'ADMIN';

    // 1. Label Chip Tanggal
    final isDateActive = state.hasActiveDateFilter;
    final dateLabel = isDateActive
        ? state.filterPeriod.resolveDisplayLabel(
            startDate: state.startDate,
            endDate: state.endDate,
          )
        : 'Tanggal';

    // 2. Chip Pembuat (Role-aware)
    final Widget authorChip;
    if (isAdmin) {
      final isAuthorActive = state.hasActiveAuthorFilter;
      final authorName = state.filterAuthorName ?? state.filterAuthorEmail;
      final authorLabel =
          isAuthorActive ? 'Dibuat oleh $authorName' : 'Dibuat oleh';

      authorChip = AppChip(
        type: AppChipType.filter,
        label: authorLabel,
        selected: isAuthorActive,
        trailing: isAuthorActive
            ? null
            : AppSvgIcon(
                KawaloVectors.arrowDown01,
                size: 18,
                color: !isLoading
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface.withValues(
                        alpha: AppStateLayer.disabledOpacity,
                      ),
              ),
        onDeleted: isAuthorActive && !isLoading ? _onResetAuthorFilter : null,
        onPressed: isLoading ? null : _onOpenAuthorPicker,
      );
    } else {
      final activeAuthorEmail = state.filterAuthorEmail;
      final isMine =
          session?.email != null && activeAuthorEmail == session?.email;

      authorChip = AppChip(
        type: AppChipType.filter,
        label: 'Dibuat oleh saya',
        selected: isMine,
        leading: isMine
            ? AppSvgIcon(
                KawaloVectors.checkFilled,
                size: 18,
                color: !isLoading
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(
                        alpha: AppStateLayer.disabledOpacity,
                      ),
              )
            : null,
        onPressed: isLoading ? null : _onToggleMine,
      );
    }

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space100,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppChip(
              type: AppChipType.filter,
              label: dateLabel,
              selected: isDateActive,
              trailing: isDateActive
                  ? null
                  : AppSvgIcon(
                      KawaloVectors.arrowDown01,
                      size: 18,
                      color: !isLoading
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface.withValues(
                              alpha: AppStateLayer.disabledOpacity,
                            ),
                    ),
              onDeleted: isDateActive && !isLoading ? _onResetDateFilter : null,
              onPressed: isLoading ? null : _onFilterPressed,
            ),
            AppSpacing.hGapSm,
            authorChip,
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required String greeting,
    required InformationCubit cubit,
    required AuthSessionEntity? session,
    required Widget filterBar,
    required Widget bodyContent,
    required List<InformationItemEntity> currentInformation,
    bool isOffline = false,
    bool isInitialLoading = false,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_selectionController.isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _clearSelection();
        }
      },
      child: AppLoadingOverlay(
        isLoading: _isDeleting,
        semanticLabel: 'Menghapus data informasi terpilih',
        message: 'Menghapus data informasi...',
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: colorScheme.surface,
          floatingActionButtonLocation:
              const AppStationaryEndFloatFabLocation(),
          floatingActionButtonAnimator:
              FloatingActionButtonAnimator.noAnimation,
          appBar: AppSelectionAppBar(
            idle: AppHomeAppBar(
              greeting: greeting,
              reserveGreetingSpace: true,
              greetingLoading: isInitialLoading && greeting.isEmpty,
              title: _isSearchExpanded ? null : 'Pusat informasi',
              titleWidget: _isSearchExpanded
                  ? AppSearchBar(
                      controller: _searchController,
                      hintText: 'Cari informasi',
                      autoFocus: true,
                      enabled: !isInitialLoading,
                      onSearch: _onSearch,
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 40,
                      ),
                    )
                  : null,
              trailing: _isSearchExpanded
                  ? AppIconButton(
                      onPressed: !isInitialLoading ? _onCloseSearch : null,
                      semanticLabel: 'Tutup pencarian',
                      icon: AppSvgIcon(
                        KawaloVectors.cancel01,
                        size: 24,
                        color: !isInitialLoading
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(
                                alpha: AppStateLayer.disabledOpacity,
                              ),
                      ),
                    )
                  : AppIconButton(
                      onPressed: !isInitialLoading ? _onOpenSearch : null,
                      semanticLabel: 'Cari informasi',
                      icon: AppSvgIcon(
                        KawaloVectors.search01,
                        size: 24,
                        color: !isInitialLoading
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(
                                alpha: AppStateLayer.disabledOpacity,
                              ),
                      ),
                    ),
            ),
            controller: _selectionController,
            showSelectAll: true,
            itemCount: currentInformation.length,
            onClear: _clearSelection,
            onAllSelected: (selectAll) {
              _onSelectAllToggled(
                selectAll: selectAll,
                items: currentInformation,
                session: session,
              );
            },
            actions: [
              AppIconButton(
                onPressed: _isDeleting || isOffline
                    ? null
                    : () => _onDeleteSelectedPressed(
                          items: currentInformation,
                        ),
                semanticLabel: 'Hapus informasi terpilih',
                icon: AppSvgIcon(
                  KawaloVectors.delete01Filled,
                  color: _isDeleting || isOffline
                      ? colorScheme.onSurface.withValues(
                          alpha: AppStateLayer.disabledOpacity,
                        )
                      : colorScheme.error,
                  size: 24,
                ),
              ),
            ],
          ),
          floatingActionButton: _selectionController.isSelectionMode ||
                  !InformationItemEntity.canBeCreatedBySession(session)
              ? null
              : AppExtendedFab(
                  onPressed: isOffline ? null : _onOpenCreateForm,
                  icon: const AppSvgIcon(
                    KawaloVectors.add01,
                    size: 24,
                  ),
                  label: 'Posting',
                ),
          body: SafeArea(
            top: false,
            child: AppKeyboardInsetsPadding(
              hasBottomNavigationBar: widget.hasBottomNavigationBar,
              isOffline: isOffline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  filterBar,
                  Expanded(
                    child: AppRefreshIndicator.contained(
                      semanticsLabel: 'Memuat ulang pusat informasi',
                      notificationPredicate:
                          _selectionController.isSelectionMode
                              ? (_) => false
                              : defaultScrollNotificationPredicate,
                      onRefresh: () => _handleRefresh(cubit),
                      child: bodyContent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.space200,
        right: AppSpacing.space200,
        top: AppSpacing.space150,
        bottom: AppLayout.fabScrollClearance,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => AppSpacing.vGap200,
      itemBuilder: (_, index) => InformationCardSkeleton(
        showMedia: index.isEven,
      ),
    );
  }

  Widget _buildInformationListView({
    required List<InformationItemEntity> information,
    required bool isLoadingMore,
    required AuthSessionEntity? session,
    bool isOffline = false,
  }) {
    final totalCount = information.length + (isLoadingMore ? 1 : 0);
    final isSelection = _selectionController.isSelectionMode;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.space200,
        right: AppSpacing.space200,
        top: AppSpacing.space150,
        bottom: AppLayout.fabScrollClearance,
      ),
      itemCount: totalCount,
      separatorBuilder: (_, __) => AppSpacing.vGap200,
      itemBuilder: (context, index) {
        if (index == information.length) {
          return const Padding(
            padding: AppSpacing.paddingVertical200,
            child: Center(
              child: AppLoadingIndicator(),
            ),
          );
        }

        final item = information[index];
        final isSelectable = _canSelectOrDelete(item, session);
        final isSelected = _selectionController.isSelected(index) ||
            _selectedIds.contains(item.id);

        return RepaintBoundary(
          child: InformationCard(
            item: item,
            isSelectionMode: isSelection,
            isSelected: isSelected,
            isSelectable: isSelectable,
            currentUserSession: session,
            isOffline: isOffline,
            onTap: () => _onInformationCardTapped(index, item, session),
            onLongPress: () =>
                _onInformationCardLongPressed(index, item, session),
            onEdit: () => _onEditInformation(item),
          ),
        );
      },
    );
  }

  Widget _buildEmptyGroupState(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    return AppEmptyState(
      icon: AppSvgIcon(
        KawaloVectors.kanbanFilled,
        color: colorScheme.secondary,
      ),
      title: 'Belum ada informasi',
      description: 'Belum ada informasi pada hari ini.',
    );
  }

  Widget _buildEmptySearchResult(BuildContext context) {
    return AppEmptyState.search(
      title: 'Informasi tidak ditemukan',
      description: 'Tidak ada informasi yang cocok dengan '
          'pencarian atau filter yang diterapkan.',
      actionLabel: 'Reset filter & pencarian',
      onActionPressed: _resetAllFilters,
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    InformationCubit cubit,
  ) {
    return AppEmptyState.error(
      title: 'Gagal memuat informasi',
      description: message,
      retryLabel: 'Coba lagi',
      onRetry: () {
        final query = _searchController.text;
        cubit.fetchInformation(
          search: query.isEmpty ? null : query,
        );
      },
    );
  }
}
