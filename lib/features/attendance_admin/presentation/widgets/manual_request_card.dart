import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/extensions/manual_request_ui_extension.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// One manual attendance request as a list row: who, "Masuk · Wajah tidak
/// dikenali", when it was requested, and its status.
class ManualRequestCard extends StatelessWidget {
  const ManualRequestCard({required this.request, super.key, this.onTap});

  final ManualRequestEntity request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TaskListItem(
      onTap: onTap,
      semanticLabel:
          'Permintaan absen manual ${request.displayUserName}, '
          '${request.displayType}, ${request.displayReason}, '
          'status ${request.status.label}, ${request.displayRequestedAt}',
      leading: AppUserAvatar(
        name: request.displayUserName,
        imageUrl: request.avatarUrl,
        size: 36,
      ),
      title: request.displayUserName,
      subtitle:
          '${request.displayType} · ${request.displayReason} · '
          '${request.displayRequestedAt}',
      trailing: request.isPending
          ? null
          : AppStatusPill(
              label: request.status.label,
              kind: request.status == ManualRequestStatus.approved
                  ? AppStatusKind.ok
                  : AppStatusKind.bad,
            ),
    );
  }
}
