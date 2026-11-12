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
    this.avatarUrl,
    this.userDuty,
    this.latitude,
    this.longitude,
    this.shiftName,
    this.shiftColor,
    this.shiftTimeWindow,
    this.groupName,
    this.earlyLeaveMinutes,
    this.faceVerified,
    this.hasPhoto,
    this.faceSimilarityPercent,
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

  /// Newer key for the same photo; preferred over [userProfilePic].
  final String? avatarUrl;

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

  /// Minutes a check-out came before the shift end (server applies the
  /// tolerance). Null when the server did not send it, which also happens for
  /// rows read back from the offline cache.
  final int? earlyLeaveMinutes;

  /// Null when unknown (older API or offline cache).
  final bool? faceVerified;

  /// Whether an admin can open a check-in/out photo for this row.
  final bool? hasPhoto;

  /// Admin-only; null for other roles, manual rows and the offline cache.
  final int? faceSimilarityPercent;

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
    avatarUrl,
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
    earlyLeaveMinutes,
    faceVerified,
    hasPhoto,
    faceSimilarityPercent,
  ];
}
