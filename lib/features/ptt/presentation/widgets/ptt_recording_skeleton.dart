import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Placeholder bubbles shown during the first load. Alternating sides hint at
/// the chat layout.
class PttRecordingSkeleton extends StatelessWidget {
  const PttRecordingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.of(context).colorScheme.surfaceContainerHigh;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.space200),
      itemCount: 6,
      itemBuilder: (context, index) => Align(
        alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.space50),
          width: MediaQuery.sizeOf(context).width * 0.7,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.borderLarge,
          ),
        ),
      ),
    );
  }
}
