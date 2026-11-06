import 'package:equatable/equatable.dart';

/// Data Transfer Object (DTO) untuk satu butir catatan absensi personil.
///
/// Selaras dengan payload DTO backend `AttendanceItemDto`.
class AttendanceModel extends Equatable {
  /// Membuat instance [AttendanceModel].
  const AttendanceModel({
    required this.id,
    required this.category,
    required this.diffMinutes,
    this.userEmail,
    this.userName,
    this.userProfilePic,
    this.userDuty,
    this.attendanceDt,
    this.attendanceType,
    this.latitude,
    this.longitude,
    this.locationName,
    this.shiftName,
    this.shiftColor,
    this.shiftTimeWindow,
    this.groupName,
  });

  /// Mengonversi map JSON dari endpoint backend (`AttendanceItemDto`) menjadi
  /// instance [AttendanceModel].
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      category: json['category'] as String,
      diffMinutes: json['diff_minutes'] as int,
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
      userProfilePic: json['user_profile_pic'] as String?,
      userDuty: json['user_duty'] as String?,
      attendanceDt: json['attendance_dt'] as String?,
      attendanceType: json['attendance_type'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      locationName: json['location_name'] as String?,
      shiftName: json['shift_name'] as String?,
      shiftColor: json['shift_color'] as String?,
      shiftTimeWindow: json['shift_time_window'] as String?,
      groupName: json['group_name'] as String?,
    );
  }

  /// Identifier unik absensi (AbsenID).
  final String id;

  /// Kategori absensi ('masuk', 'pulang', 'lainnya').
  final String category;

  /// Selisih waktu keterlambatan dalam menit (ADiffMins).
  final int diffMinutes;

  /// Email personil/petugas (AbsenEmail).
  final String? userEmail;

  /// Nama personil/petugas (UserName / AbsenName).
  final String? userName;

  /// URL atau nama file foto profil pengguna (UserProfilePic).
  final String? userProfilePic;

  /// Status dinas pengguna (UserDuty).
  final String? userDuty;

  /// Waktu absensi dalam format ISO 8601 atau string tanggal mentah (AbsenDT).
  final String? attendanceDt;

  /// Tipe absensi (AbsenType).
  final String? attendanceType;

  /// Koordinat garis lintang GPS (ALat).
  final String? latitude;

  /// Koordinat garis bujur GPS (ALong).
  final String? longitude;

  /// Nama lokasi atau pos absensi (ALocation).
  final String? locationName;

  /// Nama shift kerja (ShiftName).
  final String? shiftName;

  /// Aksen kode warna shift kerja (ShiftColor).
  final String? shiftColor;

  /// Rentang jam kerja shift terformat (misal: "07:00 - 15:00").
  final String? shiftTimeWindow;

  /// Nama grup kawasan (GroupName).
  final String? groupName;

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
