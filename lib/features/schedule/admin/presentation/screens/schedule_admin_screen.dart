import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/group/presentation/group_member_filter_options.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_state.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/extensions/managed_schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/screens/schedule_admin_day_screen.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/screens/schedule_form_screen.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_admin_calendar.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_person_row.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/presentation/widgets/schedule_card_skeleton.dart';
import 'package:kawalo_mobile/features/schedule/schedule_module.dart';

/// Group schedule for admins: month calendar with the shifts of the selected
/// day below it. Only `ADMIN`/`SUPER_ADMIN` see the actions that change data.
class ScheduleAdminScreen extends StatefulWidget {
  const ScheduleAdminScreen({
    super.key,
    this.cubit,
    this.formCubitFactory,
    this.onForecast,
  });

  /// Test injection; defaults to the [ScheduleAdminCubit] of the widget tree.
  final ScheduleAdminCubit? cubit;

  /// Test injection; defaults to [ScheduleModule.createFormCubit].
  final ScheduleFormCubit Function(BuildContext)? formCubitFactory;

  /// Opens the forecast flow. The "Forecast" action is hidden without it; the
  /// calendar reloads when the returned future completes.
  final Future<void> Function(BuildContext context)? onForecast;

  static const String routeName = AppRouteNames.scheduleAdmin;

  static Route<void> route({
    Future<void> Function(BuildContext context)? onForecast,
  }) => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: routeName),
    builder: (context) => BlocProvider<ScheduleAdminCubit>(
      create: (context) => context.read<ScheduleModule>().createAdminCubit(),
      child: ScheduleAdminScreen(onForecast: onForecast),
    ),
  );

  @override
  State<ScheduleAdminScreen> createState() => _ScheduleAdminScreenState();
}

class _ScheduleAdminScreenState extends State<ScheduleAdminScreen> {
  ScheduleAdminCubit get _cubit =>
      widget.cubit ?? context.read<ScheduleAdminCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_cubit.load());
    });
  }

  Future<void> _refresh() async {
    final ok = await _cubit.load(silent: true);
    if (!ok && mounted && _cubit.state.status == ScheduleAdminStatus.loaded) {
      AppSnackbar.show(context, message: 'Gagal memperbarui jadwal.');
    }
  }

  Future<void> _openForm({DateTime? initialDate}) async {
    final cubit = _cubit;
    final saved = await Navigator.of(context).push<DateTime>(
      ScheduleFormScreen.route(
        initialDate: initialDate ?? cubit.state.selectedDay,
        today: cubit.today,
        cubitFactory: widget.formCubitFactory,
      ),
    );
    if (saved != null) unawaited(cubit.reveal(saved));
  }

  Future<void> _openForecast() async {
    await widget.onForecast!(context);
    if (mounted) unawaited(_cubit.load(silent: true));
  }

  void _openDay(bool canManage) {
    final cubit = _cubit;
    Navigator.of(context).push<void>(
      ScheduleAdminDayScreen.route(
        cubit: cubit,
        day: cubit.state.selectedDay,
        canManage: canManage,
        formCubitFactory: widget.formCubitFactory,
      ),
    );
  }

  Future<void> _pickPerson() async {
    final cubit = _cubit;
    final module = context.read<ScheduleModule>();
    final result = await showAppUserFilterBottomSheet(
      context: context,
      onLoadUsers: () =>
          loadGroupMemberFilterOptions(module.groupRepository.getMembers),
      selectedEmail: cubit.state.filterEmail,
    );
    if (result == null) return;
    unawaited(
      cubit.setPersonFilter(
        email: result.selectedUser?.email,
        name: result.selectedUser?.displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final session = context.watch<UserSessionCubit>().state;
    final canManage = session?.isAdminRole ?? false;

    final tones = KawaloTones.of(context);

    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppTopBar(
        title: 'Jadwal Tim',
        actions: [
          BlocBuilder<ScheduleAdminCubit, ScheduleAdminState>(
            bloc: cubit,
            buildWhen: (a, b) => a.filterEmail != b.filterEmail,
            builder: (context, state) => AppIconButton(
              semanticLabel: state.filterEmail == null
                  ? 'Filter personil'
                  : 'Filter personil aktif: ${state.filterName}',
              isSelected: state.filterEmail != null,
              onPressed: _pickPerson,
              icon: const AppSvgIcon(KawaloVectors.listFilter, size: 24),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: canManage
          ? AppTaskFooter(
              children: [
                AppTaskButton(
                  label: 'Tambah Jadwal',
                  icon: Icons.add_rounded,
                  tone: tones.adm,
                  onPressed: () => unawaited(_openForm()),
                ),
                if (widget.onForecast != null)
                  AppTaskButton(
                    label: 'Forecast Otomatis',
                    icon: Icons.auto_fix_high_rounded,
                    variant: AppTaskButtonVariant.secondary,
                    size: AppTaskButtonSize.medium,
                    onPressed: () => unawaited(_openForecast()),
                  ),
              ],
            )
          : null,
      body: SafeArea(
        top: false,
        child: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang jadwal grup',
          onRefresh: _refresh,
          child: BlocBuilder<ScheduleAdminCubit, ScheduleAdminState>(
            bloc: cubit,
            builder: (context, state) => _Body(
              state: state,
              today: cubit.today,
              canManage: canManage,
              onPreviousMonth: () => unawaited(
                cubit.goToMonth(
                  DateTime(state.month.year, state.month.month - 1),
                ),
              ),
              onNextMonth: () => unawaited(
                cubit.goToMonth(
                  DateTime(state.month.year, state.month.month + 1),
                ),
              ),
              onToday: () => unawaited(cubit.goToToday()),
              onSelectDay: (d) => unawaited(cubit.selectDay(d)),
              onClearFilter: () => unawaited(cubit.setPersonFilter()),
              onRetry: () => unawaited(cubit.load()),
              hasForecast: widget.onForecast != null,
              onOpenDay: () => _openDay(canManage),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty and error states scroll on their own and need a bounded height, which
/// the surrounding list does not give.
const _stateHeight = 360.0;

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.today,
    required this.canManage,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDay,
    required this.onClearFilter,
    required this.onRetry,
    required this.hasForecast,
    required this.onOpenDay,
  });

  final ScheduleAdminState state;
  final DateTime today;
  final bool canManage;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onClearFilter;
  final VoidCallback onRetry;
  final bool hasForecast;
  final VoidCallback onOpenDay;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final loaded = state.status == ScheduleAdminStatus.loaded;

    final children = <Widget>[
      ScheduleAdminCalendar(
        state: state,
        today: today,
        onPreviousMonth: onPreviousMonth,
        onNextMonth: onNextMonth,
        onToday: onToday,
        onSelectDay: onSelectDay,
      ),
      AppSpacing.vGapSm,
      if (state.filterEmail != null) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: AppChip(
            label: 'Personil: ${state.filterName ?? state.filterEmail}',
            type: AppChipType.input,
            onDeleted: onClearFilter,
          ),
        ),
        AppSpacing.vGapSm,
      ],
      if (loaded) ..._legend(context),
      AppSpacing.vGapSm,
      ..._agenda(context),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space200,
        AppSpacing.space100,
        AppSpacing.space200,
        AppSpacing.space200,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: colorScheme.onSurface),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _legend(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final shifts = <String?, ShiftGroup>{
      for (final g in groupByShift(state.items)) g.shiftUid: g,
    };
    final style = theme.typeScale.labelSmall.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    return [
      Wrap(
        spacing: AppSpacing.space200,
        runSpacing: AppSpacing.space50,
        children: [
          for (final g in shifts.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShiftMarker(color: g.first.shiftAccentColor),
                AppSpacing.hGap50,
                Text(g.first.shiftLabel, style: style),
              ],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                KawaloVectors.locked,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              AppSpacing.hGap50,
              Text('Hari lampau terkunci', style: style),
            ],
          ),
        ],
      ),
    ];
  }

  List<Widget> _agenda(BuildContext context) {
    switch (state.status) {
      case ScheduleAdminStatus.loading:
        return [
          for (var i = 0; i < 3; i++) ...[
            const ScheduleCardSkeleton(),
            AppSpacing.vGapSm,
          ],
        ];
      case ScheduleAdminStatus.error:
        return [
          SizedBox(
            height: _stateHeight,
            child: ListErrorState(
              noun: 'jadwal',
              message: state.message ?? 'Terjadi kesalahan.',
              onRetry: onRetry,
            ),
          ),
        ];
      case ScheduleAdminStatus.loaded:
        break;
    }

    final monthHasItems = state.items.any(
      (e) => e.date.month == state.month.month,
    );
    if (!monthHasItems && state.filterEmail == null) {
      return [
        SizedBox(
          height: _stateHeight,
          child: AppEmptyState(
            icon: const AppSvgIcon.color(
              KawaloColorVectors.calendar2,
              size: 56,
            ),
            title: 'Belum ada jadwal di bulan ini',
            description: canManage
                ? 'Tambah jadwal satu per satu'
                      '${hasForecast ? ', atau buat otomatis untuk beberapa hari sekaligus dengan Forecast' : ''}.'
                : 'Jadwal grup belum dibuat.',
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space300),
          ),
        ),
      ];
    }

    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final day = state.selectedDay;
    final items = state.itemsOn(day);
    final relative = relativeDayLabel(day, today);
    final tones = KawaloTones.of(context);
    return [
      if (day.isBefore(today)) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: tones.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: tones.ink2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hari lampau terkunci dan tidak bisa diubah.',
                  style: TextStyle(
                    color: tones.ink2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapSm,
      ],
      Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                AppDateFormat.formatWeekdayDate(day),
                style: theme.typography.emphasized.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (relative != null) ...[
            AppTag(label: relative, size: AppTagSize.small),
            AppSpacing.hGapSm,
          ],
          Text(
            '${items.length} jadwal',
            style: theme.typeScale.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      AppSpacing.vGapSm,
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space200),
          child: Text(
            'Belum ada jadwal pada hari ini.',
            textAlign: TextAlign.center,
            style: theme.typeScale.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        )
      else
        for (final group in groupByShift(items)) ...[
          _ShiftSummaryCard(group: group, onTap: onOpenDay),
          AppSpacing.vGapSm,
        ],
    ];
  }
}

/// One shift of the selected day: marker, name and time, then the avatars of
/// the people on it (`.box` in the redesign). Opens the day screen.
class _ShiftSummaryCard extends StatelessWidget {
  const _ShiftSummaryCard({required this.group, required this.onTap});

  /// Avatars beyond this collapse into the "N orang" count.
  static const _maxAvatars = 5;

  final ShiftGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final first = group.first;
    final names = group.rows.map((e) => e.displayName).join(', ');
    final timeRange = first.timeRange;
    return Semantics(
      button: true,
      label: '${first.shiftLabel}, ${group.rows.length} orang: $names',
      excludeSemantics: true,
      child: Material(
        color: tones.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tones.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShiftMarker(color: first.shiftAccentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        first.shiftLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (timeRange != null)
                      Text(
                        timeRange,
                        style: AppTheme.monoFigures.copyWith(
                          color: tones.ink2,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final e in group.rows.take(_maxAvatars)) ...[
                      AppUserAvatar(
                        name: e.displayName,
                        imageUrl: e.avatarUrl,
                        size: 32,
                        maxInitials: 2,
                        circle: true,
                      ),
                      const SizedBox(width: 6),
                    ],
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        names,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tones.ink2, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${group.rows.length} orang',
                      style: TextStyle(
                        color: tones.ink2,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
