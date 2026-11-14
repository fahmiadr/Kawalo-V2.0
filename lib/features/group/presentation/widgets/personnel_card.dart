import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

/// One member row of "Personil": avatar, name, email and role.
class PersonnelCard extends StatelessWidget {
  const PersonnelCard({required this.member, super.key});

  final GroupMemberEntity member;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final hasName = member.displayName != member.email;
    final role = member.role?.trim().toUpperCase() ?? '';

    return Semantics(
      container: true,
      label:
          'Personil ${member.displayName}, email ${member.email}'
          '${role.isEmpty ? '' : ', peran $role'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tones.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tones.line),
        ),
        child: Row(
          children: [
            AppUserAvatar(
              name: member.displayName,
              imageUrl: member.profilePic,
              size: 34,
              maxInitials: 2,
              circle: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tones.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // The name falls back to the email, so it is not repeated.
                  if (hasName)
                    Text(
                      member.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tones.ink2, fontSize: 13),
                    ),
                ],
              ),
            ),
            if (role.isNotEmpty) ...[
              const SizedBox(width: 8),
              AppStatusPill(
                label: role,
                kind: role.contains('ADMIN')
                    ? AppStatusKind.ok
                    : AppStatusKind.neutral,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
