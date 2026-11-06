import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_app_bar.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_profile_card.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_summary_card.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_timeline_card.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_top_meta.dart';

/// Melakukan navigasi ke layar detail operasional personil menggunakan rute
/// standar Material 3 Expressive [AppPageRoute.forwardBackward].
Future<void> navigateToOperationalDetailScreen(
  BuildContext context, {
  required OperationalItemEntity item,
  OperationalCubit? cubit,
}) {
  final resolvedCubit = cubit ??
      (() {
        try {
          return context.read<OperationalCubit>();
        } on Object catch (_) {
          return null;
        }
      })();

  final screen = OperationalDetailScreen(
    item: item,
    cubit: resolvedCubit,
  );

  return Navigator.of(context).push<void>(
    AppPageRoute.forwardBackward<void>(
      builder: (_) => resolvedCubit != null
          ? BlocProvider.value(
              value: resolvedCubit,
              child: screen,
            )
          : screen,
    ),
  );
}

/// Tampilan layar penuh untuk detail riwayat dan linimasa tugas personil.
class OperationalDetailScreen extends StatefulWidget {
  /// Membuat instance [OperationalDetailScreen].
  const OperationalDetailScreen({
    required this.item,
    this.onRefresh,
    this.cubit,
    super.key,
  });

  /// Data personil operasional yang ditampilkan.
  final OperationalItemEntity item;

  /// Callback opsional saat swipe refresh.
  final Future<void> Function()? onRefresh;

  /// Cubit opsional untuk manajemen aktifitas operasional.
  final OperationalCubit? cubit;

  @override
  State<OperationalDetailScreen> createState() =>
      _OperationalDetailScreenState();
}

class _OperationalDetailScreenState extends State<OperationalDetailScreen> {
  late OperationalItemEntity _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = _resolveCubit(context);
        if (cubit != null && cubit.state is OperationalLoaded) {
          final loaded = cubit.state as OperationalLoaded;
          final updated = _findOperational(loaded.operationals, _item);
          if (updated != _item) {
            setState(() {
              _item = updated;
            });
          }
        }
      }
    });
  }

  @override
  void didUpdateWidget(OperationalDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item != oldWidget.item) {
      _item = widget.item;
    }
  }

  OperationalCubit? _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit;
    try {
      return context.read<OperationalCubit>();
    } on Object catch (_) {
      return null;
    }
  }

  bool _resolveIsOffline(BuildContext context) {
    try {
      final connectivityCubit = context.watch<ConnectivityCubit?>();
      return connectivityCubit?.state == ConnectivityStatus.offline;
    } on Object catch (_) {
      return false;
    }
  }

  OperationalItemEntity _findOperational(
    List<OperationalItemEntity> list,
    OperationalItemEntity target,
  ) {
    for (final operational in list) {
      final isMatch = operational.userEmail == target.userEmail &&
          ((operational.dutyDate != null && target.dutyDate != null)
              ? operational.dutyDate == target.dutyDate
              : operational.latestDutyDt == target.latestDutyDt);
      if (isMatch) return operational;
    }
    return target;
  }

  Future<void> _handleRefresh() async {
    final cubit = _resolveCubit(context);
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Aktifitas operasional berhasil diperbarui.',
        );
      }
      return;
    }

    if (cubit != null) {
      await cubit.refreshOperationals();
      if (mounted) {
        if (cubit.state is OperationalLoaded) {
          final loadedState = cubit.state as OperationalLoaded;
          final updated = _findOperational(loadedState.operationals, _item);
          setState(() {
            _item = updated;
          });
          AppSnackbar.show(
            context,
            message: 'Aktifitas operasional berhasil diperbarui.',
          );
        }
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      AppSnackbar.show(
        context,
        message: 'Aktifitas operasional berhasil diperbarui.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = _resolveCubit(context);

    Widget buildScaffold({
      required OperationalItemEntity currentItem,
      required String greeting,
    }) {
      final isOffline = _resolveIsOffline(context);

      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: OperationalDetailAppBar(
          greeting: greeting,
        ),
        bottomNavigationBar: AppBottomOfflineBanner(
          isOffline: isOffline,
        ),
        body: SafeArea(
          top: false,
          child: AppRefreshIndicator.contained(
            semanticsLabel: 'Memuat ulang detail aktifitas operasional',
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: AppSpacing.space200,
                right: AppSpacing.space200,
                top: AppSpacing.space150,
                bottom: AppSpacing.space200,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Meta Atas (Nama Grup) ─────────────────────────────
                      OperationalDetailTopMeta(item: currentItem),

                      AppSpacing.vGap200,

                      OperationalDetailProfileCard(item: currentItem),
                      AppSpacing.vGap200,
                      OperationalDetailSummaryCard(item: currentItem),
                      AppSpacing.vGap200,
                      OperationalDetailTimelineCard(item: currentItem),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (cubit != null) {
      return BlocConsumer<OperationalCubit, OperationalState>(
        bloc: cubit,
        listener: (context, state) {
          if (state is OperationalLoaded) {
            final updated = _findOperational(state.operationals, _item);
            if (updated != _item) {
              setState(() {
                _item = updated;
              });
            }
          }
        },
        builder: (context, state) {
          final effectiveItem = state is OperationalLoaded
              ? _findOperational(state.operationals, _item)
              : _item;
          final effectiveGreeting = state.lastSync.isNotEmpty
              ? state.lastSync
              : (cubit.currentGreeting.isNotEmpty
                  ? cubit.currentGreeting
                  : AppDateFormat.formatGreeting(DateTime.now()));
          return buildScaffold(
            currentItem: effectiveItem,
            greeting: effectiveGreeting,
          );
        },
      );
    }

    return buildScaffold(
      currentItem: _item,
      greeting: AppDateFormat.formatGreeting(DateTime.now()),
    );
  }
}
