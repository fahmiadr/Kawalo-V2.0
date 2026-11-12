import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/duration_text.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_date_picker.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/shift_option_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/schedule_repeat.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_state.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/extensions/managed_schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_person_row.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_picker_sheet.dart';
import 'package:kawalo_mobile/features/schedule/schedule_module.dart';

const _weekdayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Create, edit or (for locked rows and non-admins) read a schedule. Pops with
/// the date to show in the calendar after something was saved, or `null`.
class ScheduleFormScreen extends StatefulWidget {
  const ScheduleFormScreen({
    required this.today,
    super.key,
    this.entry,
    this.initialDate,
    this.canManage = true,
  });

  /// Row being edited or inspected; `null` creates.
  final ManagedScheduleEntity? entry;
  final DateTime? initialDate;
  final bool canManage;
  final DateTime today;

  static const String routeName = AppRouteNames.scheduleAdminForm;

  static Route<DateTime> route({
    required DateTime today,
    ManagedScheduleEntity? entry,
    DateTime? initialDate,
    bool canManage = true,
    ScheduleFormCubit Function(BuildContext)? cubitFactory,
  }) => AppPageRoute.fade<DateTime>(
    settings: const RouteSettings(name: routeName),
    builder: (context) => BlocProvider<ScheduleFormCubit>(
      create: (context) =>
          (cubitFactory?.call(context) ??
                context.read<ScheduleModule>().createFormCubit())
            ..loadOptions(),
      child: ScheduleFormScreen(
        today: today,
        entry: entry,
        initialDate: initialDate,
        canManage: canManage,
      ),
    ),
  );

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  GroupMemberEntity? _member;
  ShiftOptionEntity? _shift;
  late DateTime _date;
  DateTime? _until;
  bool _repeat = false;
  bool _weekly = true;
  final Set<int> _weekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };
  bool _submitted = false;
  bool _prefilled = false;

  /// Entries of the last save, kept so the overwrite confirmation can resend
  /// exactly what the admin saw.
  List<ScheduleEntry> _lastEntries = const [];
  bool _overwriteSent = false;
  String? _savedMessage;

  ManagedScheduleEntity? get _entry => widget.entry;
  bool get _readOnly => _entry != null && (_entry!.locked || !widget.canManage);

  DateTime get _lastDate => DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day + maxAheadDays,
  );

  @override
  void initState() {
    super.initState();
    final base = _entry?.date ?? widget.initialDate ?? widget.today;
    _date = base.isBefore(widget.today) && _entry == null ? widget.today : base;
  }

  /// Applies the edited row to the pickers once the options have loaded.
  void _prefill(ScheduleFormState state) {
    final e = _entry;
    if (_prefilled || e == null) return;
    _prefilled = true;
    _member =
        state.members.where((m) => m.email == e.email).firstOrNull ??
        GroupMemberEntity(email: e.email, name: e.name);
    _shift = state.shifts.where((s) => s.uid == e.shiftUid).firstOrNull;
  }

  /// Last day "Sampai tanggal" may take: 92 days after the start, but never
  /// beyond what the server accepts.
  DateTime get _untilLimit {
    final cap = DateTime(_date.year, _date.month, _date.day + maxRepeatDays);
    return cap.isAfter(_lastDate) ? _lastDate : cap;
  }

  DateTime get _effectiveUntil {
    final limit = _untilLimit;
    final until = _until ?? _date;
    if (until.isBefore(_date)) return _date;
    return until.isAfter(limit) ? limit : until;
  }

  List<DateTime> get _dates => _repeat && _entry == null
      ? expandRepeat(
          start: _date,
          until: _effectiveUntil,
          weekdays: _weekly ? _weekdays : null,
        )
      : [_date];

  Future<void> _pickMember(ScheduleFormState state) async {
    final picked = await showAppBottomSheet<GroupMemberEntity>(
      context: context,
      child: SchedulePickerSheet<GroupMemberEntity>(
        title: 'Pilih personil',
        searchable: true,
        selected: _member,
        emptyText: 'Personil tidak ditemukan.',
        options: [
          for (final m in state.members)
            PickerOption(
              value: m,
              title: m.displayName,
              subtitle: m.email,
              leading: AppUserAvatar(
                name: m.displayName,
                imageUrl: m.profilePic,
                size: 32,
                maxInitials: 2,
                circle: true,
              ),
              trailing: m.role == null
                  ? null
                  : AppTag(
                      label: m.role!,
                      size: AppTagSize.small,
                      variant: AppTagVariant.secondary,
                    ),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _member = picked);
  }

  Future<void> _pickShift(ScheduleFormState state) async {
    final picked = await showAppBottomSheet<ShiftOptionEntity>(
      context: context,
      child: SchedulePickerSheet<ShiftOptionEntity>(
        title: 'Pilih shift',
        selected: _shift,
        emptyText: 'Belum ada shift. Buat shift lebih dulu.',
        options: [
          for (final s in state.shifts)
            PickerOption(
              value: s,
              title: s.name,
              subtitle: _shiftSubtitle(s),
              leading: ShiftMarker(color: parseShiftColor(s.color)),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _shift = picked);
  }

  Future<void> _pickDate({required bool isUntil}) async {
    final first = isUntil ? _date : widget.today;
    final picked = await showAppDatePicker(
      context: context,
      firstDate: first,
      lastDate: isUntil ? _untilLimit : _lastDate,
      initialDate: isUntil ? _effectiveUntil : _date,
      currentDate: widget.today,
    );
    if (picked == null) return;
    setState(() {
      if (isUntil) {
        _until = picked;
      } else {
        _date = picked;
      }
    });
  }

  List<ScheduleEntry> _entries() => [
    for (final d in _dates)
      ScheduleEntry(email: _member!.email, shiftUid: _shift!.uid, date: d),
  ];

  bool get _valid => _member != null && _shift != null && _dates.isNotEmpty;

  void _save() {
    setState(() => _submitted = true);
    if (!_valid) return;
    final entries = _entries();
    _lastEntries = entries;
    _overwriteSent = false;
    unawaited(
      context.read<ScheduleFormCubit>().submit(entries, editingId: _entry?.id),
    );
  }

  Future<void> _confirmOverwrite({required int count}) async {
    final name = _member?.displayName ?? '';
    final single = _lastEntries.length == 1;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Ganti jadwal lama?',
      message: single
          ? '$name sudah dijadwalkan di shift lain pada '
                '${AppDateFormat.formatWeekdayDate(_date)}. Jadwal lama akan '
                'dihapus dan diganti dengan ${_shift?.name}. '
                'Tindakan ini tidak bisa dibatalkan.'
          : '$count tanggal sudah punya shift lain untuk $name. Jadwal lama '
                'pada tanggal itu akan dihapus dan diganti dengan '
                '${_shift?.name}. Jadwal yang sudah lewat atau diabsen tetap '
                'dipertahankan. Tindakan ini tidak bisa dibatalkan.',
      confirmText: 'Ganti',
      cancelText: single ? 'Batal' : 'Lewati',
    );
    if (!mounted) return;
    if (confirmed ?? false) {
      _overwriteSent = true;
      unawaited(
        context.read<ScheduleFormCubit>().submit(_lastEntries, overwrite: true),
      );
    } else if (!single) {
      _finish(_savedMessage);
    }
  }

  void _finish(String? message) {
    if (message != null) AppSnackbar.show(context, message: message);
    Navigator.of(context).pop(_lastEntries.firstOrNull?.date ?? _date);
  }

  void _onState(BuildContext context, ScheduleFormState state) {
    if (state.status != ScheduleFormStatus.saved) return;
    _savedMessage = state.message;
    final skips = state.result?.otherShiftSkips ?? 0;
    if (skips > 0 && !_overwriteSent) {
      unawaited(_confirmOverwrite(count: skips));
    } else {
      _finish(state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _readOnly
        ? 'Detail jadwal'
        : _entry == null
        ? 'Tambah jadwal'
        : 'Ubah jadwal';

    return BlocConsumer<ScheduleFormCubit, ScheduleFormState>(
      listener: _onState,
      builder: (context, state) {
        final saving = state.status == ScheduleFormStatus.saving;
        final ready =
            state.status == ScheduleFormStatus.ready ||
            state.status == ScheduleFormStatus.saving ||
            state.status == ScheduleFormStatus.failed;
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            automaticallyImplyLeading: false,
            leading: AppIconButton(
              semanticLabel: 'Tutup',
              onPressed: saving ? null : () => Navigator.of(context).pop(),
              icon: const AppSvgIcon(KawaloVectors.cancel01, size: 24),
            ),
            title: Text(title),
            actions: [
              if (_readOnly && _entry!.locked)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.space200),
                  child: AppTag(
                    label: 'Terkunci',
                    size: AppTagSize.small,
                    variant: AppTagVariant.error,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _readOnly
              ? null
              : AppPageActions(
                  children: [
                    AppButton(
                      size: AppButtonSize.md,
                      enabled: ready && !saving,
                      onPressed: _save,
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          body: SafeArea(
            child: switch (state.status) {
              ScheduleFormStatus.loadingOptions => const Center(
                child: AppLoadingIndicator(),
              ),
              ScheduleFormStatus.optionsError => ListErrorState(
                noun: 'data jadwal',
                message: state.message ?? 'Terjadi kesalahan.',
                onRetry: () =>
                    unawaited(context.read<ScheduleFormCubit>().loadOptions()),
              ),
              _ => _buildForm(context, state, saving),
            },
          ),
        );
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    ScheduleFormState state,
    bool saving,
  ) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    _prefill(state);
    final failed = state.status == ScheduleFormStatus.failed;
    final dates = _dates;
    final entry = _entry;

    final fields = <Widget>[
      if (_readOnly)
        _InfoCard(
          locked: entry!.locked,
          text: entry.locked
              ? 'Jadwal yang sudah diabsen atau tanggalnya sudah lewat tidak '
                    'bisa diubah atau dihapus.'
              : 'Hanya admin yang dapat mengubah jadwal.',
        ),
      if (failed && state.message != null) ...[
        _ErrorCard(
          message: state.message!,
          onOverwrite: state.canOverwrite
              ? () => unawaited(_confirmOverwrite(count: 1))
              : null,
          onShowDay: () => Navigator.of(context).pop(_date),
        ),
      ],
      _Field(
        label: 'Personil${_readOnly ? '' : ' *'}',
        value: _member?.displayName,
        subtitle: _member?.email,
        placeholder: 'Pilih personil',
        leading: _member == null
            ? null
            : AppUserAvatar(
                name: _member!.displayName,
                imageUrl: _member!.profilePic,
                size: 32,
                maxInitials: 2,
                circle: true,
              ),
        trailing: _member?.role == null
            ? null
            : AppTag(
                label: _member!.role!,
                size: AppTagSize.small,
                variant: AppTagVariant.secondary,
              ),
        error: _submitted && _member == null ? 'Pilih personil.' : null,
        onTap: _readOnly || saving ? null : () => _pickMember(state),
      ),
      _Field(
        label: 'Shift${_readOnly ? '' : ' *'}',
        value: _shift?.name ?? (_readOnly ? entry?.shiftLabel : null),
        subtitle: _shift == null
            ? (_readOnly ? _entryShiftSubtitle(entry!) : null)
            : _shiftSubtitle(_shift!),
        placeholder: 'Pilih shift',
        leading: _shift == null && !_readOnly
            ? null
            : ShiftMarker(
                color: _shift == null
                    ? entry?.shiftAccentColor
                    : parseShiftColor(_shift!.color),
              ),
        error: _submitted && _shift == null ? 'Pilih shift.' : null,
        onTap: _readOnly || saving ? null : () => _pickShift(state),
      ),
      _Field(
        label: _repeat && entry == null
            ? 'Tanggal mulai *'
            : 'Tanggal${_readOnly ? '' : ' *'}',
        value: AppDateFormat.formatWeekdayDate(_date),
        leading: const AppSvgIcon(KawaloVectors.calendar01, size: 20),
        hint: _readOnly
            ? null
            : 'Tidak bisa memilih tanggal yang sudah lewat. '
                  'Maksimal $maxAheadDays hari ke depan.',
        onTap: _readOnly || saving ? null : () => _pickDate(isUntil: false),
      ),
      if (_readOnly) _AttendanceCard(item: entry!),
      if (!_readOnly && entry == null)
        ..._repeatSection(context, saving, dates),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space200),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in fields) ...[f, AppSpacing.vGap200],
                if (_readOnly)
                  AppButton(
                    style: AppButtonColor.tonal,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kembali'),
                  ),
                if (saving)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space100),
                    child: Text(
                      'Menyimpan jadwal...',
                      textAlign: TextAlign.center,
                      style: theme.typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _repeatSection(
    BuildContext context,
    bool saving,
    List<DateTime> dates,
  ) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final cap = DateTime(_date.year, _date.month, _date.day + maxRepeatDays);
    final noDays = _repeat && dates.isEmpty;
    final name = _member?.displayName ?? 'Personil';
    final shift = _shift?.name ?? 'Shift';
    final summary = dates.isEmpty
        ? 'Tidak ada tanggal yang cocok.'
        : dates.length == 1
        ? '$name · $shift · ${AppDateFormat.formatWeekdayDate(dates.first)}'
        : '${AppDateFormat.formatDayMonth(dates.first)} - '
              '${AppDateFormat.formatDateOnly(dates.last)} · '
              '${_weekly ? _weekdayList() : 'Setiap hari'}';

    return [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ulangi jadwal',
                  style: theme.typography.emphasized.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Buat jadwal yang sama di beberapa hari sekaligus',
                  style: theme.typeScale.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _repeat,
            onChanged: saving
                ? null
                : (v) => setState(() {
                    _repeat = v;
                    _until ??= _date;
                  }),
          ),
        ],
      ),
      if (_repeat) ...[
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Harian')),
            ButtonSegment(value: true, label: Text('Mingguan')),
          ],
          selected: {_weekly},
          onSelectionChanged: (s) => setState(() => _weekly = s.first),
        ),
        if (_weekly)
          Wrap(
            spacing: AppSpacing.space100,
            runSpacing: AppSpacing.space100,
            children: [
              for (var i = 0; i < 7; i++)
                AppChip(
                  label: _weekdayLabels[i],
                  type: AppChipType.filter,
                  selected: _weekdays.contains(i + 1),
                  onPressed: () => setState(() {
                    if (!_weekdays.add(i + 1)) _weekdays.remove(i + 1);
                  }),
                ),
            ],
          ),
        _Field(
          label: 'Sampai tanggal (ikut dibuat)',
          value: AppDateFormat.formatWeekdayDate(_effectiveUntil),
          leading: const AppSvgIcon(KawaloVectors.calendar01, size: 20),
          hint:
              'Maksimal $maxRepeatDays hari dari tanggal mulai (sampai '
              '${AppDateFormat.formatDateOnly(cap)}).',
          error: noDays ? 'Pilih minimal satu hari dalam minggu.' : null,
          onTap: saving ? null : () => _pickDate(isUntil: true),
        ),
      ],
      AppCard(
        variant: AppCardVariant.filled,
        padding: const EdgeInsets.all(AppSpacing.space150),
        child: Row(
          children: [
            AppSvgIcon(
              KawaloVectors.calendar05,
              size: 22,
              color: colorScheme.primary,
            ),
            AppSpacing.hGap150,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akan dibuat ${dates.length} jadwal',
                    style: theme.typography.emphasized.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    summary,
                    style: theme.typeScale.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  String _weekdayList() {
    final days = _weekdays.toList()..sort();
    return days.map((d) => _weekdayLabels[d - 1]).join(', ');
  }

  String _shiftSubtitle(ShiftOptionEntity s) =>
      '${s.startTime}-${s.endTime}'
      '${s.locationName == null ? '' : ' · ${s.locationName}'}';

  String? _entryShiftSubtitle(ManagedScheduleEntity e) {
    final range = e.timeRange;
    if (range == null) return null;
    return '$range${e.locationName == null ? '' : ' · ${e.locationName}'}';
  }
}

/// A labelled, tappable value box. `onTap == null` renders it read-only.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.onTap,
    this.value,
    this.subtitle,
    this.placeholder,
    this.leading,
    this.trailing,
    this.hint,
    this.error,
  });

  final String label;
  final String? value;
  final String? subtitle;
  final String? placeholder;
  final Widget? leading;
  final Widget? trailing;
  final String? hint;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.typeScale.labelMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.vGapXs,
        AppCard(
          variant: AppCardVariant.outlined,
          onPressed: onTap,
          enabled: onTap != null,
          border: hasError
              ? BorderSide(color: colorScheme.error, width: 1.5)
              : null,
          semanticLabel: '$label: ${value ?? placeholder ?? ''}',
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space100,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppStateLayer.minTouchTarget,
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, AppSpacing.hGap150],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value ?? placeholder ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typeScale.bodyLarge.copyWith(
                          color: value == null
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typeScale.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[AppSpacing.hGapSm, trailing!],
                if (onTap != null) ...[
                  AppSpacing.hGapSm,
                  AppSvgIcon(
                    KawaloVectors.arrowDown01,
                    size: 20,
                    color: colorScheme.outline,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasError || hint != null) ...[
          AppSpacing.vGapXs,
          Text(
            error ?? hint!,
            style: theme.typeScale.bodySmall.copyWith(
              color: hasError
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.locked, required this.text});

  final bool locked;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    return AppCard(
      variant: AppCardVariant.filled,
      padding: const EdgeInsets.all(AppSpacing.space150),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(
            KawaloVectors.locked,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          AppSpacing.hGap150,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locked ? 'Jadwal ini terkunci' : 'Hanya baca',
                  style: theme.typography.emphasized.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  text,
                  style: theme.typeScale.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onShowDay,
    this.onOverwrite,
  });

  final String message;
  final VoidCallback onShowDay;

  /// Only for the "other shift that day" conflict.
  final VoidCallback? onOverwrite;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        variant: AppCardVariant.filled,
        color: colorScheme.errorContainer,
        padding: const EdgeInsets.all(AppSpacing.space150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSvgIcon(
                  KawaloVectors.alertCircle,
                  size: 20,
                  color: colorScheme.onErrorContainer,
                ),
                AppSpacing.hGap150,
                Expanded(
                  child: Text(
                    message,
                    style: theme.typography.emphasized.bodyMedium.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Wrap(
              spacing: AppSpacing.space100,
              children: [
                if (onOverwrite != null)
                  AppButton(
                    onPressed: onOverwrite,
                    child: const Text('Ganti Jadwal Lama'),
                  ),
                AppButton(
                  style: AppButtonColor.tonal,
                  onPressed: onShowDay,
                  child: const Text('Lihat Jadwal Hari Itu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.item});

  final ManagedScheduleEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    Widget row(String label, String value, {Widget? tag}) => Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.typeScale.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.typography.emphasized.bodyLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        ?tag,
      ],
    );
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.space200),
      child: Column(
        children: [
          row(
            'Masuk',
            item.checkin ?? 'Belum absen masuk',
            tag: item.lateMins > 0
                ? AppTag(
                    label: 'Terlambat ${formatMinutes(item.lateMins)}',
                    size: AppTagSize.small,
                    variant: AppTagVariant.error,
                  )
                : null,
          ),
          AppSpacing.vGapSm,
          row('Keluar', item.checkout ?? 'Belum absen keluar'),
        ],
      ),
    );
  }
}
