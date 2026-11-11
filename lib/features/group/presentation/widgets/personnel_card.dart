import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
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
          _Avatar(member: member),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});

  final GroupMemberEntity member;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final pic = member.profilePic;
    final isNetworkUrl =
        pic != null &&
        (pic.startsWith('http://') || pic.startsWith('https://'));

    return ExcludeSemantics(
      child: isNetworkUrl
          ? ClipRRect(
              borderRadius: AppRadius.borderMedium,
              child: CachedNetworkImage(
                imageUrl: pic,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                placeholder: (_, _) => _Initial(member.displayName),
                errorWidget: (_, _, _) => _Initial(member.displayName),
              ),
            )
          : _Initial(member.displayName),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmed = name.trim();

    return Container(
      width: _Avatar._size,
      height: _Avatar._size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: AppRadius.borderMedium,
      ),
      child: Text(
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase(),
        style: theme.typography.emphasized.titleMedium.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
