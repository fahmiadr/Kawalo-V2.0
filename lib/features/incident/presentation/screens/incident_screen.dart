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
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
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
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

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
    _scrollController.removeListener(_onScroll);
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.85) {
      final session = _resolveSession(context);
      _resolveCubit(context).loadMore(session: session);
    }
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
    if (!mounted) return;
    AppFetchFeedback.show(
      context,
      result: result,
      hasData: currentCubit.state.displayedIncidents.isNotEmpty,
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
      final session = _resolveSession(context);
      final fetchResult = await cubit.setDateFilter(result, session: session);
      if (mounted) {
        AppFetchFeedback.show(
          context,
          result: fetchResult,
          hasData: cubit.state.displayedIncidents.isNotEmpty,
        );
      }
    }
  }

  Future<void> _onResetDateFilter() async {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final fetchResult = await cubit.resetDateFilter(session: session);
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedIncidents.isNotEmpty,
      );
    }
  }

  Future<void> _onStatusFilterSelected(IncidentStatus? status) async {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    final fetchResult = await cubit.setFilter(status, session: session);
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedIncidents.isNotEmpty,
      );
    }
  }

  Future<void> _resetAllFilters() async {
    final cubit = _resolveCubit(context);
    final session = _resolveSession(context);
    _searchController.clear();
    setState(() {
      _isSearchExpanded = false;
    });
    final fetchResult = await cubit.resetFilters(session: session);
    if (mounted) {
      AppFetchFeedback.show(
        context,
        result: fetchResult,
        hasData: cubit.state.displayedIncidents.isNotEmpty,
      );
    }
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
        final greeting = state.lastSync;
        final isOffline = isDeviceOffline;
        final currentIncidents = state.displayedIncidents;
        final isInitialLoading =
            state is IncidentInitial || state is IncidentLoading;

        return _buildScaffold(
          context: context,
          greeting: greeting,
          cubit: cubit,
          session: session,
          currentIncidents: currentIncidents,
          isOffline: isOffline,
          isInitialLoading: isInitialLoading,
          filterBar: _buildFilterBar(
            context: context,
            state: state,
            isLoading: isInitialLoading,
            session: session,
          ),
          bodyContent: _buildBody(context, state, cubit, session),
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
    AuthSessionEntity? session,
  ) {
    final isLoading = state is IncidentInitial || state is IncidentLoading;

    if (isLoading) {
      return _buildLoadingSkeleton();
    } else if (state is IncidentLoaded) {
      if (state.displayedIncidents.isEmpty) {
        if (state.hasActiveFilter) {
          return _buildEmptySearchResult(context);
        } else {
          return _buildEmptyGroupState(context);
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
        return _buildErrorState(context, state.message, cubit);
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFilterBar({
    required BuildContext context,
    required IncidentState state,
    required bool isLoading,
    required AuthSessionEntity? session,
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
            // Chip Filter Tanggal
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

            // Filter Status Insiden
            AppChip(
              type: AppChipType.filter,
              label: 'Semua',
              selected: state.selectedFilter == null,
              onPressed: isLoading ? null : () => _onStatusFilterSelected(null),
            ),
            AppSpacing.hGapSm,
            AppChip(
              type: AppChipType.filter,
              label: 'Terbuka',
              selected: state.selectedFilter == IncidentStatus.open,
              onPressed: isLoading
                  ? null
                  : () => _onStatusFilterSelected(IncidentStatus.open),
            ),
            AppSpacing.hGapSm,
            AppChip(
              type: AppChipType.filter,
              label: 'Selesai',
              selected: state.selectedFilter == IncidentStatus.resolved,
              onPressed: isLoading
                  ? null
                  : () => _onStatusFilterSelected(IncidentStatus.resolved),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required String greeting,
    required IncidentListCubit cubit,
    required AuthSessionEntity? session,
    required List<IncidentEntity> currentIncidents,
    required Widget filterBar,
    required Widget bodyContent,
    bool isOffline = false,
    bool isInitialLoading = false,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final canCreate = IncidentEntity.canBeCreatedBySession(session);

    return PopScope(
      canPop: !_isSearchExpanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearchExpanded) {
          _onCloseSearch();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colorScheme.surface,
        floatingActionButtonLocation: const AppStationaryEndFloatFabLocation(),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        appBar: AppHomeAppBar(
          greeting: greeting,
          reserveGreetingSpace: true,
          greetingLoading: isInitialLoading && greeting.isEmpty,
          title: _isSearchExpanded ? null : 'Insiden',
          titleWidget: _isSearchExpanded
              ? AppSearchBar(
                  controller: _searchController,
                  hintText: 'Cari insiden',
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
            semanticLabel: _isSearchExpanded
                ? 'Tutup pencarian'
                : 'Cari insiden',
            icon: AppSvgIcon(
              _isSearchExpanded
                  ? KawaloVectors.cancel01
                  : KawaloVectors.search01,
              size: 24,
              color: !isInitialLoading
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(
                      alpha: AppStateLayer.disabledOpacity,
                    ),
            ),
          ),
        ),
        floatingActionButton: !canCreate
            ? null
            : AppExtendedFab(
                onPressed: isOffline ? null : _onOpenCreateForm,
                icon: const AppSvgIcon(KawaloVectors.add01, size: 24),
                label: 'Insiden',
              ),
        bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
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
                    semanticsLabel: 'Memuat ulang laporan insiden',
                    notificationPredicate: _isRefreshing
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
      separatorBuilder: (_, _) => AppSpacing.vGap200,
      itemBuilder: (_, _) => const IncidentCardSkeleton(),
    );
  }

  Widget _buildIncidentListView({
    required List<IncidentEntity> incidents,
    required bool isLoadingMore,
  }) {
    final totalCount = incidents.length + (isLoadingMore ? 1 : 0);

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
      separatorBuilder: (_, _) => AppSpacing.vGap200,
      itemBuilder: (context, index) {
        if (index == incidents.length) {
          return const Padding(
            padding: AppSpacing.paddingVertical200,
            child: Center(child: AppLoadingIndicator()),
          );
        }

        final incident = incidents[index];
        return IncidentCard(
          incident: incident,
          onTap: () => _onIncidentTapped(incident),
        );
      },
    );
  }

  Widget _buildEmptyGroupState(BuildContext context) {
    return const AppEmptyState(
      icon: AppSvgIcon.color(KawaloColorVectors.incident1),
      title: 'Belum ada laporan insiden',
      description:
          'Belum ada laporan insiden '
          'pada hari ini.',
    );
  }

  Widget _buildEmptySearchResult(BuildContext context) {
    return AppEmptyState.search(
      title: 'Laporan insiden tidak ditemukan',
      description:
          'Tidak ada laporan insiden yang cocok dengan '
          'pencarian atau filter yang diterapkan.',
      actionLabel: 'Reset filter & pencarian',
      onActionPressed: _resetAllFilters,
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    IncidentListCubit cubit,
  ) {
    return AppEmptyState.error(
      title: 'Gagal memuat laporan insiden',
      description: message,
      retryLabel: 'Coba lagi',
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
}
