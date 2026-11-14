import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';

/// Static grey placeholder of one `GuestCard` row while the list loads.
class GuestCardSkeleton extends StatelessWidget {
  const GuestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    Widget block(double width, double height, {double radius = 8}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tones.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return ExcludeSemantics(
      child: AppCard(
        color: tones.surface,
        border: BorderSide(color: tones.line),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            block(34, 34, radius: 17),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(c.maxWidth * 0.7, 14),
                    const SizedBox(height: 8),
                    block(c.maxWidth * 0.45, 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
