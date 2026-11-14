import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// `primary` is filled with the task tone; `secondary` is the neutral grey
/// (Batal, Kembali, Lihat ...).
enum AppTaskButtonVariant { primary, secondary }

/// `large`: 64 px full width (the one primary action of a screen or card).
/// `medium`: 48 px full width (dialog/sheet actions).
/// `small`: 44 px, as wide as its label (inline secondary actions).
enum AppTaskButtonSize { large, medium, small }

/// Button of the redesign 2026 (`.btn` in `rd.css`). Without [onPressed] it is
/// drawn disabled (grey); [isLoading] shows a spinner before the label and
/// ignores taps.
class AppTaskButton extends StatelessWidget {
  const AppTaskButton({
    required this.label,
    super.key,
    this.icon,
    this.tone,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppTaskButtonVariant.primary,
    this.size = AppTaskButtonSize.large,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;

  /// Fill of [AppTaskButtonVariant.primary]; brand green by default.
  final KawaloTone? tone;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppTaskButtonVariant variant;
  final AppTaskButtonSize size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final t = tone ?? tones.ptt;
    final disabled = onPressed == null;
    final (Color bg, Color fg) = disabled
        ? (tones.surface2, tones.ink3)
        : variant == AppTaskButtonVariant.primary
        ? (t.color, t.on)
        : (tones.surface2, tones.ink);
    final (
      double height,
      double radius,
      double fontSize,
      double iconSize,
    ) = switch (size) {
      AppTaskButtonSize.large => (64, 20, 17, 24),
      AppTaskButtonSize.medium => (48, 14, 15, 22),
      AppTaskButtonSize.small => (44, 14, 14, 20),
    };
    final fullWidth = size != AppTaskButtonSize.small;

    return Semantics(
      button: true,
      enabled: !disabled && !isLoading,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height,
              minWidth: fullWidth ? double.infinity : 0,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox.square(
                      dimension: iconSize - 2,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: fg,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: iconSize, color: fg),
                  if (isLoading || icon != null) const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
