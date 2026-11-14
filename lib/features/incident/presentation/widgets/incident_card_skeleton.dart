import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// Placeholder row with the shape of `IncidentCard` while the list loads.
class IncidentCardSkeleton extends StatelessWidget {
  const IncidentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tones.surface2,
        borderRadius: BorderRadius.circular(6),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tones.surface2,
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(160, 14),
                  const SizedBox(height: 6),
                  bar(110, 12),
                ],
              ),
            ),
            bar(56, 20),
          ],
        ),
      ),
    );
  }
}
