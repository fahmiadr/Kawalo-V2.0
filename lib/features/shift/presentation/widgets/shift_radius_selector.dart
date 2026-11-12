import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_form_chip_group.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/extensions/shift_ui_extension.dart';

/// Preset chips (25 m .. 1 km) plus "Lainnya" for a typed radius.
class ShiftRadiusSelector extends StatelessWidget {
  const ShiftRadiusSelector({
    required this.radiusText,
    required this.isCustom,
    required this.onPreset,
    required this.onCustom,
    required this.onTextChanged,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  /// Marks the "Lainnya" chip in [AppFormChipGroup].
  static const _customValue = -1;

  final String radiusText;
  final bool isCustom;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustom;
  final ValueChanged<String> onTextChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final current = int.tryParse(radiusText.trim());
    final summary = isCustom
        ? 'Atur sendiri'
        : current == null
        ? ''
        : formatShiftRadius(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormChipGroup<int>(
          label: 'Radius absen',
          layout: AppFormChipGroupLayout.wrap,
          enabled: enabled,
          selectedValue: isCustom ? _customValue : current,
          trailing: Text(
            summary,
            style: theme.typeScale.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          items: [
            for (final metres in ShiftFormCubit.radiusPresets)
              AppFormChipItem(
                value: metres,
                label: formatShiftRadius(metres),
                semanticLabel: 'Radius ${formatShiftRadius(metres)}',
              ),
            const AppFormChipItem(value: _customValue, label: 'Lainnya'),
          ],
          onSelected: (value) =>
              value == _customValue ? onCustom() : onPreset(value),
        ),
        if (isCustom) ...[
          AppSpacing.vGap150,
          _CustomRadiusField(
            initialText: radiusText,
            onChanged: onTextChanged,
            errorText: errorText,
            enabled: enabled,
          ),
        ],
      ],
    );
  }
}

class _CustomRadiusField extends StatefulWidget {
  const _CustomRadiusField({
    required this.initialText,
    required this.onChanged,
    required this.enabled,
    this.errorText,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  State<_CustomRadiusField> createState() => _CustomRadiusFieldState();
}

class _CustomRadiusFieldState extends State<_CustomRadiusField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Radius (meter) *',
      variant: AppTextFieldVariant.outlined,
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 4,
      showCounter: false,
      suffixText: 'm',
      errorText: widget.errorText,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}
