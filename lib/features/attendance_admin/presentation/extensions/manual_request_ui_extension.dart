import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/app_display_formatter.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';

extension ManualRequestUiExtension on ManualRequestEntity {
  String get displayUserName => userName.toDisplay();

  String get displayRequestedAt =>
      requestedAt.toDisplayFormat(AppDateFormat.formatRawDate);

  String get displayDecidedAt =>
      decidedAt.toDisplayFormat(AppDateFormat.formatRawDate);

  /// "Masuk" or "Pulang", read from the server's attendance type.
  String get displayType {
    final type = attendanceType.toLowerCase();
    if (type.contains('out') || type.contains('pulang')) return 'Pulang';
    if (type.contains('in') || type.contains('masuk')) return 'Masuk';
    return attendanceType.toDisplay();
  }

  String get displayReason => switch (reason) {
    ManualRequestReason.faceFailed => 'Wajah tidak dikenali',
    ManualRequestReason.cameraUnavailable => 'Kamera tidak tersedia',
    ManualRequestReason.unknown => 'Alasan tidak tercatat',
  };

  String get displayShift {
    final hasName = shiftName != null && shiftName!.isNotEmpty;
    final hasWindow = shiftTimeWindow != null && shiftTimeWindow!.isNotEmpty;
    if (hasName && hasWindow) return '$shiftName • $shiftTimeWindow';
    if (hasName) return shiftName!;
    if (hasWindow) return shiftTimeWindow!;
    return AppDisplayFormatter.emDash;
  }

  String? get displayDistance {
    final distance = distanceMeters;
    if (distance == null) return null;
    final radius = radiusMeters;
    return radius == null
        ? '$distance m dari lokasi shift'
        : '$distance m dari lokasi shift (radius $radius m)';
  }

  /// Red/green carry the on-time meaning elsewhere in attendance, so a pending
  /// request stays neutral; only a rejection gets the error colour.
  AppTagVariant get statusVariant => switch (status) {
    ManualRequestStatus.pending => AppTagVariant.neutral,
    ManualRequestStatus.approved => AppTagVariant.primary,
    ManualRequestStatus.rejected => AppTagVariant.error,
  };
}
