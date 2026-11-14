import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';

/// "Selesaikan" in the detail top bar; the confirm dialog follows.
class IncidentDetailResolveButton extends StatelessWidget {
  const IncidentDetailResolveButton({
    required this.isResolving,
    required this.isOffline,
    required this.onPressed,
    super.key,
  });

  final bool isResolving;
  final bool isOffline;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppTaskButton(
      label: 'Selesaikan',
      variant: AppTaskButtonVariant.secondary,
      size: AppTaskButtonSize.small,
      semanticLabel: 'Selesaikan insiden',
      isLoading: isResolving,
      onPressed: isOffline ? null : onPressed,
    );
  }
}
