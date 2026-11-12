import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/forecast/forecast_module.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_cubit.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_state.dart';
import 'package:kawalo_mobile/features/forecast/presentation/widgets/forecast_config_view.dart';
import 'package:kawalo_mobile/features/forecast/presentation/widgets/forecast_preview_view.dart';
import 'package:kawalo_mobile/features/forecast/presentation/widgets/forecast_status_views.dart';

/// Admin tool that generates a schedule for a date range: configure, preview,
/// save. Only the ADMIN and SUPER_ADMIN roles may use it; the API enforces the
/// same rule.
class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key, this.cubit});

  static const String routeName = AppRouteNames.forecast;

  /// Test injection; defaults to the [ForecastCubit] of the widget tree.
  final ForecastCubit? cubit;

  /// Needs a [ForecastModule] and a [UserSessionCubit] above the navigator.
  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: routeName),
    builder: (context) => BlocProvider<ForecastCubit>(
      create: (context) => context.read<ForecastModule>().createCubit(),
      child: const ForecastScreen(),
    ),
  );

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  ForecastCubit get _cubit => widget.cubit ?? context.read<ForecastCubit>();

  bool get _isAdmin =>
      context.read<UserSessionCubit>().state?.isAdminRole ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isAdmin) unawaited(_cubit.load());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.of(context).colorScheme.surface,
        appBar: const AppHomeAppBar(
          title: 'Forecast Jadwal',
          showBackButton: true,
          showTrailing: false,
        ),
        body: const AppEmptyState(
          icon: Icon(Icons.lock_outline, size: 64),
          title: 'Khusus admin',
          description: 'Hanya admin grup yang dapat membuat forecast jadwal.',
        ),
      );
    }

    final cubit = _cubit;
    return BlocBuilder<ForecastCubit, ForecastState>(
      bloc: cubit,
      builder: (context, state) {
        // Back from the preview steps returns to the form instead of leaving
        // the screen, so the admin never loses the values typed in.
        final leavesScreen =
            state is! ForecastReady ||
            state is ForecastConfiguring ||
            state is ForecastApplied;
        return PopScope(
          canPop: leavesScreen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.backToConfig();
          },
          child: Scaffold(
            backgroundColor: AppTheme.of(context).colorScheme.surface,
            appBar: AppHomeAppBar(
              greeting: _caption(state),
              reserveGreetingSpace: true,
              title:
                  state is ForecastPreviewLoading ||
                      state is ForecastPreviewReady ||
                      state is ForecastStale
                  ? 'Pratinjau Forecast'
                  : 'Forecast Jadwal',
              showBackButton: true,
              showTrailing: false,
            ),
            body: SafeArea(top: false, child: _body(state, cubit)),
          ),
        );
      },
    );
  }

  static String? _caption(ForecastState state) => switch (state) {
    ForecastConfiguring() => 'Langkah 1 dari 2 · Pengaturan',
    ForecastPreviewLoading() => 'Langkah 2 dari 2 · Membuat pratinjau',
    ForecastPreviewReady() => 'Langkah 2 dari 2 · Periksa hasil',
    ForecastStale() => 'Langkah 2 dari 2 · Gagal menyimpan',
    ForecastApplied() => 'Selesai',
    ForecastLoading() || ForecastLoadError() => null,
  };

  Widget _body(ForecastState state, ForecastCubit cubit) => switch (state) {
    ForecastLoading() => const Center(
      child: AppLoadingIndicator(semanticLabel: 'Memuat data forecast'),
    ),
    ForecastLoadError(:final message) => ListErrorState(
      noun: 'data forecast',
      message: message,
      onRetry: () => unawaited(cubit.load()),
    ),
    final ForecastConfiguring s => ForecastConfigView(state: s, cubit: cubit),
    final ForecastPreviewLoading s => ForecastPreviewLoadingView(state: s),
    final ForecastPreviewReady s => Stack(
      children: [
        ForecastPreviewView(state: s, cubit: cubit),
        if (s.applying)
          AppLoadingOverlay(
            message: 'Menyimpan ${s.preview.stats.totalCreated} jadwal',
            semanticLabel: 'Menyimpan jadwal',
          ),
      ],
    ),
    final ForecastStale s => ForecastStaleView(
      state: s,
      onRetry: () => unawaited(cubit.retryPreview()),
      onEdit: cubit.backToConfig,
    ),
    final ForecastApplied s => ForecastSuccessView(
      state: s,
      onDone: () => Navigator.of(context).maybePop(),
    ),
  };
}
