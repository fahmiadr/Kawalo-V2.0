import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_filter_bar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_scaffold.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
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
  const AttendanceScreen({super.key, this.cubit});

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
    _scrollController = LoadMoreScrollController(
      onLoadMore: () => _resolveCubit(context).loadMoreAttendances(),
    );

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
    _scrollController.dispose();
    super.dispose();
  }

  AttendanceCubit _resolveCubit(BuildContext context) {
    return widget.cubit ?? context.read<AttendanceCubit>();
  }

  void _showFeedback(AttendanceCubit cubit, AppFetchResult result) {
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: cubit.state.displayedAttendances.isNotEmpty,
    );
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
    AttendanceDetailBottomSheet.show(context: context, item: item);
  }

  void _onOpenSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
  }

  void _onCloseSearch() {
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
    final currentCubit = _resolveCubit(context);
    final result = await currentCubit.fetchAttendances(search: query);
    _showFeedback(currentCubit, result);
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
      _showFeedback(cubit, await cubit.setFilter(result));
    }
  }

  Future<void> _onResetDateFilter() async {
    final cubit = _resolveCubit(context);
    _showFeedback(cubit, await cubit.resetDateFilter());
  }

  Future<void> _resetAllFilters() async {
    final cubit = _resolveCubit(context);
    _searchController.clear();
    _showFeedback(cubit, await cubit.resetFilters());
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
        final isOffline = isDeviceOffline;
        final isInitialLoading =
            state is AttendanceInitial || state is AttendanceLoading;

        return ListScreenScaffold(
          title: 'Data absensi',
          searchLabel: 'Cari data absensi',
          refreshLabel: 'Memuat ulang data absensi',
          greeting: state.lastSync,
          isInitialLoading: isInitialLoading,
          isOffline: isOffline,
          isSearchExpanded: _isSearchExpanded,
          searchController: _searchController,
          onSearch: _onSearch,
          onOpenSearch: _onOpenSearch,
          onCloseSearch: _onCloseSearch,
          onRefresh: () => _handleRefresh(cubit),
          bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
          filterBar: ListFilterBar(
            isLoading: isInitialLoading,
            isDateActive: state.hasActiveDateFilter,
            dateLabel: state.filterPeriod.resolveDisplayLabel(
              startDate: state.startDate,
              endDate: state.endDate,
            ),
            onDatePressed: _onFilterPressed,
            onDateReset: _onResetDateFilter,
          ),
          body: _buildBody(context, state, cubit),
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
      return ListScreenSkeleton(
        bottomPadding: AppSpacing.space200,
        itemBuilder: (_, _) => const AttendanceCardSkeleton(),
      );
    }

    if (state is AttendanceLoaded) {
      if (state.attendances.isEmpty) {
        if (state.hasActiveFilter) {
          return ListEmptySearchResult(
            noun: 'data absensi',
            onReset: _resetAllFilters,
          );
        }
        return _buildEmptyGroupState();
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
      return ListErrorState(
        noun: 'data absensi',
        message: state.message,
        onRetry: () {
          final query = _searchController.text;
          cubit.fetchAttendances(search: query.isEmpty ? null : query);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAttendanceListView({
    required List<AttendanceItemEntity> attendances,
    required bool isLoadingMore,
  }) {
    return ListScreenListView(
      controller: _scrollController,
      bottomPadding: AppSpacing.space200,
      itemCount: attendances.length,
      isLoadingMore: isLoadingMore,
      itemBuilder: (context, index) {
        final item = attendances[index];
        return AttendanceCard(
          item: item,
          onTap: () => _onAttendanceTapped(item),
        );
      },
    );
  }

  Widget _buildEmptyGroupState() {
    return const AppEmptyState(
      icon: AppSvgIcon.color(KawaloColorVectors.checklist2),
      title: 'Belum ada data absensi',
      description: 'Belum ada aktivitas absensi personil pada hari ini.',
    );
  }
}
