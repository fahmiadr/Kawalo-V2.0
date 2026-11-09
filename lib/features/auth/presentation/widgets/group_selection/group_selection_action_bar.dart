import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

class GroupSelectionActionBar extends StatelessWidget {
  const GroupSelectionActionBar({
    required this.horizontalPadding,
    required this.isLoading,
    required this.canConfirm,
    required this.onConfirm,
    super.key,
  });

  final double horizontalPadding;
  final bool isLoading;
  final bool canConfirm;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppSpacing.space150,
            ),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                size: AppButtonSize.md,
                shape: AppButtonShape.square,
                enabled: !isLoading && canConfirm,
                semanticLabel: isLoading
                    ? 'Menyiapkan grup'
                    : 'Konfirmasi dan lanjutkan ke '
                          'beranda',
                onPressed: isLoading ? null : onConfirm,
                child: Text(
                  'Lanjutkan ke beranda',
                  style: typeScale.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
