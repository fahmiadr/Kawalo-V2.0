import 'package:isar_community/isar.dart';

part 'attendance_local_model.g.dart';

/// Skema tabel lokal Isar untuk persistensi data absensi.
///
/// Urutan field identik dengan DTO backend dan model domain data.
@collection
class AttendanceLocalModel {
  /// Primary key internal Isar.
  Id isarId = Isar.autoIncrement;

  /// Identifier unik absensi (AbsenID).
  @Index(unique: true, replace: true)
  late String id;

  /// Kategori absensi ('masuk', 'pulang', 'lainnya').
  late String category;

  /// Selisih waktu keterlambatan dalam menit (ADiffMins).
  late int diffMinutes;

  /// Email personil/petugas (AbsenEmail).
  @Index(caseSensitive: false)
  String? userEmail;

  /// Nama personil/petugas (UserName / AbsenName).
  @Index(caseSensitive: false)
  String? userName;

  /// Waktu absensi dalam format ISO 8601 atau string tanggal mentah (AbsenDT).
  @Index()
  String? attendanceDt;

  /// Tipe absensi (AbsenType).
  @Index(caseSensitive: false)
  String? attendanceType;

  /// Nama lokasi atau pos absensi (ALocation).
  @Index(caseSensitive: false)
  String? locationName;

  /// Nama shift kerja (ShiftName).
  @Index(caseSensitive: false)
  String? shiftName;

  /// URL atau nama file foto profil pengguna (UserProfilePic).
  String? userProfilePic;

  /// Status dinas pengguna (UserDuty).
  String? userDuty;

  /// Koordinat garis lintang GPS (ALat).
  String? latitude;

  /// Koordinat garis bujur GPS (ALong).
  String? longitude;

  /// Aksen kode warna shift kerja (ShiftColor).
  String? shiftColor;

  /// Rentang jam kerja shift terformat (misal: "07:00 - 15:00").
  String? shiftTimeWindow;

  /// Nama grup kawasan (GroupName).
  String? groupName;

  /// Menit pulang lebih cepat dari akhir shift; null untuk baris lama.
  int? earlyLeaveMinutes;

  /// Hasil verifikasi wajah; null bila tidak diketahui.
  bool? faceVerified;

  /// Apakah foto absensi tersedia untuk admin.
  bool? hasPhoto;
}
