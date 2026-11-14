import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

class ScheduleCardSkeleton extends StatelessWidget {
  const ScheduleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);

    Widget bar(double width, double height, [double radius = 6]) => Container(
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
            bar(40, 40, 13),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(140, 14), const SizedBox(height: 8), bar(96, 12)],
            ),
          ],
        ),
      ),
    );
  }
}
