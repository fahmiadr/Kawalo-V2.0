import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/attendance_admin/attendance_admin_module.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_setting_cubit.dart';

const _presets = [30, 40, 50, 60, 70];

/// Admin screen to set the minimum face similarity that passes check-in/out.
/// The API rejects writes from other roles, so non-admins only see the value.
class AttendanceSettingScreen extends StatefulWidget {
  const AttendanceSettingScreen({super.key, this.cubit});

  static const String routeName = AppRouteNames.attendanceSettings;

  /// Test injection; defaults to the [AttendanceSettingCubit] of the tree.
  final AttendanceSettingCubit? cubit;

  /// Needs an [AttendanceAdminModule] and a [UserSessionCubit] above the
  /// navigator.
  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: routeName),
    builder: (context) => BlocProvider<AttendanceSettingCubit>(
      create: (context) =>
          context.read<AttendanceAdminModule>().createSettingCubit(),
      child: const AttendanceSettingScreen(),
    ),
  );

  @override
  State<AttendanceSettingScreen> createState() =>
      _AttendanceSettingScreenState();
}

class _AttendanceSettingScreenState extends State<AttendanceSettingScreen> {
  AttendanceSettingCubit get _cubit =>
      widget.cubit ?? context.read<AttendanceSettingCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_cubit.load());
    });
  }

  Future<void> _confirmReset(AttendanceSettingEntity setting) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Kembalikan ke bawaan server (${setting.defaultPercent}%)?',
      message:
          'Persentase kemiripan minimal kembali ke ${setting.defaultPercent}%. '
          'Pengaturan khusus grup ini dihapus.',
      confirmText: 'Kembalikan',
      isDestructive: false,
    );
    if ((confirmed ?? false) && mounted) unawaited(_cubit.resetToDefault());
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.watch<UserSessionCubit?>()?.state?.isAdminRole ?? false;
    final colors = AppTheme.of(context).colorScheme;

    return BlocConsumer<AttendanceSettingCubit, AttendanceSettingState>(
      bloc: _cubit,
      listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
      listener: (context, state) {
        final notice = state.notice;
        if (notice != null) AppSnackbar.show(context, message: notice);
      },
      builder: (context, state) {
        final setting = state.setting;
        final showActions = isAdmin && setting != null && state.phase.isLoaded;
        return Scaffold(
          backgroundColor: colors.surface,
          appBar: const AppHomeAppBar(
            title: 'Pengaturan Absensi',
            showBackButton: true,
            showTrailing: false,
          ),
          bottomNavigationBar: showActions
              ? AppPageActions(
                  children: [
                    AppButton(
                      size: AppButtonSize.md,
                      enabled: state.isDirty && !state.saving,
                      onPressed: () => unawaited(_cubit.save()),
                      child: Text(state.saving ? 'Menyimpan...' : 'Simpan'),
                    ),
                    if (!setting.isDefault)
                      AppButton(
                        size: AppButtonSize.md,
                        style: AppButtonColor.tonal,
                        enabled: !state.saving,
                        onPressed: () => unawaited(_confirmReset(setting)),
                        child: const Text('Kembalikan ke Bawaan'),
                      ),
                  ],
                )
              : null,
          body: SafeArea(
            child: switch (state.phase) {
              AttendanceSettingPhase.loading => const Center(
                child: AppLoadingIndicator(
                  semanticLabel: 'Memuat pengaturan absensi',
                ),
              ),
              AttendanceSettingPhase.failure => ListErrorState(
                noun: 'pengaturan absensi',
                message: state.errorMessage ?? 'Terjadi kesalahan.',
                onRetry: () => unawaited(_cubit.load()),
              ),
              AttendanceSettingPhase.loaded => _Content(
                setting: setting!,
                draft: state.draft,
                editable: isAdmin && !state.saving,
                isAdmin: isAdmin,
                onChanged: _cubit.changeDraft,
              ),
            },
          ),
        );
      },
    );
  }
}

extension on AttendanceSettingPhase {
  bool get isLoaded => this == AttendanceSettingPhase.loaded;
}

enum _Strictness { loose, balanced, strict }

_Strictness _strictnessOf(int percent) => percent < 35
    ? _Strictness.loose
    : percent > 60
    ? _Strictness.strict
    : _Strictness.balanced;

class _Content extends StatelessWidget {
  const _Content({
    required this.setting,
    required this.draft,
    required this.editable,
    required this.isAdmin,
    required this.onChanged,
  });

  final AttendanceSettingEntity setting;
  final int draft;
  final bool editable;
  final bool isAdmin;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colors = theme.colorScheme;
    final text = theme.typeScale;
    final updatedBy = setting.updatedBy;
    final presets = [
      for (final p in _presets)
        if (p >= setting.minPercent && p <= setting.maxPercent) p,
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space200),
      children: [
        _Panel(
          color: colors.surfaceContainerLow,
          child: Text(
            'Persentase kemiripan minimal agar wajah dianggap cocok saat '
            'check-in dan check-out. Makin tinggi makin ketat.',
            style: text.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        if (!isAdmin) ...[
          AppSpacing.vGapSm,
          _Panel(
            color: colors.surfaceContainerHigh,
            child: Text(
              'Hanya admin yang dapat mengubah pengaturan ini.',
              style: text.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
        AppSpacing.vGap300,
        Center(
          child: Text(
            '$draft%',
            key: const ValueKey('setting_value'),
            style: text.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ),
        Semantics(
          label: 'Persentase kemiripan minimal',
          value: '$draft persen',
          child: Slider(
            min: setting.minPercent.toDouble(),
            max: setting.maxPercent.toDouble(),
            divisions: setting.maxPercent - setting.minPercent,
            value: draft.toDouble(),
            label: '$draft%',
            onChanged: editable ? (v) => onChanged(v.round()) : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${setting.minPercent}%', style: text.labelMedium),
              Text('${setting.maxPercent}%', style: text.labelMedium),
            ],
          ),
        ),
        AppSpacing.vGapMd,
        Wrap(
          spacing: AppSpacing.space100,
          runSpacing: AppSpacing.space100,
          children: [
            for (final p in presets)
              AppChip(
                type: AppChipType.filter,
                label: '$p%',
                selected: draft == p,
                onPressed: editable ? () => onChanged(p) : null,
              ),
          ],
        ),
        AppSpacing.vGapMd,
        _HintPanel(strictness: _strictnessOf(draft)),
        AppSpacing.vGap300,
        Text(
          'Bawaan server: ${setting.defaultPercent}%',
          style: text.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        if (!setting.isDefault && updatedBy != null) ...[
          AppSpacing.vGap50,
          Text(
            'Diubah oleh $updatedBy pada '
            '${AppDateFormat.formatRawDate(setting.updatedAt)}',
            style: text.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.strictness});

  final _Strictness strictness;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colors = theme.colorScheme;
    final (label, warn) = switch (strictness) {
      _Strictness.loose => ('Longgar: petugas lain lebih mudah lolos', true),
      _Strictness.balanced => ('Seimbang', false),
      _Strictness.strict => (
        'Ketat: petugas yang sah bisa lebih sering ditolak',
        true,
      ),
    };
    return _Panel(
      color: warn ? colors.errorContainer : colors.surfaceContainerHigh,
      child: Text(
        label,
        style: theme.typeScale.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: warn ? colors.onErrorContainer : colors.onSurface,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.space200),
    decoration: BoxDecoration(
      color: color,
      borderRadius: AppRadius.borderMedium,
    ),
    child: child,
  );
}
