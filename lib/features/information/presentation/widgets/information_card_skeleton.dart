import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';

/// Static grey placeholder of one `InformationCard` while the list loads.
class InformationCardSkeleton extends StatelessWidget {
  const InformationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    Widget block(double widthFactor, double height, {double radius = 8}) =>
        FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: tones.surface2,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );

    return ExcludeSemantics(
      child: AppCard(
        color: tones.surface,
        border: BorderSide(color: tones.line),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(0.25, 20, radius: 10),
            const SizedBox(height: 12),
            block(0.75, 16),
            const SizedBox(height: 8),
            block(0.5, 12),
          ],
        ),
      ),
    );
  }
}
