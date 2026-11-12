import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

class PersonnelCard extends StatelessWidget {
  const PersonnelCard({required this.member, super.key});

  final GroupMemberEntity member;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final hasName = member.displayName != member.email;

    return AppCard(
      semanticLabel: 'Personil ${member.displayName}, email ${member.email}',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Row(
        children: [
          AppUserAvatar(name: member.displayName, imageUrl: member.profilePic),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.displayName,
                  style: theme.typography.emphasized.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // The name falls back to the email, so it is not repeated.
                if (hasName)
                  Text(
                    member.email,
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
    );
  }
}
