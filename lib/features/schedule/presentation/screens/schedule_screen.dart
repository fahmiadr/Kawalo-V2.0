import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/presentation/widgets/schedule_card.dart';
import 'package:kawalo_mobile/features/schedule/presentation/widgets/schedule_card_skeleton.dart';

/// "Jadwal Saya": the signed-in user's shifts for the next 30 days under a
/// strip of the current week.
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
    final tones = KawaloTones.of(context);
    final now = widget.clock();
    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppTopBar(
        title: 'Jadwal Saya',
        subtitle: scheduleMonthLabel(now),
      ),
      body: SafeArea(
        top: false,
        child: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang jadwal saya',
          onRefresh: _refresh,
          child: BlocBuilder<ScheduleCubit, ScheduleState>(
            bloc: cubit,
            builder: (context, state) => switch (state) {
              ScheduleInitial() || ScheduleLoading() => ListScreenSkeleton(
                bottomPadding: 24,
                itemBuilder: (_, _) => const ScheduleCardSkeleton(),
              ),
              ScheduleError(:final message) => ListErrorState(
                noun: 'jadwal',
                message: message,
                onRetry: () => unawaited(cubit.fetch()),
              ),
              ScheduleLoaded(:final schedules) when schedules.isEmpty => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: _WeekStrip(now: now, schedules: schedules),
                  ),
                  Expanded(
                    child: AppEmptyState(
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        size: 64,
                        color: tones.pat.color,
                      ),
                      title: 'Belum ada jadwal',
                      description:
                          'Jadwal 30 hari ke depan dari admin tampil di '
                          'sini.',
                    ),
                  ),
                ],
              ),
              ScheduleLoaded(:final schedules) => _ScheduleList(
                schedules: schedules,
                now: now,
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// Monday to Sunday of the week containing [now]; a dot marks days with a
/// loaded shift.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.now, required this.schedules});

  final DateTime now;
  final List<ScheduleEntity> schedules;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];
    final scheduled = {for (final s in schedules) s.date};

    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _WeekDay(
                day: day,
                isToday: relativeDayLabel(day, now) == 'Hari ini',
                hasShift: scheduled.contains(day),
                tones: tones,
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.day,
    required this.isToday,
    required this.hasShift,
    required this.tones,
  });

  final DateTime day;
  final bool isToday;
  final bool hasShift;
  final KawaloTones tones;

  @override
  Widget build(BuildContext context) {
    final name = scheduleWeekdayShort[day.weekday - 1];
    final fg = isToday ? tones.pat.on : tones.ink2;
    return Semantics(
      container: true,
      label:
          '$name ${day.day}${isToday ? ', hari ini' : ''}'
          '${hasShift ? ', ada jadwal' : ''}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        decoration: BoxDecoration(
          color: isToday ? tones.pat.color : tones.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? tones.pat.on : tones.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: hasShift
                    ? (isToday ? tones.pat.on : tones.pat.color)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
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
    return ListView(
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
                _WeekStrip(now: now, schedules: schedules),
                for (final schedule in schedules) ...[
                  const SizedBox(height: 8),
                  ScheduleCard(schedule: schedule, now: now),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
