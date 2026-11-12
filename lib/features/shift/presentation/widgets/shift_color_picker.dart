import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/core/widgets/app_form_field_slot.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/shift/presentation/shift_palette.dart';

/// Palette swatches. A legacy colour outside [shiftPalette] stays selectable
/// as an extra swatch ("Warna lama") so editing a shift does not change it.
class ShiftColorPicker extends StatelessWidget {
  const ShiftColorPicker({
    required this.selectedHex,
    required this.onSelected,
    this.legacyHex,
    this.enabled = true,
    super.key,
  });

  final String selectedHex;
  final ValueChanged<String> onSelected;

  /// Colour the edited shift had when the form opened.
  final String? legacyHex;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final legacy = legacyHex?.toUpperCase();
    final extra =
        legacy != null &&
            parseShiftColor(legacy) != null &&
            !shiftPalette.any((s) => s.hex == legacy)
        ? ShiftSwatch(legacy, 'Warna lama')
        : null;
    final swatches = [?extra, ...shiftPalette];
    final selected = swatches
        .where((s) => s.hex == selectedHex.toUpperCase())
        .firstOrNull;

    return AppFormFieldSlot(
      label: 'Warna shift',
      trailing: Text(
        selected?.name ?? '',
        style: theme.typeScale.labelMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.space50,
        runSpacing: AppSpacing.space50,
        children: [
          for (final swatch in swatches)
            _Swatch(
              swatch: swatch,
              selected: swatch == selected,
              onTap: enabled ? () => onSelected(swatch.hex) : null,
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.swatch, required this.selected, this.onTap});

  final ShiftSwatch swatch;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = swatch.color;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Warna ${swatch.name}',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(
                        color: AppTheme.of(context).colorScheme.onSurface,
                        width: 2,
                      )
                    : null,
              ),
              child: selected
                  ? IconTheme(
                      data: IconThemeData(color: onShiftColor(color)),
                      child: const AppSvgIcon(KawaloVectors.check, size: 20),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
