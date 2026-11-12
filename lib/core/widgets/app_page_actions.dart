import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Primary actions of a page (Simpan, Hapus, Kirim, ...), stacked vertically
/// at the very bottom, full width.
///
/// Product rule: Simpan and Hapus never live in the header. Put the main action
/// first and the destructive one last; a destructive action always asks for
/// confirmation before it runs.
class AppPageActions extends StatelessWidget {
  const AppPageActions({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) AppSpacing.vGap100,
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
