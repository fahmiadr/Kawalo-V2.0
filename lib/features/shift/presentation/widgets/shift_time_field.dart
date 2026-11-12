import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';

/// Read-only field that opens the system time picker (24-hour).
class ShiftTimeField extends StatefulWidget {
  const ShiftTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  final String label;
  final ShiftClock? value;
  final ValueChanged<ShiftClock> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  State<ShiftTimeField> createState() => _ShiftTimeFieldState();
}

class _ShiftTimeFieldState extends State<ShiftTimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(ShiftTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value?.toString() ?? '';
    if (_controller.text != text) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final current = widget.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 7,
        minute: current?.minute ?? 0,
      ),
      helpText: widget.label.replaceAll('*', '').trim(),
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      widget.onChanged(ShiftClock(picked.hour, picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.label,
      value: widget.value?.toString(),
      child: AppTextField(
        label: widget.label,
        variant: AppTextFieldVariant.outlined,
        controller: _controller,
        readOnly: true,
        enabled: widget.enabled,
        errorText: widget.errorText,
        showErrorIcon: false,
        trailing: AppSvgIcon(
          KawaloVectors.clockHour5,
          size: 24,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: widget.enabled ? _pick : null,
      ),
    );
  }
}
