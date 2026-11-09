import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_filter_bar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_scaffold.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_detail_screen.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_card.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_card_skeleton.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_form_dialog.dart';

/// Layar utama fitur Laporan Insiden.
///
/// Selaras 100% dengan cetak biru GuestScreen, mendukung State Polimorfik,
/// Skeleton loader saat initial loading, Infinite scroll uncontained,
/// Bottom sheet filter tanggal, dan remote search.
class IncidentScreen extends StatefulWidget {
  /// Membuat instance [IncidentScreen].
  const IncidentScreen({super.key, this.cubit});

  /// Instance [IncidentListCubit] opsional untuk injeksi pengujian.
  final IncidentListCubit? cubit;

  /// Route pembuka layar daftar insiden.
  static Route<void> route({IncidentListCubit? cubit}) {
    return MaterialPageRoute<void>(
      builder: (_) => IncidentScreen(cubit: cubit),
    );
  }

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = LoadMoreScrollController(
      onLoadMore: () {
        final session = _resolveSession(context);
        _resolveCubit(context).loadMore(session: session);
      },
    );

    final cubit = _resolveCubit(context);
    final initialQuery = cubit.state.searchQuery ?? '';
    _isSearchExpanded = initialQuery.isNotEmpty;
    _searchController = TextEditingController(text: initialQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final session = _resolveSession(context);
        final currentCubit = _resolveCubit(context);
        final result = await currentCubit.fetchIncidents(session: session);
        if (mounted && !_isRefreshing) {
          if (result == AppFetchResult.cachedFallback) {
            AppFetchFeedback.show(
              context,
              result: result,
              hasData: currentCubit.state.displayedIncidents.isNotEmpty,
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

  IncidentListCubit _resolveCubit(BuildContext context) {
    return widget.cubit ?? context.read<IncidentListCubit>();
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

  void _showFeedback(IncidentListCubit cubit, AppFetchResult result) {
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: cubit.state.displayedIncidents.isNotEmpty,
    );
  }

  Future<void> _handleRefresh(IncidentListCubit cubit) async {
    _isRefreshing = true;
    try {
      final session = _resolveSession(context);
      final query = _searchController.text;
      final result = await cubit.refreshIncidents(
        session: session,
        search: query.isEmpty ? null : query,
      );
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: result,
          hasData: cubit.state.displayedIncidents.isNotEmpty,
          successMessage: 'Laporan insiden berhasil diperbarui.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _onIncidentTapped(IncidentEntity incident) {
    Navigator.of(
      context,
    ).push(IncidentDetailScreen.route(incidentId: incident.id)).then((result) {
      if (!mounted) return;
      if (result is IncidentEntity) {
        _resolveCubit(context).onIncidentUpdated(result);
      } else if (result is String) {
        _resolveCubit(context).onIncidentDeleted(result);
      }
    });
  }

  Future<void> _onOpenCreateForm() async {
    final cubit = _resolveCubit(context);
    await IncidentFormDialog.showCreate(context, incidentListCubit: cubit);
  }

  void _onOpenSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
  }

  void _onCloseSearch() {
    final hasActiveSearch =
        _searchController.text.isNotEmpty ||
        (_resolveCubit(context).state.searchQuery?.isNotEmpty ?? false);
    _searchController.clear();
    setState(() {
      _isSearchExpanded = false;
    });
    if (hasActiveSearch) {
      _onSearch('');
    }
  }

  Future<void> _onSearch(String query) async {
    final session = _resolveSession(context);
    final currentCubit = _resolveCubit(context);
    final result = await currentCubit.fetchIncidents(
      session: session,
      search: query,
    );
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
      final session = _resolveSession(context);
      final fetchResult = await cubit.setDateFilter(result, session: session);
      _showFeedback(cubit, fetchResult);
    }
  }

  Future<void> _onResetDateFilter() async {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    _showFeedback(cubit, await cubit.resetDateFilter(session: session));
  }

  Future<void> _onStatusFilterSelected(IncidentStatus? status) async {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    _showFeedback(cubit, await cubit.setFilter(status, session: session));
  }

  Future<void> _resetAllFilters() async {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    _searchController.clear();
    setState(() {
      _isSearchExpanded = false;
    });
    _showFeedback(cubit, await cubit.resetFilters(session: session));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context, listen: true);
    final connectivityCubit = context.watch<ConnectivityCubit?>();
    final isDeviceOffline =
        connectivityCubit?.state == ConnectivityStatus.offline;

    final consumer = BlocConsumer<IncidentListCubit, IncidentState>(
      bloc: cubit,
      listener: (context, state) {
        if (state is IncidentError) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is IncidentLoaded) {
          final query = state.searchQuery ?? '';
          if (_searchController.text != query) {
            _searchController.text = query;
          }
        }
      },
      builder: (context, state) {
        final isOffline = isDeviceOffline;
        final isInitialLoading =
            state is IncidentInitial || state is IncidentLoading;

        return ListScreenScaffold(
          title: 'Insiden',
          searchLabel: 'Cari insiden',
          refreshLabel: 'Memuat ulang laporan insiden',
          greeting: state.lastSync,
          isInitialLoading: isInitialLoading,
          isOffline: isOffline,
          isSearchExpanded: _isSearchExpanded,
          searchController: _searchController,
          onSearch: _onSearch,
          onOpenSearch: _onOpenSearch,
          onCloseSearch: _onCloseSearch,
          onRefresh: () => _handleRefresh(cubit),
          canRefresh: !_isRefreshing,
          bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
          filterBar: _buildFilterBar(state: state, isLoading: isInitialLoading),
          body: _buildBody(context, state, cubit),
          createLabel: 'Insiden',
          onCreate: IncidentEntity.canBeCreatedBySession(session)
              ? _onOpenCreateForm
              : null,
          canPop: !_isSearchExpanded,
          onPopBlocked: _onCloseSearch,
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
    IncidentState state,
    IncidentListCubit cubit,
  ) {
    final isLoading = state is IncidentInitial || state is IncidentLoading;

    if (isLoading) {
      return ListScreenSkeleton(
        itemBuilder: (_, _) => const IncidentCardSkeleton(),
      );
    } else if (state is IncidentLoaded) {
      if (state.displayedIncidents.isEmpty) {
        if (state.hasActiveFilter) {
          return ListEmptySearchResult(
            noun: 'laporan insiden',
            onReset: _resetAllFilters,
          );
        } else {
          return _buildEmptyGroupState();
        }
      } else {
        return _buildIncidentListView(
          incidents: state.displayedIncidents,
          isLoadingMore: state.isLoadingMore,
        );
      }
    } else if (state is IncidentError) {
      if (state.displayedIncidents.isNotEmpty) {
        return _buildIncidentListView(
          incidents: state.displayedIncidents,
          isLoadingMore: false,
        );
      } else {
        return ListErrorState(
          noun: 'laporan insiden',
          message: state.message,
          onRetry: () {
            final query = _searchController.text;
            final session = _resolveSession(context);
            cubit.fetchIncidents(
              session: session,
              search: query.isEmpty ? null : query,
            );
          },
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFilterBar({
    required IncidentState state,
    required bool isLoading,
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
        // Filter Status Insiden
        AppChip(
          type: AppChipType.filter,
          label: 'Semua',
          selected: state.selectedFilter == null,
          onPressed: isLoading ? null : () => _onStatusFilterSelected(null),
        ),
        AppChip(
          type: AppChipType.filter,
          label: 'Terbuka',
          selected: state.selectedFilter == IncidentStatus.open,
          onPressed: isLoading
              ? null
              : () => _onStatusFilterSelected(IncidentStatus.open),
        ),
        AppChip(
          type: AppChipType.filter,
          label: 'Selesai',
          selected: state.selectedFilter == IncidentStatus.resolved,
          onPressed: isLoading
              ? null
              : () => _onStatusFilterSelected(IncidentStatus.resolved),
        ),
      ],
    );
  }

  Widget _buildIncidentListView({
    required List<IncidentEntity> incidents,
    required bool isLoadingMore,
  }) {
    return ListScreenListView(
      controller: _scrollController,
      itemCount: incidents.length,
      isLoadingMore: isLoadingMore,
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return IncidentCard(
          incident: incident,
          onTap: () => _onIncidentTapped(incident),
        );
      },
    );
  }

  Widget _buildEmptyGroupState() {
    return const AppEmptyState(
      icon: AppSvgIcon.color(KawaloColorVectors.incident1),
      title: 'Belum ada laporan insiden',
      description:
          'Belum ada laporan insiden '
          'pada hari ini.',
    );
  }
}
