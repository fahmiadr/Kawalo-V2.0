import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/extensions/attendance_item_ui_extension.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_shift_marker.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// One attendance record as a list row (`RdRiwayatAbsen`, `RdLaporanAbsen`):
/// who, "Masuk 06.52 · Pos Utama", and the timing as a pill. Details (shift,
/// map, photo) live in the detail sheet.
class AttendanceCard extends StatelessWidget {
  const AttendanceCard({required this.item, super.key, this.onTap});

  final AttendanceItemEntity item;
  final VoidCallback? onTap;

  /// `Masuk 06.52 · 10 Sep`, falling back to the raw value.
  String get _when {
    final at = AppDateFormat.tryParse(item.attendanceDt)?.toLocal();
    if (at == null) return item.displayAttendanceDt;
    final hm =
        '${at.hour.toString().padLeft(2, '0')}.'
        '${at.minute.toString().padLeft(2, '0')}';
    return '${item.displayCategory} $hm · ${AppDateFormat.formatDayMonth(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final location = item.locationName;
    final similarity = item.faceSimilarityPercent;
    final isAdmin =
        context.watch<UserSessionCubit?>()?.state?.isAdminRole ?? false;
    final subtitle = [
      _when,
      if (location != null && location.isNotEmpty) location,
      if (isAdmin && similarity != null) 'Kemiripan $similarity%',
    ].join(' · ');
    final (label, kind) = item.isUnverified
        ? ('Tidak terverifikasi', AppStatusKind.neutral)
        : (
            item.displayDiffLabel,
            item.isOffSchedule ? AppStatusKind.bad : AppStatusKind.ok,
          );

    return TaskListItem(
      onTap: onTap,
      semanticLabel:
          'Absensi ${item.displayUserName}, $subtitle, '
          'shift ${item.displayShift}, $label',
      leading: AppUserAvatar(
        name: item.displayUserName,
        imageUrl: item.displayAvatarUrl,
        size: 36,
      ),
      title: item.displayUserName,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AttendanceShiftMarker(item: item),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: AppStatusPill(label: label, kind: kind),
          ),
        ],
      ),
    );
  }
}
