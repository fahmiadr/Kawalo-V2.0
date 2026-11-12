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
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.of(context).colorScheme.surface,
      appBar: AppHomeAppBar(
        title: 'Manajemen Jadwal',
        showBackButton: true,
        trailing: BlocBuilder<ScheduleAdminCubit, ScheduleAdminState>(
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
      ),
      floatingActionButton: canManage
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.onForecast != null) ...[
                  AppExtendedFab(
                    color: AppFabColor.secondary,
                    onPressed: _openForecast,
                    icon: const AppSvgIcon(KawaloVectors.flashAuto, size: 24),
                    label: 'Forecast',
                  ),
                  AppSpacing.vGapSm,
                ],
                AppExtendedFab(
                  onPressed: _openForm,
                  icon: const AppSvgIcon(KawaloVectors.add01, size: 24),
                  label: 'Tambah',
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
              onAdd: _openForm,
              onForecast: widget.onForecast == null ? null : _openForecast,
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
    required this.onAdd,
    required this.onForecast,
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
  final VoidCallback onAdd;
  final VoidCallback? onForecast;
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
        AppLayout.fabScrollClearance * 1.6,
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
                      '${onForecast == null ? '' : ', atau buat otomatis untuk beberapa hari sekaligus dengan Forecast'}.'
                : 'Jadwal grup belum dibuat.',
            actionLabel: canManage ? 'Tambah Jadwal' : null,
            onActionPressed: canManage ? onAdd : null,
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
    return [
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

class _ShiftSummaryCard extends StatelessWidget {
  const _ShiftSummaryCard({required this.group, required this.onTap});

  final ShiftGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final first = group.first;
    final names = group.rows.map((e) => e.displayName).join(', ');
    return AppCard(
      onPressed: onTap,
      semanticLabel: '${first.shiftLabel}, ${group.rows.length} orang: $names',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Row(
        children: [
          ShiftMarker(color: first.shiftAccentColor),
          AppSpacing.hGap150,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: first.shiftLabel,
                    style: theme.typography.emphasized.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      if (first.timeRange != null)
                        TextSpan(
                          text: '  ${first.timeRange}',
                          style: theme.typeScale.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                AppSpacing.vGap25,
                Text(
                  names,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typeScale.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          AppTag(
            label: '${group.rows.length} orang',
            variant: AppTagVariant.secondary,
            size: AppTagSize.small,
          ),
          AppSpacing.hGap50,
          AppSvgIcon(
            KawaloVectors.arrowRight01,
            size: 20,
            color: colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
