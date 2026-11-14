import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// Grey placeholder rows shaped like `PttRecordingTile` for the first load.
class PttRecordingSkeleton extends StatelessWidget {
  const PttRecordingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = KawaloTones.of(context).surface2;
    Widget bar(double width, double height, [double radius = 6]) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Semantics(
      label: 'Memuat riwayat PTT',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 20),
        itemBuilder: (_, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(34, 34, 17),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(120, 14),
                  const SizedBox(height: 10),
                  bar(double.infinity, 52, 14),
                  const SizedBox(height: 8),
                  bar(180, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
