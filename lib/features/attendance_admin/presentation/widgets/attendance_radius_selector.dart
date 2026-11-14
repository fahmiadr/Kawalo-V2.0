import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_location_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/extensions/attendance_location_ui_extension.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// Preset chips (25 m .. 1 km) plus "Lainnya" for a typed radius.
class AttendanceRadiusSelector extends StatelessWidget {
  const AttendanceRadiusSelector({
    required this.radiusText,
    required this.isCustom,
    required this.onPreset,
    required this.onCustom,
    required this.onTextChanged,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  /// Marks the "Lainnya" chip.
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
    final tones = KawaloTones.of(context);
    final current = int.tryParse(radiusText.trim());
    final summary = isCustom
        ? 'Atur sendiri'
        : current == null
        ? ''
        : formatAttendanceRadius(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Radius absen',
                style: TextStyle(
                  color: tones.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(summary, style: TextStyle(color: tones.ink2, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TaskChoiceChips<int>(
          tone: tones.adm,
          enabled: enabled,
          selected: isCustom ? _customValue : current,
          options: [
            for (final metres in AttendanceLocationCubit.radiusPresets)
              (metres, formatAttendanceRadius(metres)),
            (_customValue, 'Lainnya'),
          ],
          onSelected: (value) =>
              value == _customValue ? onCustom() : onPreset(value),
        ),
        if (isCustom) ...[
          const SizedBox(height: 12),
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
