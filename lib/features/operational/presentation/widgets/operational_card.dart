import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

/// One member row of "Aktivitas Operasional": avatar, name, latest state with
/// its time, and the duty (ON/OFF DUTY) pill.
class OperationalCard extends StatelessWidget {
  const OperationalCard({
    required this.item,
    super.key,
    this.onTap,
    this.clock = DateTime.now,
  });

  final OperationalItemEntity item;
  final VoidCallback? onTap;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final stateLine = item.displayLatestStateLine(clock());

    return Semantics(
      button: onTap != null,
      label:
          'Personil ${item.displayUserName}, '
          'email ${item.displayUserEmail}, '
          'status dinas ${item.displayLatestDuty}, '
          '${item.displayTotalActivities} aktivitas, '
          'mulai dinas ${item.displayFirstActivityTime}, '
          'status terkini $stateLine',
      excludeSemantics: true,
      child: Material(
        color: tones.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tones.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AppUserAvatar(
                  name: item.displayUserName,
                  imageUrl: item.userProfilePic,
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
                        item.displayUserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        stateLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tones.ink2, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppStatusPill(
                  label: item.displayLatestDuty,
                  kind: item.isOnDuty
                      ? AppStatusKind.ok
                      : AppStatusKind.neutral,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
