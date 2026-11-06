import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card_skeleton.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_detail_bottom_sheet.dart';

/// Layar utama fitur Data Absensi Kehadiran.
///
/// Menyajikan data catatan absensi personil dari tabel tkabsen
/// dengan filter pencarian terintegrasi, pemisahan kartu hemat ruang,
/// dan tampilan peta detail OpenStreetMap.
class AttendanceScreen extends StatefulWidget {
  /// Membuat instance [AttendanceScreen].
  const AttendanceScreen({
    super.key,
    this.cubit,
  });

  /// Instance [AttendanceCubit] opsional untuk injeksi pengujian.
  final AttendanceCubit? cubit;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    final cubit = _resolveCubit(context);
    final initialQuery = cubit.state.searchQuery ?? '';
    _isSearchExpanded = initialQuery.isNotEmpty;
    _searchController = TextEditingController(text: initialQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final currentCubit = _resolveCubit(context);
        final result = await currentCubit.fetchAttendances();
        if (mounted && !_isRefreshing) {
          // Tidak menampilkan feedback saat berhasil dimuat dari server.
          // Hanya berikan feedback jika menyajikan cache (offline/server down).
          if (result == AppFetchResult.cachedFallback) {
            AppFetchFeedback.show(
              context,
              result: result,
              hasData: currentCubit.state.displayedAttendances.isNotEmpty,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.85) {
      _resolveCubit(context).loadMoreAttendances();
    }
  }

  AttendanceCubit _resolveCubit(BuildContext context) {
    return widget.cubit ?? context.read<AttendanceCubit>();
  }

  Future<void> _handleRefresh(AttendanceCubit cubit) async {
    _isRefreshing = true;
    try {
      final query = _searchController.text;
      final result = await cubit.refreshAttendances(
        search: query.isEmpty ? null : query,
      );
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: result,
          hasData: cubit.state.displayedAttendances.isNotEmpty,
          successMessage: 'Data absensi berhasil diperbarui.',
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _onAttendanceTapped(AttendanceItemEntity item) {
    AttendanceDetailBottomSheet.show(
      context: context,
      item: item,
    );
  }

  void _onOpenSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
  }

  void _onCloseSearch() {
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
    final currentCubit = _resolveCubit(context);
    final result = await currentCubit.fetchAttendances(search: query);
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: currentCubit.state.displayedAttendances.isNotEmpty,
    );
  }

  Future<void> _onFilterPressed() async {
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
          hasData: cubit.state.displayedAttendances.isNotEmpty,
        );
      }
    }
  }

  Future<void> _onResetDateFilter() async {
    final cubit = _resolveCubit(context);
    final fetchResult = await cubit.resetDateFilter();
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedAttendances.isNotEmpty,
      );
    }
  }

  Future<void> _resetAllFilters() async {
    final cubit = _resolveCubit(context);
    _searchController.clear();
    final fetchResult = await cubit.resetFilters();
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedAttendances.isNotEmpty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    final connectivityCubit = context.watch<ConnectivityCubit?>();
    final isDeviceOffline =
        connectivityCubit?.state == ConnectivityStatus.offline;

    final consumer = BlocConsumer<AttendanceCubit, AttendanceState>(
      bloc: cubit,
      listener: (context, state) {
        if (state is AttendanceError) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is AttendanceLoaded) {
          final query = state.searchQuery ?? '';
          if (_searchController.text != query) {
            _searchController.text = query;
          }
        }
      },
      builder: (context, state) {
        final greeting = state.lastSync;
        final isOffline = isDeviceOffline;
        final isInitialLoading =
            state is AttendanceInitial || state is AttendanceLoading;

        return _buildScaffold(
          context: context,
          greeting: greeting,
          cubit: cubit,
          isOffline: isOffline,
          isInitialLoading: isInitialLoading,
          filterBar: _buildFilterBar(
            context: context,
            state: state,
            isLoading: isInitialLoading,
          ),
          bodyContent: _buildBody(context, state, cubit),
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
    AttendanceState state,
    AttendanceCubit cubit,
  ) {
    if (state is AttendanceInitial || state is AttendanceLoading) {
      return _buildLoadingSkeleton();
    }

    if (state is AttendanceLoaded) {
      if (state.attendances.isEmpty) {
        if (state.hasActiveFilter) {
          return _buildEmptySearchResult(context);
        }
        return _buildEmptyGroupState(context);
      }
      return _buildAttendanceListView(
        attendances: state.attendances,
        isLoadingMore: state.isLoadingMore,
      );
    }

    if (state is AttendanceError) {
      if (state.cachedAttendances.isNotEmpty) {
        return _buildAttendanceListView(
          attendances: state.cachedAttendances,
          isLoadingMore: false,
        );
      }
      return _buildErrorState(context, state.message, cubit);
    }

    return const SizedBox.shrink();
  }

  Widget _buildFilterBar({
    required BuildContext context,
    required bool isLoading,
    required AttendanceState state,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    final isDateActive = state.hasActiveDateFilter;
    final dateLabel = isDateActive
        ? state.filterPeriod.resolveDisplayLabel(
            startDate: state.startDate,
            endDate: state.endDate,
          )
        : 'Tanggal';

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
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required String greeting,
    required AttendanceCubit cubit,
    required Widget filterBar,
    required Widget bodyContent,
    bool isOffline = false,
    bool isInitialLoading = false,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.surface,
      appBar: AppHomeAppBar(
        greeting: greeting,
        reserveGreetingSpace: true,
        greetingLoading: isInitialLoading && greeting.isEmpty,
        title: _isSearchExpanded ? null : 'Data absensi',
        titleWidget: _isSearchExpanded
            ? AppSearchBar(
                controller: _searchController,
                hintText: 'Cari data absensi',
                autoFocus: true,
                enabled: !isInitialLoading,
                onSearch: _onSearch,
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 40,
                ),
              )
            : null,
        showBackButton: true,
        trailing: AppIconButton(
          onPressed: !isInitialLoading
              ? (_isSearchExpanded ? _onCloseSearch : _onOpenSearch)
              : null,
          semanticLabel:
              _isSearchExpanded ? 'Tutup pencarian' : 'Cari data absensi',
          icon: AppSvgIcon(
            _isSearchExpanded ? KawaloVectors.cancel01 : KawaloVectors.search01,
            size: 24,
            color: !isInitialLoading
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(
                    alpha: AppStateLayer.disabledOpacity,
                  ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomOfflineBanner(
        isOffline: isOffline,
      ),
      body: SafeArea(
        top: false,
        child: AppKeyboardInsetsPadding(
          isOffline: isOffline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filterBar,
              Expanded(
                child: AppRefreshIndicator.contained(
                  semanticsLabel: 'Memuat ulang data absensi',
                  onRefresh: () => _handleRefresh(cubit),
                  child: bodyContent,
                ),
              ),
            ],
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
        bottom: AppSpacing.space200,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => AppSpacing.vGap200,
      itemBuilder: (_, __) => const AttendanceCardSkeleton(),
    );
  }

  Widget _buildAttendanceListView({
    required List<AttendanceItemEntity> attendances,
    required bool isLoadingMore,
  }) {
    final totalCount = attendances.length + (isLoadingMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.space200,
        right: AppSpacing.space200,
        top: AppSpacing.space150,
        bottom: AppSpacing.space200,
      ),
      itemCount: totalCount,
      separatorBuilder: (_, __) => AppSpacing.vGap200,
      itemBuilder: (context, index) {
        if (index == attendances.length) {
          return const Padding(
            padding: AppSpacing.paddingVertical200,
            child: Center(
              child: AppLoadingIndicator(),
            ),
          );
        }

        final item = attendances[index];
        return AttendanceCard(
          item: item,
          onTap: () => _onAttendanceTapped(item),
        );
      },
    );
  }

  Widget _buildEmptyGroupState(BuildContext context) {
    return const AppEmptyState(
      icon: AppSvgIcon.color(
        KawaloColorVectors.checklist2,
      ),
      title: 'Belum ada data absensi',
      description: 'Belum ada aktivitas absensi personil pada hari ini.',
    );
  }

  Widget _buildEmptySearchResult(BuildContext context) {
    return AppEmptyState.search(
      title: 'Data absensi tidak ditemukan',
      description: 'Tidak ada data absensi yang cocok dengan '
          'pencarian atau filter yang diterapkan.',
      actionLabel: 'Reset filter & pencarian',
      onActionPressed: _resetAllFilters,
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    AttendanceCubit cubit,
  ) {
    return AppEmptyState.error(
      title: 'Gagal memuat data absensi',
      description: message,
      retryLabel: 'Coba lagi',
      onRetry: () {
        final query = _searchController.text;
        cubit.fetchAttendances(
          search: query.isEmpty ? null : query,
        );
      },
    );
  }
}
