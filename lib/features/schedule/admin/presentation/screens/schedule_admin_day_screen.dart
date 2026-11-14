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
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_state.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/extensions/managed_schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/screens/schedule_form_screen.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_person_row.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';

/// Everybody scheduled on one day, grouped by shift. Long-press starts
/// selection for deleting; locked rows (past or already attended) cannot be
/// selected.
class ScheduleAdminDayScreen extends StatefulWidget {
  const ScheduleAdminDayScreen({
    required this.cubit,
    required this.day,
    required this.canManage,
    super.key,
    this.formCubitFactory,
  });

  final ScheduleAdminCubit cubit;
  final DateTime day;
  final bool canManage;

  /// Test injection for the form screen.
  final ScheduleFormCubit Function(BuildContext)? formCubitFactory;

  static const String routeName = AppRouteNames.scheduleAdminDay;

  static Route<void> route({
    required ScheduleAdminCubit cubit,
    required DateTime day,
    required bool canManage,
    ScheduleFormCubit Function(BuildContext)? formCubitFactory,
  }) => AppPageRoute.forwardBackward<void>(
    settings: const RouteSettings(name: routeName),
    builder: (_) => ScheduleAdminDayScreen(
      cubit: cubit,
      day: day,
      canManage: canManage,
      formCubitFactory: formCubitFactory,
    ),
  );

  @override
  State<ScheduleAdminDayScreen> createState() => _ScheduleAdminDayScreenState();
}

class _ScheduleAdminDayScreenState extends State<ScheduleAdminDayScreen> {
  final Set<String> _selected = {};
  bool _deleting = false;

  bool get _selecting => _selected.isNotEmpty;

  void _toggle(ManagedScheduleEntity item) {
    if (item.locked) return;
    setState(() {
      if (!_selected.add(item.id)) _selected.remove(item.id);
    });
  }

  Future<void> _open(ManagedScheduleEntity item) async {
    if (_selecting) return _toggle(item);
    final saved = await Navigator.of(context).push<DateTime>(
      ScheduleFormScreen.route(
        entry: item,
        canManage: widget.canManage,
        today: widget.cubit.today,
        cubitFactory: widget.formCubitFactory,
      ),
    );
    if (saved != null) unawaited(widget.cubit.reveal(saved));
  }

  Future<void> _add() async {
    final cubit = widget.cubit;
    final saved = await Navigator.of(context).push<DateTime>(
      ScheduleFormScreen.route(
        initialDate: widget.day,
        today: cubit.today,
        cubitFactory: widget.formCubitFactory,
      ),
    );
    if (saved != null) unawaited(cubit.reveal(saved));
  }

  Future<void> _deleteSelected(List<ManagedScheduleEntity> items) async {
    final chosen = items.where((e) => _selected.contains(e.id)).toList();
    if (chosen.isEmpty) return;
    final date = AppDateFormat.formatWeekdayDate(widget.day);
    final message = chosen.length == 1
        ? '${chosen.first.displayName} tidak lagi dijadwalkan di '
              '${chosen.first.shiftLabel} pada $date. '
              'Tindakan ini tidak bisa dibatalkan.'
        : '${chosen.length} jadwal pada $date akan dihapus. '
              'Tindakan ini tidak bisa dibatalkan.';
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus ${chosen.length} jadwal?',
      message: message,
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _deleting = true);
    final result = await widget.cubit.deleteMany(
      chosen.map((e) => e.id).toList(),
    );
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _selected.clear();
    });
    result.fold(
      (failure) => AppSnackbar.show(context, message: failure.message),
      (r) => AppSnackbar.show(
        context,
        message: r.skippedCount == 0
            ? '${r.deletedCount} jadwal dihapus.'
            : '${r.deletedCount} jadwal dihapus, ${r.skippedCount} dilewati '
                  'karena terkunci.',
      ),
    );
  }

  PreferredSizeWidget _appBar(int total) {
    if (_selecting) {
      return AppTopBar(
        title: '${_selected.length} dipilih',
        leading: AppTopBarLeading.close,
        onLeadingPressed: () => setState(_selected.clear),
      );
    }
    final relative = relativeDayLabel(widget.day, widget.cubit.today);
    return AppTopBar(
      title: AppDateFormat.formatWeekdayDate(widget.day),
      subtitle: '${relative == null ? '' : '$relative · '}$total jadwal',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final tones = KawaloTones.of(context);
    return BlocBuilder<ScheduleAdminCubit, ScheduleAdminState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final items = state.itemsOn(widget.day);
        final groups = groupByShift(items);
        final isPast = widget.day.isBefore(widget.cubit.today);
        return PopScope(
          canPop: !_selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(_selected.clear);
          },
          child: Scaffold(
            backgroundColor: tones.background,
            appBar: _appBar(items.length),
            bottomNavigationBar: _selecting
                ? AppTaskFooter(
                    children: [
                      AppTaskButton(
                        label: 'Hapus (${_selected.length})',
                        semanticLabel: 'Hapus jadwal terpilih',
                        icon: Icons.delete_outline_rounded,
                        tone: tones.sos,
                        isLoading: _deleting,
                        onPressed: _deleting
                            ? null
                            : () => unawaited(_deleteSelected(items)),
                      ),
                    ],
                  )
                : widget.canManage && !isPast
                ? AppTaskFooter(
                    children: [
                      AppTaskButton(
                        label:
                            'Tambah ke '
                            '${AppDateFormat.formatDayMonth(widget.day)}',
                        icon: Icons.add_rounded,
                        tone: tones.adm,
                        onPressed: () => unawaited(_add()),
                      ),
                    ],
                  )
                : null,
            body: SafeArea(
              top: false,
              child: items.isEmpty
                  ? const AppEmptyState(
                      icon: AppSvgIcon.color(
                        KawaloColorVectors.calendar2,
                        size: 56,
                      ),
                      title: 'Belum ada jadwal',
                      description: 'Belum ada yang dijadwalkan pada hari ini.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space200,
                        0,
                        AppSpacing.space200,
                        AppSpacing.space200,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppLayout.contentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final group in groups) ...[
                                  ScheduleShiftHeader(group: group),
                                  AppSpacing.vGapSm,
                                  for (final item in group.rows) ...[
                                    SchedulePersonRow(
                                      item: item,
                                      selectionMode: _selecting,
                                      selected: _selected.contains(item.id),
                                      onTap: () => unawaited(_open(item)),
                                      onLongPress: widget.canManage
                                          ? () => _toggle(item)
                                          : null,
                                    ),
                                    AppSpacing.vGap50,
                                  ],
                                ],
                                AppSpacing.vGapSm,
                                Row(
                                  children: [
                                    AppSvgIcon(
                                      KawaloVectors.locked,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    AppSpacing.hGapSm,
                                    Expanded(
                                      child: Text(
                                        'Jadwal yang sudah diabsen atau sudah '
                                        'lewat terkunci dan tidak bisa diubah '
                                        'atau dihapus.',
                                        style: theme.typeScale.bodySmall
                                            .copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
