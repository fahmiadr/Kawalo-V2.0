import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';

/// Tinted note box used by the attendance admin screens.
class AttendancePanel extends StatelessWidget {
  const AttendancePanel({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.space200),
    decoration: BoxDecoration(
      color: color,
      borderRadius: AppRadius.borderMedium,
    ),
    child: child,
  );
}
