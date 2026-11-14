import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/attendance_admin/attendance_admin_module.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_setting_cubit.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

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
    final tones = KawaloTones.of(context);

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
          backgroundColor: tones.background,
          appBar: AppBar(
            backgroundColor: tones.background,
            surfaceTintColor: Colors.transparent,
            title: const Text('Batas Kemiripan Wajah'),
          ),
          bottomNavigationBar: showActions
              ? AppTaskFooter(
                  children: [
                    AppTaskButton(
                      label: 'Simpan',
                      icon: Icons.check_rounded,
                      tone: tones.adm,
                      isLoading: state.saving,
                      onPressed: state.isDirty && !state.saving
                          ? () => unawaited(_cubit.save())
                          : null,
                    ),
                    if (!setting.isDefault)
                      taskSecondary(
                        'Kembalikan ke Bawaan',
                        state.saving
                            ? null
                            : () => unawaited(_confirmReset(setting)),
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
    final tones = KawaloTones.of(context);
    final note = TextStyle(color: tones.ink2, fontSize: 14, height: 1.4);
    final updatedBy = setting.updatedBy;
    final presets = [
      for (final p in _presets)
        if (p >= setting.minPercent && p <= setting.maxPercent) p,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        TaskBox(
          children: [
            Center(
              child: Text(
                '$draft%',
                key: const ValueKey('setting_value'),
                style: TextStyle(
                  color: tones.ink,
                  fontSize: 56,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Center(
              child: Text(
                'Kemiripan minimum',
                style: TextStyle(
                  color: tones.ink2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Semantics(
              label: 'Persentase kemiripan minimal',
              value: '$draft persen',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: tones.adm.color,
                  thumbColor: tones.adm.color,
                  inactiveTrackColor: tones.surface2,
                ),
                child: Slider(
                  min: setting.minPercent.toDouble(),
                  max: setting.maxPercent.toDouble(),
                  divisions: setting.maxPercent - setting.minPercent,
                  value: draft.toDouble(),
                  label: '$draft%',
                  onChanged: editable ? (v) => onChanged(v.round()) : null,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${setting.minPercent}%', style: note),
                Text('${setting.maxPercent}%', style: note),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        TaskChoiceChips<int>(
          tone: tones.adm,
          enabled: editable,
          selected: draft,
          onSelected: onChanged,
          options: [for (final p in presets) (p, '$p%')],
        ),
        const SizedBox(height: 12),
        _HintPanel(strictness: _strictnessOf(draft)),
        const SizedBox(height: 12),
        Text(
          'Persentase kemiripan minimal agar wajah dianggap cocok saat '
          'check-in dan check-out. Makin tinggi makin ketat: wajah orang lain '
          'makin sulit lolos, tetapi petugas lebih sering gagal dan melapor '
          'manual.',
          style: note,
        ),
        if (!isAdmin) ...[
          const SizedBox(height: 8),
          Text('Hanya admin yang dapat mengubah pengaturan ini.', style: note),
        ],
        const SizedBox(height: 8),
        Text('Bawaan server: ${setting.defaultPercent}%', style: note),
        if (!setting.isDefault && updatedBy != null)
          Text(
            'Diubah oleh $updatedBy pada '
            '${AppDateFormat.formatRawDate(setting.updatedAt)}',
            style: note,
          ),
      ],
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.strictness});

  final _Strictness strictness;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final (label, warn) = switch (strictness) {
      _Strictness.loose => ('Longgar: petugas lain lebih mudah lolos', true),
      _Strictness.balanced => ('Seimbang', false),
      _Strictness.strict => (
        'Ketat: petugas yang sah bisa lebih sering ditolak',
        true,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warn ? tones.warnSoft : tones.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: warn ? tones.warn : tones.ink2,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
