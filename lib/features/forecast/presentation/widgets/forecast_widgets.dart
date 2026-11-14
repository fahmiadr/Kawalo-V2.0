import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';

const _weekdayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String forecastWeekdayShort(DateTime d) => _weekdayShort[d.weekday - 1];

/// "10 - 16 Nov 2026" style label of the configured range.
String forecastRangeLabel(ForecastConfig config) {
  final s = config.startDate;
  final e = config.endDate;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  if (s.year == e.year && s.month == e.month) {
    return s.day == e.day
        ? '${s.day} ${months[s.month - 1]} ${s.year}'
        : '${s.day} - ${e.day} ${months[s.month - 1]} ${s.year}';
  }
  if (s.year == e.year) {
    return '${s.day} ${months[s.month - 1]} - '
        '${e.day} ${months[e.month - 1]} ${s.year}';
  }
  return '${s.day} ${months[s.month - 1]} ${s.year} - '
      '${e.day} ${months[e.month - 1]} ${e.year}';
}

/// Centers [child] and caps its width like the other form screens.
class ForecastContent extends StatelessWidget {
  const ForecastContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
      child: child,
    ),
  );
}

/// Pinned actions of a step: [message] (a failed request) above the
/// buttons, which stack full width with the primary one first.
class ForecastBottomBar extends StatelessWidget {
  const ForecastBottomBar({required this.buttons, this.message, super.key});

  final List<Widget> buttons;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final message = this.message;
    return ColoredBox(
      color: tones.background,
      child: SafeArea(
        top: false,
        child: ForecastContent(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      style: TextStyle(color: tones.sos.color, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  buttons[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minus / value / plus control. [onChanged] `null` disables both buttons.
class ForecastStepper extends StatelessWidget {
  const ForecastStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  /// What the value counts, for screen readers ("Kuota Shift Pagi").
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final change = onChanged;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: const Icon(Icons.remove),
            semanticLabel: 'Kurangi $label',
            onPressed: change == null || value <= min
                ? null
                : () => change(value - 1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.typography.emphasized.titleSmall.copyWith(
                color: change == null
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          AppIconButton(
            icon: const Icon(Icons.add),
            semanticLabel: 'Tambah $label',
            onPressed: change == null || value >= max
                ? null
                : () => change(value + 1),
          ),
        ],
      ),
    );
  }
}

/// Colour dot of a shift; legacy colours that are invalid or purple fall back
/// to a neutral outline.
class ForecastShiftMarker extends StatelessWidget {
  const ForecastShiftMarker({required this.color, super.key});

  final String? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: parseShiftColor(color) ?? colorScheme.outlineVariant,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline),
        ),
      ),
    );
  }
}
