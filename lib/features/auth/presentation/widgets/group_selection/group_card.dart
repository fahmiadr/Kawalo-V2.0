import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_logo.dart';

/// One selectable group row: logo, name, owner and the user's role there. The
/// selected row gets a 2 px brand border.
class GroupCard extends StatelessWidget {
  const GroupCard({
    required this.group,
    required this.isSelected,
    required this.isLoading,
    required this.onSelect,
    this.focusNode,
    super.key,
  });

  final UserGroupEntity group;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onSelect;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final name = group.groupName ?? group.groupUid;
    final owner = group.groupOwner?.trim() ?? '';
    final role = group.category?.trim().toUpperCase() ?? '';

    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: tones.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isSelected
              ? BorderSide(color: tones.ptt.color, width: 2)
              : BorderSide(color: tones.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          focusNode: focusNode,
          onTap: isLoading ? null : onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                GroupLogo(logoUrl: group.groupLogo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (owner.isNotEmpty)
                        Text(
                          'Pemilik: $owner',
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
                    kind: isSelected ? AppStatusKind.ok : AppStatusKind.neutral,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
