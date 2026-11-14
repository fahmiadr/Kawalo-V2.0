import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_batch_delete.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_filter_bar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_scaffold.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_selection_controller.dart';
import 'package:kawalo_mobile/features/group/presentation/group_member_filter_options.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_detail_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card_skeleton.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form_dialog.dart';

/// Informasi list (redesign 2026), opened from the "Lainnya" card: cards with
/// a category pill, title and first line; date and author filters; members
/// who may post get one "Tulis Informasi" action at the bottom.
class InformationScreen extends StatefulWidget {
  const InformationScreen({
    super.key,
    this.cubit,
    this.isActive = true,
    this.hasBottomNavigationBar = true,
  });

  /// Opened from the Beranda "Lainnya" card; no longer a tab.
  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.information),
    builder: (_) => const InformationScreen(hasBottomNavigationBar: false),
  );

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
  late final ListSelectionController _selection;
  bool _isDeleting = false;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = LoadMoreScrollController(
      onLoadMore: () => _resolveCubit(context).loadMoreInformation(),
    );
    _selection = ListSelectionController(onChanged: _onSelectionChanged);

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
    _selection.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) {
      setState(() {});
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

  void _showFeedback(InformationCubit cubit, AppFetchResult result) {
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: cubit.state.displayedInformation.isNotEmpty,
    );
  }

  Future<void> _handleRefresh(InformationCubit cubit) async {
    if (_selection.isSelectionMode) {
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
    if (_selection.isSelectionMode) return;
    final cubit = _resolveCubit(context);
    await InformationFormDialog.showCreate(context, informationCubit: cubit);
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
    if (_selection.isSelectionMode) {
      if (!_canSelectOrDelete(item, session)) {
        AppSnackbar.show(
          context,
          message: 'Anda hanya dapat memilih informasi yang Anda buat.',
        );
        return;
      }

      _selection.toggle(index, item.id);
    } else {
      _onInformationTapped(item);
    }
  }

  void _onInformationCardLongPressed(
    int index,
    InformationItemEntity item,
    AuthSessionEntity? session,
  ) {
    if (_selection.isSelectionMode) return;

    if (!_canSelectOrDelete(item, session)) {
      AppSnackbar.show(
        context,
        message: 'Anda hanya dapat memilih informasi yang Anda buat.',
      );
      return;
    }

    _selection.toggle(index, item.id);
  }

  void _onSelectAllToggled({
    required bool selectAll,
    required List<InformationItemEntity> items,
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
    required List<InformationItemEntity> items,
  }) {
    final selectedIds = _selection.selectedIds([
      for (final item in items) item.id,
    ]);
    return runListBatchDelete(
      context: context,
      ids: selectedIds,
      noun: 'informasi',
      delete: () => _resolveCubit(context).deleteMultipleInformation(
        selectedIds,
        session: _resolveSession(context),
      ),
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
    final result = await currentCubit.fetchInformation(search: query);
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

  Future<void> _onOpenAuthorPicker() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final result = await showAppUserFilterBottomSheet(
      context: context,
      onLoadUsers: () => loadGroupMemberFilterOptions(cubit.loadGroupMembers),
      selectedEmail: cubit.state.filterAuthorEmail,
      currentUserSession: session,
    );
    if (!mounted) return;
    if (result != null) {
      final fetchResult = await cubit.changeAuthorFilter(
        email: result.selectedUser?.email,
        name: result.selectedUser?.name,
      );
      _showFeedback(cubit, fetchResult);
    }
  }

  Future<void> _onResetAuthorFilter() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    _showFeedback(cubit, await cubit.changeAuthorFilter());
  }

  Future<void> _onToggleMine() async {
    _selection.clear();
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final userEmail = session?.email;
    final userName = session?.name;
    if (userEmail == null) return;
    final activeAuthorEmail = cubit.state.filterAuthorEmail;
    final isCurrentlyMine = activeAuthorEmail == userEmail;

    final fetchResult = isCurrentlyMine
        ? await cubit.changeAuthorFilter()
        : await cubit.changeAuthorFilter(email: userEmail, name: userName);
    _showFeedback(cubit, fetchResult);
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
          _selection.resync([
            for (final item in state.displayedInformation) item.id,
          ]);
        }
      },
      builder: (context, state) {
        final isOffline = isDeviceOffline;
        final currentInfo = state.displayedInformation;
        final isInitialLoading =
            state is InformationInitial || state is InformationLoading;

        return ListScreenScaffold(
          title: 'Informasi',
          searchLabel: 'Cari informasi',
          refreshLabel: 'Memuat ulang pusat informasi',
          lastSync: state.lastSync,
          isInitialLoading: isInitialLoading,
          isOffline: isOffline,
          isSearchExpanded: _isSearchExpanded,
          searchController: _searchController,
          onSearch: _onSearch,
          onOpenSearch: _onOpenSearch,
          onCloseSearch: _onCloseSearch,
          onRefresh: () => _handleRefresh(cubit),
          showBackButton: !widget.hasBottomNavigationBar,
          hasBottomNavigationBar: widget.hasBottomNavigationBar,
          filterBar: _buildFilterBar(
            state: state,
            isLoading: isInitialLoading,
            session: session,
          ),
          body: _buildBody(
            context,
            state,
            cubit,
            session,
            isOffline: isOffline,
          ),
          selection: ListScreenSelection(
            controller: _selection,
            itemCount: currentInfo.length,
            onClear: _selection.clear,
            onAllSelected: (selectAll) {
              _onSelectAllToggled(
                selectAll: selectAll,
                items: currentInfo,
                session: session,
              );
            },
            onDelete: () => _onDeleteSelectedPressed(items: currentInfo),
            isDeleting: _isDeleting,
            deleteLabel: 'Hapus informasi terpilih',
            deletingLabel: 'Menghapus data informasi terpilih',
            deletingMessage: 'Menghapus data informasi...',
          ),
          bottomNavigationBar: _buildBottomBar(
            canCreate:
                InformationItemEntity.canBeCreatedBySession(session) &&
                !_selection.isSelectionMode,
            isOffline: isOffline,
          ),
          canPop: !_selection.isSelectionMode,
          onPopBlocked: _selection.clear,
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
          return ListEmptySearchResult(
            noun: 'informasi',
            onReset: _resetAllFilters,
          );
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
        return ListErrorState(
          noun: 'informasi',
          message: state.message,
          onRetry: () {
            final query = _searchController.text;
            cubit.fetchInformation(search: query.isEmpty ? null : query);
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
    required InformationState state,
  }) {
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
          isActive: state.hasActiveAuthorFilter,
          activeEmail: state.filterAuthorEmail,
          activeName: state.filterAuthorName ?? state.filterAuthorEmail,
          onOpenPicker: _onOpenAuthorPicker,
          onReset: _onResetAuthorFilter,
          onToggleMine: _onToggleMine,
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListScreenSkeleton(
      itemBuilder: (_, index) => const InformationCardSkeleton(),
    );
  }

  Widget _buildInformationListView({
    required List<InformationItemEntity> information,
    required bool isLoadingMore,
    required AuthSessionEntity? session,
    bool isOffline = false,
  }) {
    final isSelection = _selection.isSelectionMode;

    return ListScreenListView(
      controller: _scrollController,
      itemCount: information.length,
      isLoadingMore: isLoadingMore,
      itemBuilder: (context, index) {
        final item = information[index];
        final isSelectable = _canSelectOrDelete(item, session);
        final isSelected = _selection.isSelected(index, item.id);

        return RepaintBoundary(
          child: InformationCard(
            item: item,
            isSelectionMode: isSelection,
            isSelected: isSelected,
            isSelectable: isSelectable,
            onTap: () => _onInformationCardTapped(index, item, session),
            onLongPress: () =>
                _onInformationCardLongPressed(index, item, session),
          ),
        );
      },
    );
  }

  Widget? _buildBottomBar({required bool canCreate, required bool isOffline}) {
    if (!canCreate) return null;
    return AppTaskFooter(
      children: [
        AppTaskButton(
          label: 'Tulis Informasi',
          icon: Icons.edit_outlined,
          onPressed: isOffline ? null : _onOpenCreateForm,
        ),
      ],
    );
  }

  Widget _buildEmptyGroupState(BuildContext context) {
    final tones = KawaloTones.of(context);
    return AppEmptyState(
      icon: Icon(Icons.campaign_outlined, size: 48, color: tones.ink2),
      title: 'Belum ada informasi',
      description: 'Pengumuman dari admin grup tampil di sini.',
    );
  }
}
