import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_form_values.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_state.dart';
import 'package:kawalo_mobile/features/shift/presentation/extensions/shift_ui_extension.dart';
import 'package:kawalo_mobile/features/shift/presentation/widgets/shift_color_picker.dart';
import 'package:kawalo_mobile/features/shift/presentation/widgets/shift_time_field.dart';
import 'package:kawalo_mobile/features/shift/shift_module.dart';

/// Full-screen create/edit form. Pops `true` after a save or delete so the
/// caller refreshes its list.
class ShiftFormDialog extends StatefulWidget {
  const ShiftFormDialog({required this.cubit, super.key});

  final ShiftFormCubit cubit;

  /// Creates the cubit from the tree's [ShiftModule] unless [cubit] is given
  /// (tests). Pass [initial] to edit.
  static Future<bool?> show(
    BuildContext context, {
    ShiftEntity? initial,
    ShiftFormCubit? cubit,
  }) async {
    final owned = cubit == null;
    final resolved =
        cubit ?? context.read<ShiftModule>().createFormCubit(initial: initial);
    try {
      return await AppDialog.showFullScreen<bool>(
        context,
        title: resolved.isEdit ? 'Ubah Shift' : 'Tambah Shift',
        bottomActions: [
          _SaveButton(cubit: resolved),
          if (resolved.isEdit) _DeleteButton(cubit: resolved),
        ],
        body: ShiftFormDialog(cubit: resolved),
      );
    } finally {
      if (owned) unawaited(resolved.close());
    }
  }

  @override
  State<ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<ShiftFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;

  ShiftFormCubit get _cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    final values = _cubit.state.values;
    _name = TextEditingController(text: values.name);
    _description = TextEditingController(text: values.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscard() async {
    final discard = await showAppConfirmationDialog(
      context: context,
      title: 'Buang perubahan?',
      message: 'Data formulir yang belum disimpan akan hilang.',
      cancelText: 'Lanjut mengisi',
      confirmText: 'Buang',
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftFormCubit, ShiftFormState>(
      bloc: _cubit,
      builder: (context, state) {
        final values = state.values;
        final errors = state.errors;
        final enabled = !state.isBusy;
        final start = values.startTime;
        final end = values.endTime;
        final theme = AppTheme.of(context);

        return PopScope(
          canPop: !state.isDirty && !state.isBusy,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !state.isBusy) unawaited(_confirmDiscard());
          },
          child: AppLoadingOverlay(
            isLoading: state.isBusy,
            semanticLabel: state.status == ShiftFormStatus.deleting
                ? 'Menghapus shift'
                : 'Menyimpan shift',
            message: state.status == ShiftFormStatus.deleting
                ? 'Menghapus shift...'
                : 'Menyimpan shift...',
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space200,
                AppSpacing.space200,
                AppSpacing.space200,
                AppSpacing.space400,
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
                        if (_cubit.isEdit) ...[
                          const _Note(
                            'Perubahan jam berlaku untuk semua jadwal shift '
                            'ini, termasuk yang sudah lewat.',
                          ),
                          AppSpacing.vGap200,
                        ],
                        AppTextField(
                          label: 'Nama shift *',
                          variant: AppTextFieldVariant.outlined,
                          controller: _name,
                          enabled: enabled,
                          maxLength: ShiftFormValues.textMax,
                          showCounter: false,
                          errorText: errors.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onChanged: _cubit.setName,
                        ),
                        AppSpacing.vGap200,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ShiftTimeField(
                                label: 'Jam mulai *',
                                value: start,
                                enabled: enabled,
                                errorText: errors.startTime,
                                onChanged: _cubit.setStartTime,
                              ),
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: ShiftTimeField(
                                label: 'Jam selesai *',
                                value: end,
                                enabled: enabled,
                                errorText: errors.endTime,
                                onChanged: _cubit.setEndTime,
                              ),
                            ),
                          ],
                        ),
                        if (start != null && end != null && start != end) ...[
                          AppSpacing.vGap75,
                          Text(
                            _durationHint(start, end),
                            style: theme.typeScale.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        AppSpacing.vGap200,
                        ShiftColorPicker(
                          selectedHex: values.color,
                          legacyHex: _cubit.initial?.color,
                          enabled: enabled,
                          onSelected: _cubit.setColor,
                        ),
                        AppSpacing.vGap200,
                        AppTextField(
                          label: 'Deskripsi (opsional)',
                          variant: AppTextFieldVariant.outlined,
                          controller: _description,
                          enabled: enabled,
                          maxLength: ShiftFormValues.textMax,
                          showCounter: false,
                          errorText: errors.description,
                          textInputAction: TextInputAction.next,
                          onChanged: _cubit.setDescription,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _durationHint(ShiftClock start, ShiftClock end) {
    final duration = formatShiftDuration(start.minutesUntil(end));
    return start.endsNextDay(end)
        ? 'Berakhir keesokan harinya pukul $end · durasi $duration'
        : 'Durasi $duration';
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space150),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(
            KawaloVectors.info,
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              text,
              style: theme.typeScale.bodySmall.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom actions live outside the form body, so they take the cubit
/// explicitly and rebuild only when the busy flag flips.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.cubit});

  final ShiftFormCubit cubit;

  Future<void> _save(BuildContext context) async {
    final result = await cubit.submit();
    if (result == null || !context.mounted) return;
    result.fold(
      (failure) => AppSnackbar.show(context, message: failure.message),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftFormCubit, ShiftFormState>(
      bloc: cubit,
      buildWhen: (a, b) => a.isBusy != b.isBusy,
      builder: (context, state) => AppButton(
        size: AppButtonSize.md,
        enabled: !state.isBusy,
        onPressed: () => unawaited(_save(context)),
        child: const Text('Simpan'),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.cubit});

  final ShiftFormCubit cubit;

  Future<void> _delete(BuildContext context) async {
    final name = cubit.initial?.name ?? '';
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus $name?',
      message:
          'Shift tidak bisa dipakai untuk jadwal baru. Riwayat jadwal dan '
          'absensi tetap tersimpan.',
    );
    if (confirmed != true || !context.mounted) return;

    final result = await cubit.delete();
    if (result == null || !context.mounted) return;
    await result.fold((failure) async {
      if (failure.statusCode == 409) {
        await _showBlocked(context, failure.message);
      } else {
        AppSnackbar.show(context, message: failure.message);
      }
    }, (_) async => Navigator.of(context).pop(true));
  }

  Future<void> _showBlocked(BuildContext context, String message) =>
      AppDialog.show<void>(
        context,
        dialog: AppDialog(
          title: 'Shift tidak bisa dihapus',
          content: Text(message),
          actions: [
            AppButton(
              style: AppButtonColor.text,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colorScheme;
    return BlocBuilder<ShiftFormCubit, ShiftFormState>(
      bloc: cubit,
      buildWhen: (a, b) => a.isBusy != b.isBusy,
      builder: (context, state) => AppButton(
        size: AppButtonSize.md,
        enabled: !state.isBusy,
        decoration: AppButtonDecoration(
          backgroundColor: WidgetStatePropertyAll(colors.error),
          foregroundColor: WidgetStatePropertyAll(colors.onError),
        ),
        onPressed: () => unawaited(_delete(context)),
        child: const Text('Hapus Shift'),
      ),
    );
  }
}
