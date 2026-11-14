import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

/// Pushes [OperationalDetailScreen], sharing the list's [OperationalCubit] so
/// a refresh here updates the list too.
Future<void> navigateToOperationalDetailScreen(
  BuildContext context, {
  required OperationalItemEntity item,
  OperationalCubit? cubit,
}) {
  final resolvedCubit =
      cubit ??
      (() {
        try {
          return context.read<OperationalCubit>();
        } on Object catch (_) {
          return null;
        }
      })();

  final screen = OperationalDetailScreen(item: item, cubit: resolvedCubit);

  return Navigator.of(context).push<void>(
    AppPageRoute.forwardBackward<void>(
      settings: const RouteSettings(name: AppRouteNames.operationalDetail),
      builder: (_) => resolvedCubit != null
          ? BlocProvider.value(value: resolvedCubit, child: screen)
          : screen,
    ),
  );
}

/// One member's duty day: start and latest state, then every reported
/// activity (newest first, as sent by the server).
class OperationalDetailScreen extends StatefulWidget {
  const OperationalDetailScreen({
    required this.item,
    this.onRefresh,
    this.cubit,
    this.clock = DateTime.now,
    super.key,
  });

  final OperationalItemEntity item;

  /// Test hook replacing the cubit refresh.
  final Future<void> Function()? onRefresh;

  final OperationalCubit? cubit;

  final DateTime Function() clock;

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

  /// Same member and day in a refreshed list, or [target] when it is gone.
  OperationalItemEntity _findOperational(
    List<OperationalItemEntity> list,
    OperationalItemEntity target,
  ) {
    for (final operational in list) {
      final isMatch =
          operational.userEmail == target.userEmail &&
          ((operational.dutyDate != null && target.dutyDate != null)
              ? operational.dutyDate == target.dutyDate
              : operational.latestDutyDt == target.latestDutyDt);
      if (isMatch) return operational;
    }
    return target;
  }

  Future<void> _handleRefresh() async {
    final onRefresh = widget.onRefresh;
    final cubit = _resolveCubit(context);
    if (onRefresh != null) {
      await onRefresh();
    } else if (cubit != null) {
      await cubit.refreshOperationals();
      final state = cubit.state;
      if (!mounted || state is! OperationalLoaded) return;
      setState(() => _item = _findOperational(state.operationals, _item));
    } else {
      return;
    }
    if (mounted) {
      AppSnackbar.show(
        context,
        message: 'Aktivitas operasional berhasil diperbarui.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    if (cubit == null) return _buildScaffold(_item);
    return BlocBuilder<OperationalCubit, OperationalState>(
      bloc: cubit,
      builder: (context, state) => _buildScaffold(
        state is OperationalLoaded
            ? _findOperational(state.operationals, _item)
            : _item,
      ),
    );
  }

  Widget _buildScaffold(OperationalItemEntity item) {
    final tones = KawaloTones.of(context);
    final isOffline =
        context.watch<ConnectivityCubit?>()?.state ==
        ConnectivityStatus.offline;
    final now = widget.clock();

    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppBar(
        backgroundColor: tones.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.displayUserName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tones.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              item.displayLatestDuty,
              style: TextStyle(
                color: tones.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
      body: SafeArea(
        top: false,
        child: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang detail aktivitas operasional',
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryBox(item: item, now: now),
                      const SizedBox(height: 14),
                      Semantics(
                        header: true,
                        child: Text(
                          (_isToday(item.dutyDate, now)
                                  ? 'Riwayat hari ini'
                                  : 'Riwayat aktivitas')
                              .toUpperCase(),
                          style: TextStyle(
                            color: tones.ink2,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.84,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item.timeline.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Belum ada riwayat aktivitas dinas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: tones.ink2, fontSize: 15),
                          ),
                        )
                      else
                        for (final (i, entry) in item.timeline.indexed) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _TimelineRow(
                            entry: entry,
                            isLatest: i == 0,
                            now: now,
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [dutyDate] is "YYYY-MM-DD"; without it the day is unknown.
  static bool _isToday(String? dutyDate, DateTime now) {
    final date = dutyDate == null ? null : DateTime.tryParse(dutyDate);
    return date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.item, required this.now});

  final OperationalItemEntity item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);

    Widget kv(String key, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(key, style: TextStyle(color: tones.ink2, fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.monoFigures.copyWith(
                color: tones.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tones.line),
      ),
      child: Column(
        children: [
          kv('Mulai dinas', compactDutyTime(item.firstActivityDt, now)),
          kv('Status terkini', item.displayLatestStateLine(now)),
          kv('Total aktivitas', item.displayTotalActivities),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLatest,
    required this.now,
  });

  final DutyTimelineEntity entry;
  final bool isLatest;
  final DateTime now;

  Future<void> _copyId(BuildContext context, String uid) async {
    await Clipboard.setData(ClipboardData(text: uid));
    if (context.mounted) {
      AppSnackbar.show(context, message: 'ID aktivitas disalin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final uid = entry.journeyUid?.trim() ?? '';
    final time = entry.displayClock(now);

    return Semantics(
      label: '${entry.displayState}, ${entry.displayDuty}, $time',
      hint: uid.isEmpty ? null : 'Tekan lama untuk menyalin ID aktivitas',
      excludeSemantics: true,
      child: Material(
        color: tones.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tones.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: uid.isEmpty ? null : () => _copyId(context, uid),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLatest ? tones.pat.soft : tones.surface2,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: isLatest ? tones.pat.color : tones.ink2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayState,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppStatusPill(
                        label: entry.displayDuty,
                        kind: entry.isOnDuty
                            ? AppStatusKind.ok
                            : AppStatusKind.neutral,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: AppTheme.monoFigures.copyWith(
                    color: tones.ink2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
