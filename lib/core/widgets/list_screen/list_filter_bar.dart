import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Horizontally scrolling chip row below the app bar of a list screen: the
/// date chip first, then the feature-specific [chips] separated by a gap.
class ListFilterBar extends StatelessWidget {
  const ListFilterBar({
    required this.isLoading,
    required this.isDateActive,
    required this.dateLabel,
    required this.onDatePressed,
    required this.onDateReset,
    super.key,
    this.chips = const <Widget>[],
  });

  final bool isLoading;

  final bool isDateActive;

  /// Label shown while the date filter is active.
  final String dateLabel;

  final VoidCallback onDatePressed;

  final VoidCallback onDateReset;

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space100,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppChip(
              type: AppChipType.filter,
              label: isDateActive ? dateLabel : 'Tanggal',
              selected: isDateActive,
              trailing: isDateActive
                  ? null
                  : _ListChipArrow(isLoading: isLoading),
              onDeleted: isDateActive && !isLoading ? onDateReset : null,
              onPressed: isLoading ? null : onDatePressed,
            ),
            for (final chip in chips) ...[AppSpacing.hGapSm, chip],
          ],
        ),
      ),
    );
  }
}

/// "Dibuat oleh" chip that adapts to the role: admins pick any member, other
/// roles toggle a "created by me" filter.
class ListCreatorFilterChip extends StatelessWidget {
  const ListCreatorFilterChip({
    required this.session,
    required this.isLoading,
    required this.isActive,
    required this.activeEmail,
    required this.activeName,
    required this.onOpenPicker,
    required this.onReset,
    required this.onToggleMine,
    super.key,
  });

  final AuthSessionEntity? session;

  final bool isLoading;

  final bool isActive;

  final String? activeEmail;

  /// Name (or email fallback) of the member the list is filtered by.
  final String? activeName;

  final VoidCallback onOpenPicker;

  final VoidCallback onReset;

  final VoidCallback onToggleMine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    if (session?.role == 'ADMIN') {
      return AppChip(
        type: AppChipType.filter,
        label: isActive ? 'Dibuat oleh $activeName' : 'Dibuat oleh',
        selected: isActive,
        trailing: isActive ? null : _ListChipArrow(isLoading: isLoading),
        onDeleted: isActive && !isLoading ? onReset : null,
        onPressed: isLoading ? null : onOpenPicker,
      );
    }

    final isMine = session?.email != null && activeEmail == session?.email;
    return AppChip(
      type: AppChipType.filter,
      label: 'Dibuat oleh saya',
      selected: isMine,
      leading: isMine
          ? AppSvgIcon(
              KawaloVectors.checkFilled,
              size: 18,
              color: !isLoading
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurface.withValues(
                      alpha: AppStateLayer.disabledOpacity,
                    ),
            )
          : null,
      onPressed: isLoading ? null : onToggleMine,
    );
  }
}

class _ListChipArrow extends StatelessWidget {
  const _ListChipArrow({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    return AppSvgIcon(
      KawaloVectors.arrowDown01,
      size: 18,
      color: !isLoading
          ? colorScheme.onSurfaceVariant
          : colorScheme.onSurface.withValues(
              alpha: AppStateLayer.disabledOpacity,
            ),
    );
  }
}
