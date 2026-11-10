import 'package:flutter/material.dart' show Color, HSVColor;
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/app_display_formatter.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';

/// Ekstensi lapisan presentasi untuk [AttendanceItemEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, tag styling,
/// koordinat, dan string terformat) tanpa mencemari lapisan Domain.
extension AttendanceItemUiExtension on AttendanceItemEntity {
  /// Nama personil yang aman untuk tampilan UI (em-dash jika kosong/null).
  String get displayUserName => userName.toDisplay();

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

  /// Shift marker colour parsed from `#RRGGBB` / `RRGGBB`, or `null` when the
  /// value is empty or invalid.
  ///
  /// Purple hues are dropped on purpose: the app never shows purple, and the
  /// colour is free text chosen by the group admin.
  Color? get shiftAccentColor {
    final raw = shiftColor?.trim();
    if (raw == null || raw.isEmpty) return null;
    final hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (hex.length != 6) return null;
    final rgb = int.tryParse(hex, radix: 16);
    if (rgb == null) return null;

    final color = Color(0xFF000000 | rgb);
    final hsv = HSVColor.fromColor(color);
    final isPurple = hsv.saturation > 0.15 && hsv.hue >= 250 && hsv.hue <= 330;
    return isPurple ? null : color;
  }

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

  /// Label keterlambatan waktu absensi berbasis logika domain.
  String get displayDiffLabel {
    if (diffMinutes == 0) return 'Tepat waktu';
    if (diffMinutes > 0) return 'Terlambat $diffMinutes menit';
    return 'Lebih awal ${diffMinutes.abs()} menit';
  }
}
