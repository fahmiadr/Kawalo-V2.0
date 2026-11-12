import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/extensions/manual_request_ui_extension.dart';

/// List card of one manual attendance request, same layout as the attendance
/// list card.
class ManualRequestCard extends StatelessWidget {
  const ManualRequestCard({required this.request, super.key, this.onTap});

  final ManualRequestEntity request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasized = theme.typography.emphasized;

    return AppCard(
      onPressed: onTap,
      semanticLabel:
          'Permintaan absen manual ${request.displayUserName}, '
          '${request.displayType}, ${request.displayReason}, '
          'status ${request.status.label}, ${request.displayRequestedAt}',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppUserAvatar(
                name: request.displayUserName,
                imageUrl: request.avatarUrl,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.displayUserName,
                      style: emphasized.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      request.userEmail,
                      style: theme.typeScale.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.space100,
            runSpacing: AppSpacing.space100,
            children: [
              AppTag(
                label: request.displayType,
                variant: request.displayType == 'Masuk'
                    ? AppTagVariant.primary
                    : AppTagVariant.secondary,
              ),
              AppTag(
                label: request.status.label,
                variant: request.statusVariant,
              ),
            ],
          ),
          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),
          _Row(
            icon: KawaloColorVectors.timeRotation,
            text: request.displayShift,
          ),
          AppSpacing.vGap50,
          _Row(
            icon: KawaloColorVectors.checklist2,
            text: request.displayReason,
          ),
          AppSpacing.vGap50,
          _Row(
            icon: KawaloColorVectors.calendar1,
            text: request.displayRequestedAt,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      children: [
        AppSvgIcon.color(icon, size: 20),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            text,
            style: theme.typeScale.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
