import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

class OperationalCardSkeleton extends StatelessWidget {
  const OperationalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);

    Widget bar(double width, double height, double radius) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tones.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tones.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tones.line),
        ),
        child: Row(
          children: [
            bar(34, 34, 17),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(140, 14, 6),
                  const SizedBox(height: 8),
                  bar(96, 12, 6),
                ],
              ),
            ),
            bar(64, 20, 10),
          ],
        ),
      ),
    );
  }
}
