import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/presentation/widgets/schedule_card.dart';
import 'package:kawalo_mobile/features/schedule/presentation/widgets/schedule_card_skeleton.dart';

/// Work schedule of the signed-in user for the next 30 days, grouped by day.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.cubit, this.clock = DateTime.now});

  /// Test injection; defaults to the [ScheduleCubit] of the widget tree.
  final ScheduleCubit? cubit;

  final DateTime Function() clock;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.schedule),
    builder: (_) => const ScheduleScreen(),
  );

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  ScheduleCubit get _cubit => widget.cubit ?? context.read<ScheduleCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_cubit.fetch());
    });
  }

  Future<void> _refresh() async {
    final ok = await _cubit.fetch(silent: true);
    if (!ok && mounted && _cubit.state is ScheduleLoaded) {
      AppSnackbar.show(context, message: 'Gagal memperbarui jadwal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    return Scaffold(
      backgroundColor: AppTheme.of(context).colorScheme.surface,
      appBar: const AppHomeAppBar(
        title: 'Jadwal Kerja',
        showBackButton: true,
        showTrailing: false,
      ),
      body: SafeArea(
        top: false,
        child: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang jadwal kerja',
          onRefresh: _refresh,
          child: BlocBuilder<ScheduleCubit, ScheduleState>(
            bloc: cubit,
            builder: (context, state) => switch (state) {
              ScheduleInitial() || ScheduleLoading() => ListScreenSkeleton(
                bottomPadding: AppSpacing.space300,
                itemBuilder: (_, _) => const ScheduleCardSkeleton(),
              ),
              ScheduleError(:final message) => ListErrorState(
                noun: 'jadwal kerja',
                message: message,
                onRetry: () => unawaited(cubit.fetch()),
              ),
              ScheduleLoaded(:final schedules) when schedules.isEmpty =>
                const AppEmptyState(
                  icon: AppSvgIcon.color(
                    KawaloColorVectors.calendar2,
                    size: 64,
                  ),
                  title: 'Belum ada jadwal',
                  description:
                      'Belum ada jadwal kerja untuk Anda dalam 30 hari ke '
                      'depan.',
                ),
              ScheduleLoaded(:final schedules) => _ScheduleList(
                schedules: schedules,
                now: widget.clock(),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.schedules, required this.now});

  final List<ScheduleEntity> schedules;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final children = <Widget>[];
    DateTime? currentDay;
    for (final schedule in schedules) {
      if (currentDay != schedule.date) {
        currentDay = schedule.date;
        final relative = relativeDayLabel(schedule.date, now);
        final date = AppDateFormat.formatWeekdayDate(schedule.date);
        children
          ..add(children.isEmpty ? AppSpacing.vGapSm : AppSpacing.vGap200)
          ..add(
            Semantics(
              header: true,
              child: Text(
                relative == null ? date : '$relative · $date',
                style: theme.typography.emphasized.titleSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          )
          ..add(AppSpacing.vGapSm);
      } else {
        children.add(AppSpacing.vGapSm);
      }
      children.add(ScheduleCard(schedule: schedule));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space200,
        AppSpacing.space100,
        AppSpacing.space200,
        AppSpacing.space300,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
