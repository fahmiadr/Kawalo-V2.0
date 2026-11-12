import 'package:flutter/material.dart' show Color;
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/app_display_formatter.dart';
import 'package:kawalo_mobile/core/utils/duration_text.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';

/// Ekstensi lapisan presentasi untuk [AttendanceItemEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, tag styling,
/// koordinat, dan string terformat) tanpa mencemari lapisan Domain.
extension AttendanceItemUiExtension on AttendanceItemEntity {
  /// Nama personil yang aman untuk tampilan UI (em-dash jika kosong/null).
  String get displayUserName => userName.toDisplay();

  /// Profile photo URL, `null` when the server sent none.
  String? get displayAvatarUrl => avatarUrl ?? userProfilePic;

  /// Email personil yang aman untuk tampilan UI.
  String get displayUserEmail => userEmail.toDisplay();

  /// Nama lokasi yang aman untuk tampilan UI.
  String get displayLocationName => locationName.toDisplay();

  /// Nama grup kawasan yang aman untuk tampilan UI.
  String get displayGroupName => groupName.toDisplay();

  /// Tipe absensi yang aman untuk tampilan UI.
  String get displayAttendanceType => attendanceType.toDisplay();

  /// Status dinas yang aman untuk tampilan UI.
  String get displayUserDuty => userDuty.toDisplay();

  /// Tanggal/waktu absensi yang aman untuk tampilan UI.
  String get displayAttendanceDt =>
      attendanceDt.toDisplayFormat(AppDateFormat.formatRawDate);

  /// Nama shift yang aman untuk tampilan UI.
  String get displayShiftName => shiftName.toDisplay();

  /// Rentang jam kerja shift yang aman untuk tampilan UI.
  String get displayShiftTimeWindow => shiftTimeWindow.toDisplay();

  /// Teks gabungan nama shift dan rentang jam kerja.
  String get displayShift {
    final hasName = shiftName != null && shiftName!.isNotEmpty;
    final hasWindow = shiftTimeWindow != null && shiftTimeWindow!.isNotEmpty;

    if (hasName && hasWindow) {
      return '$shiftName • $shiftTimeWindow';
    }
    if (hasName) {
      return shiftName!;
    }
    if (hasWindow) {
      return shiftTimeWindow!;
    }
    return AppDisplayFormatter.emDash;
  }

  /// Shift marker colour, see [parseShiftColor].
  Color? get shiftAccentColor => parseShiftColor(shiftColor);

  /// Menentukan varian [AppTagVariant] berbasis kategori atau kata kunci pada
  /// [attendanceType].
  AppTagVariant get tagVariant {
    final cat = category.toUpperCase();
    if (cat == 'MASUK') {
      return AppTagVariant.primary;
    }
    if (cat == 'PULANG') {
      return AppTagVariant.secondary;
    }
    return AppTagVariant.neutral;
  }

  /// Label ringkas representasi status absensi untuk tampilan [AppTag].
  String get displayCategory {
    final cat = category.toUpperCase();
    if (cat == 'MASUK') return 'Masuk';
    if (cat == 'PULANG') return 'Pulang';
    return displayAttendanceType;
  }

  /// Check-outs are judged by [AttendanceItemEntity.earlyLeaveMinutes]; when
  /// the server did not send it (older API, offline cache) they fall back to
  /// the legacy [diffMinutes] reading.
  bool get _usesEarlyLeave =>
      category.toUpperCase() == 'PULANG' && earlyLeaveMinutes != null;

  /// Merah bila check-in terlambat atau check-out terlalu cepat, selain itu
  /// hijau (varian primary adalah hijau merek).
  bool get isOffSchedule =>
      _usesEarlyLeave ? earlyLeaveMinutes! > 0 : diffMinutes > 0;

  /// Warna label status: merah ([AppTagVariant.error]) atau hijau
  /// ([AppTagVariant.primary]).
  AppTagVariant get statusVariant =>
      isOffSchedule ? AppTagVariant.error : AppTagVariant.primary;

  /// Label status waktu absensi (terlambat / pulang lebih cepat / tepat waktu).
  String get displayDiffLabel {
    if (_usesEarlyLeave) {
      final early = earlyLeaveMinutes!;
      return early > 0
          ? 'Pulang lebih cepat ${formatMinutes(early)}'
          : 'Tepat waktu';
    }
    if (diffMinutes == 0) return 'Tepat waktu';
    if (diffMinutes > 0) return 'Terlambat ${formatMinutes(diffMinutes)}';
    return 'Lebih awal ${formatMinutes(diffMinutes)}';
  }

  /// True only when the server explicitly reports a failed face match
  /// (manual approval or legacy row).
  bool get isUnverified => faceVerified == false;
}
