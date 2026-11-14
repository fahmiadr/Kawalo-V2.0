import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_scaffold.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';
import 'package:kawalo_mobile/features/operational/presentation/screens/operational_detail_screen.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_card.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_card_skeleton.dart';

/// Read-only duty activity of the group's members (one row per member per
/// day, grouped by e-mail from `tkdutyjourney`).
class OperationalScreen extends StatefulWidget {
  const OperationalScreen({super.key, this.cubit});

  /// Test injection; defaults to the [OperationalCubit] of the widget tree.
  final OperationalCubit? cubit;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.operational),
    builder: (_) => const OperationalScreen(),
  );

  @override
  State<OperationalScreen> createState() => _OperationalScreenState();
}

class _OperationalScreenState extends State<OperationalScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = LoadMoreScrollController(
      onLoadMore: () => _resolveCubit(context).loadMoreOperationals(),
    );

    final cubit = _resolveCubit(context);
    final initialQuery = cubit.state.searchQuery ?? '';
    _isSearchExpanded = initialQuery.isNotEmpty;
    _searchController = TextEditingController(text: initialQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final currentCubit = _resolveCubit(context);
        final result = await currentCubit.fetchOperationals();
        if (mounted && !_isRefreshing) {
          if (result == AppFetchResult.cachedFallback) {
            AppFetchFeedback.show(
              context,
              result: result,
              hasData: currentCubit.state.displayedOperationals.isNotEmpty,
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

  OperationalCubit _resolveCubit(BuildContext context) {
    return widget.cubit ?? context.read<OperationalCubit>();
  }

  void _showFeedback(OperationalCubit cubit, AppFetchResult result) {
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: cubit.state.displayedOperationals.isNotEmpty,
    );
  }

  Future<void> _handleRefresh(OperationalCubit cubit) async {
    _isRefreshing = true;
    try {
      final query = _searchController.text;
      final result = await cubit.refreshOperationals(
        search: query.isEmpty ? null : query,
      );
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: result,
          hasData: cubit.state.displayedOperationals.isNotEmpty,
          successMessage: 'Aktivitas operasional berhasil diperbarui.',
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _onOperationalTapped(OperationalItemEntity item) {
    navigateToOperationalDetailScreen(
      context,
      item: item,
      cubit: _resolveCubit(context),
    );
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
    final result = await currentCubit.fetchOperationals(search: query);
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

  Future<void> _onThisWeek() async {
    final cubit = _resolveCubit(context);
    _showFeedback(
      cubit,
      await cubit.setFilter(
        AppDateFilterResult.sanitize(period: AppDateFilterPeriod.thisWeek),
      ),
    );
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

    final consumer = BlocConsumer<OperationalCubit, OperationalState>(
      bloc: cubit,
      listener: (context, state) {
        if (state is OperationalError) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is OperationalLoaded) {
          final query = state.searchQuery ?? '';
          if (_searchController.text != query) {
            _searchController.text = query;
          }
        }
      },
      builder: (context, state) {
        final isOffline = isDeviceOffline;
        final isInitialLoading =
            state is OperationalInitial || state is OperationalLoading;

        return ListScreenScaffold(
          title: 'Aktivitas Operasional',
          searchLabel: 'Cari aktivitas operasional',
          refreshLabel: 'Memuat ulang aktivitas operasional',
          lastSync: state.lastSync,
          isInitialLoading: isInitialLoading,
          isOffline: isOffline,
          isSearchExpanded: _isSearchExpanded,
          searchController: _searchController,
          onSearch: _onSearch,
          onOpenSearch: _onOpenSearch,
          onCloseSearch: _onCloseSearch,
          onRefresh: () => _handleRefresh(cubit),
          filterBar: _DateChips(
            isLoading: isInitialLoading,
            period: state.filterPeriod,
            customLabel: state.filterPeriod.resolveDisplayLabel(
              startDate: state.startDate,
              endDate: state.endDate,
            ),
            onToday: _onResetDateFilter,
            onThisWeek: _onThisWeek,
            onPick: _onFilterPressed,
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
    OperationalState state,
    OperationalCubit cubit,
  ) {
    if (state is OperationalInitial || state is OperationalLoading) {
      return ListScreenSkeleton(
        itemBuilder: (_, _) => const OperationalCardSkeleton(),
      );
    }

    if (state is OperationalLoaded) {
      if (state.operationals.isEmpty) {
        if (state.hasActiveFilter) {
          return ListEmptySearchResult(
            noun: 'aktivitas operasional',
            onReset: _resetAllFilters,
          );
        }
        return _buildEmptyGroupState();
      }
      return _buildOperationalListView(
        operationals: state.operationals,
        isLoadingMore: state.isLoadingMore,
      );
    }

    if (state is OperationalError) {
      if (state.cachedOperationals.isNotEmpty) {
        return _buildOperationalListView(
          operationals: state.cachedOperationals,
          isLoadingMore: false,
        );
      }
      return ListErrorState(
        noun: 'aktivitas operasional',
        message: state.message,
        onRetry: () {
          final query = _searchController.text;
          cubit.fetchOperationals(search: query.isEmpty ? null : query);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildOperationalListView({
    required List<OperationalItemEntity> operationals,
    required bool isLoadingMore,
  }) {
    return ListScreenListView(
      controller: _scrollController,
      itemCount: operationals.length,
      isLoadingMore: isLoadingMore,
      itemBuilder: (context, index) {
        final item = operationals[index];
        return OperationalCard(
          item: item,
          onTap: () => _onOperationalTapped(item),
        );
      },
    );
  }

  Widget _buildEmptyGroupState() {
    return AppEmptyState(
      icon: Icon(
        Icons.bar_chart_rounded,
        size: 64,
        color: KawaloTones.of(context).ink2,
      ),
      title: 'Belum ada aktivitas',
      description: 'Aktivitas dinas anggota pada tanggal ini tampil di sini.',
    );
  }
}

/// "Hari ini" / "Pekan ini" / "Pilih tanggal": the first two are one-tap
/// presets of the date filter, the last opens the full date sheet and shows
/// the chosen range once active.
class _DateChips extends StatelessWidget {
  const _DateChips({
    required this.isLoading,
    required this.period,
    required this.customLabel,
    required this.onToday,
    required this.onThisWeek,
    required this.onPick,
  });

  final bool isLoading;
  final AppDateFilterPeriod period;
  final String customLabel;
  final VoidCallback onToday;
  final VoidCallback onThisWeek;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final picked =
        period == AppDateFilterPeriod.thisMonth ||
        period == AppDateFilterPeriod.custom;
    Widget chip(String label, {required bool selected, VoidCallback? onTap}) =>
        AppChip(
          type: AppChipType.filter,
          label: label,
          selected: selected,
          onPressed: isLoading ? null : onTap,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          chip(
            AppDateFilterPeriod.today.label,
            selected: period == AppDateFilterPeriod.today,
            onTap: onToday,
          ),
          const SizedBox(width: 6),
          chip(
            AppDateFilterPeriod.thisWeek.label,
            selected: period == AppDateFilterPeriod.thisWeek,
            onTap: onThisWeek,
          ),
          const SizedBox(width: 6),
          chip(
            picked ? customLabel : 'Pilih tanggal',
            selected: picked,
            onTap: onPick,
          ),
        ],
      ),
    );
  }
}
