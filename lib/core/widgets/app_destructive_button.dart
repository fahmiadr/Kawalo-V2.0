import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

/// Error-colored full button for destructive page actions (Hapus ...), meant
/// to sit last inside `AppPageActions`. The caller must still ask for
/// confirmation before deleting anything.
class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.enabled = true,
    super.key,
  });

  final String label;

  final VoidCallback? onPressed;

  final String? semanticLabel;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    return AppButton(
      size: AppButtonSize.md,
      enabled: enabled && onPressed != null,
      semanticLabel: semanticLabel,
      decoration: AppButtonDecoration(
        backgroundColor: WidgetStatePropertyAll(colors.error),
        foregroundColor: WidgetStatePropertyAll(colors.onError),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
