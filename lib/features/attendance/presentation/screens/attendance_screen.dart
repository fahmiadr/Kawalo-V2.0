import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_scaffold.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/attendance/attendance_module.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card_skeleton.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_detail_bottom_sheet.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_card.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_cubit.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// `GET /attendance` as "Riwayat Absen" (guards) or "Laporan Absensi"
/// (admins, with the summary): preset range chips, search, detail sheet.
class AttendanceScreen extends StatefulWidget {
  /// Membuat instance [AttendanceScreen].
  const AttendanceScreen({super.key, this.cubit, this.statsCubit});

  /// Instance [AttendanceCubit] opsional untuk injeksi pengujian.
  final AttendanceCubit? cubit;

  /// Instance [AttendanceStatsCubit] opsional untuk injeksi pengujian. Tanpa
  /// ini layar membuatnya dari [AttendanceModule]; bila modul tidak tersedia,
  /// kartu ringkasan tidak ditampilkan.
  final AttendanceStatsCubit? statsCubit;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.attendance),
    builder: (_) => const AttendanceScreen(),
  );

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;
  AttendanceStatsCubit? _statsCubit;
  String? _loadedStatsKey;

  @override
  void initState() {
    super.initState();
    _statsCubit =
        widget.statsCubit ??
        context.read<AttendanceModule?>()?.createStatsCubit();
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
        // The state listener only fires on a change, so cover the case where
        // the fetch left an already-loaded state untouched.
        final loaded = currentCubit.state;
        if (mounted && loaded is AttendanceLoaded) _syncStats(loaded);
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
    if (widget.statsCubit == null) unawaited(_statsCubit?.close());
    super.dispose();
  }

  /// Reloads the summary when the date range or the last sync changed; page
  /// loads (infinite scroll) leave both untouched.
  void _syncStats(AttendanceLoaded state) {
    final stats = _statsCubit;
    if (stats == null) return;
    final today = DateTime.now().toIso8601String();
    final from = (state.startDateIso ?? today).substring(0, 10);
    final to = (state.endDateIso ?? today).substring(0, 10);
    final key = '$from|$to|${state.lastSync}';
    if (key == _loadedStatsKey) return;
    _loadedStatsKey = key;
    unawaited(stats.load(from: from, to: to));
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
    final isAdmin =
        context.watch<UserSessionCubit?>()?.state?.isAdminRole ?? false;

    final consumer = BlocConsumer<AttendanceCubit, AttendanceState>(
      bloc: cubit,
      listener: (context, state) {
        if (state is AttendanceError) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is AttendanceLoaded) {
          _syncStats(state);
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
          title: isAdmin ? 'Laporan Absensi' : 'Riwayat Absen',
          searchLabel: 'Cari data absensi',
          refreshLabel: 'Memuat ulang data absensi',
          lastSync: state.lastSync,
          isInitialLoading: isInitialLoading,
          isOffline: isOffline,
          isSearchExpanded: _isSearchExpanded,
          searchController: _searchController,
          onSearch: _onSearch,
          onOpenSearch: _onOpenSearch,
          onCloseSearch: _onCloseSearch,
          onRefresh: () => _handleRefresh(cubit),
          filterBar: _buildRangeBar(state, isLoading: isInitialLoading),
          body: _buildBody(context, state, cubit, isAdmin: isAdmin),
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
    AttendanceCubit cubit, {
    required bool isAdmin,
  }) {
    if (state is AttendanceInitial || state is AttendanceLoading) {
      return ListScreenSkeleton(
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
        return _buildEmptyGroupState(isAdmin: isAdmin);
      }
      return _buildAttendanceListView(
        attendances: state.attendances,
        isLoadingMore: state.isLoadingMore,
        stats: _buildStatsHeader(state),
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

  Widget? _buildStatsHeader(AttendanceLoaded state) {
    final stats = _statsCubit;
    if (stats == null) return null;
    return AttendanceStatsCard(
      cubit: stats,
      rangeLabel: state.filterPeriod.resolveDisplayLabel(
        startDate: state.startDate,
        endDate: state.endDate,
      ),
    );
  }

  Widget _buildAttendanceListView({
    required List<AttendanceItemEntity> attendances,
    required bool isLoadingMore,
    Widget? stats,
  }) {
    // The summary is list item 0 so it scrolls away with the list.
    final offset = stats == null ? 0 : 1;
    return ListScreenListView(
      controller: _scrollController,
      itemCount: attendances.length + offset,
      isLoadingMore: isLoadingMore,
      itemBuilder: (context, index) {
        if (stats != null && index == 0) return stats;
        final item = attendances[index - offset];
        return AttendanceCard(
          item: item,
          onTap: () => _onAttendanceTapped(item),
        );
      },
    );
  }

  Widget _buildEmptyGroupState({required bool isAdmin}) {
    final tones = KawaloTones.of(context);
    return TaskMessage(
      icon: Icon(isAdmin ? Icons.insert_chart_outlined : Icons.schedule),
      kind: isAdmin ? TaskMessageKind.neutral : TaskMessageKind.tone,
      tone: tones.abs,
      title: 'Belum ada absensi',
      message: isAdmin
          ? 'Belum ada yang check-in pada rentang ini.'
          : 'Check-in Anda pada rentang ini akan muncul di sini.',
    );
  }

  // Preset ranges of the chips (`RdRiwayatAbsen`, `RdLaporanAbsen`), mapped
  // onto the cubit's date filter; "Pilih tanggal" opens the full picker.
  static const _today = 'today';
  static const _days7 = '7';
  static const _days30 = '30';
  static const _thisMonth = 'month';
  static const _custom = 'custom';

  static bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  String _selectedRange(AttendanceState state) {
    switch (state.filterPeriod) {
      case AppDateFilterPeriod.today:
        return _today;
      case AppDateFilterPeriod.thisMonth:
        return _thisMonth;
      case AppDateFilterPeriod.thisWeek:
        return _custom;
      case AppDateFilterPeriod.custom:
        final now = DateTime.now();
        if (!_sameDay(state.endDate, now)) return _custom;
        for (final (key, days) in [(_days7, 6), (_days30, 29)]) {
          if (_sameDay(
            state.startDate,
            DateTime(now.year, now.month, now.day - days),
          )) {
            return key;
          }
        }
        return _custom;
    }
  }

  Future<void> _onRangeSelected(String range) async {
    final cubit = _resolveCubit(context);
    final now = DateTime.now();
    AppDateFilterResult preset(int days) => AppDateFilterResult.sanitize(
      period: AppDateFilterPeriod.custom,
      startDate: DateTime(now.year, now.month, now.day - days),
      endDate: now,
      scope: AppDateFilterScope.pastOnly,
    );
    final AppFetchResult result;
    switch (range) {
      case _today:
        result = await cubit.resetDateFilter();
      case _days7:
        result = await cubit.setFilter(preset(6));
      case _days30:
        result = await cubit.setFilter(preset(29));
      case _thisMonth:
        result = await cubit.setFilter(
          AppDateFilterResult.sanitize(period: AppDateFilterPeriod.thisMonth),
        );
      default:
        await _onFilterPressed();
        return;
    }
    _showFeedback(cubit, result);
  }

  Widget _buildRangeBar(AttendanceState state, {required bool isLoading}) {
    final tones = KawaloTones.of(context);
    final selected = _selectedRange(state);
    final customLabel = selected == _custom
        ? state.filterPeriod.resolveDisplayLabel(
            startDate: state.startDate,
            endDate: state.endDate,
          )
        : 'Pilih tanggal';
    return ColoredBox(
      color: tones.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: TaskChoiceChips<String>(
          enabled: !isLoading,
          tone: tones.abs,
          selected: selected,
          onSelected: (range) => unawaited(_onRangeSelected(range)),
          options: [
            (_today, 'Hari ini'),
            (_days7, '7 hari'),
            (_days30, '30 hari'),
            (_thisMonth, 'Bulan ini'),
            (_custom, customLabel),
          ],
        ),
      ),
    );
  }
}
