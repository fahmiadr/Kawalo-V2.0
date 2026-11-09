import 'package:equatable/equatable.dart';

/// Entitas domain murni yang merepresentasikan satu baris catatan absensi.
class AttendanceItemEntity extends Equatable {
  /// Membuat instance [AttendanceItemEntity].
  const AttendanceItemEntity({
    required this.id,
    required this.category,
    required this.diffMinutes,
    this.userEmail,
    this.userName,
    this.attendanceDt,
    this.attendanceType,
    this.locationName,
    this.userProfilePic,
    this.userDuty,
    this.latitude,
    this.longitude,
    this.shiftName,
    this.shiftColor,
    this.shiftTimeWindow,
    this.groupName,
  });

  /// Identifier unik absensi (AbsenID).
  final String id;

  /// Kategori absensi yang dihitung backend ('masuk', 'pulang', 'lainnya').
  final String category;

  /// Selisih waktu keterlambatan dalam menit (ADiffMins).
  final int diffMinutes;

  /// Email personil/petugas (AbsenEmail).
  final String? userEmail;

  /// Nama personil/petugas (UserName / AbsenName).
  final String? userName;

  /// URL atau nama file foto profil pengguna (UserProfilePic).
  final String? userProfilePic;

  /// Status dinas pengguna (UserDuty, misal: ON DUTY, OFF DUTY).
  final String? userDuty;

  /// Waktu absensi dalam format ISO 8601 atau string tanggal mentah (AbsenDT).
  final String? attendanceDt;

  /// Tipe absensi (AbsenType, misal: CHECK IN, CHECK OUT, REGISTER, dll.).
  final String? attendanceType;

  /// Nama lokasi atau pos absensi (ALocation).
  final String? locationName;

  /// Koordinat garis lintang GPS (ALat).
  final double? latitude;

  /// Koordinat garis bujur GPS (ALong).
  final double? longitude;

  /// Nama shift kerja (ShiftName dari tkshift).
  final String? shiftName;

  /// Aksen kode warna shift kerja (ShiftColor dari tkshift).
  final String? shiftColor;

  /// Rentang jam kerja shift terformat, misal: "07:00 - 15:00".
  final String? shiftTimeWindow;

  /// Nama grup kawasan (GroupName dari tkgroup).
  final String? groupName;

  /// Menandakan apakah petugas terlambat.
  bool get isLate => diffMinutes > 0;

  /// Menandakan apakah petugas tepat waktu atau lebih awal.
  bool get isOnTime => diffMinutes <= 0;

  @override
  List<Object?> get props => [
    id,
    category,
    diffMinutes,
    userEmail,
    userName,
    userProfilePic,
    userDuty,
    attendanceDt,
    attendanceType,
    latitude,
    longitude,
    locationName,
    shiftName,
    shiftColor,
    shiftTimeWindow,
    groupName,
  ];
}
