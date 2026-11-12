import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kawalo_mobile/core/network/json_converters.dart';

part 'attendance_model.g.dart';

/// Data Transfer Object (DTO) untuk satu butir catatan absensi personil.
///
/// Selaras dengan payload DTO backend `AttendanceItemDto`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class AttendanceModel extends Equatable {
  const AttendanceModel({
    required this.id,
    required this.category,
    required this.diffMinutes,
    this.userEmail,
    this.userName,
    this.userProfilePic,
    this.avatarUrl,
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
    this.earlyLeaveMinutes,
    this.faceVerified,
    this.hasPhoto,
    this.faceSimilarityPercent,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);

  /// Identifier unik absensi (AbsenID).
  final String id;

  /// Kategori absensi ('masuk', 'pulang', 'lainnya').
  final String category;

  /// Selisih waktu keterlambatan dalam menit (ADiffMins).
  ///
  /// The server sends null while an attendance is still open; it maps to 0
  /// because the domain entity only accepts a non-null value.
  @JsonKey(defaultValue: 0)
  @IntFromNumConverter()
  final int diffMinutes;

  /// Email personil/petugas (AbsenEmail).
  final String? userEmail;

  /// Nama personil/petugas (UserName / AbsenName).
  final String? userName;

  /// URL atau nama file foto profil pengguna (UserProfilePic).
  final String? userProfilePic;

  /// Newer key for the same photo; preferred over [userProfilePic].
  final String? avatarUrl;

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

  /// Menit pulang lebih cepat dari akhir shift (AEarlyMins).
  @NullableIntFromNumConverter()
  final int? earlyLeaveMinutes;

  /// Hasil verifikasi wajah 1:1; null bila tidak diketahui.
  final bool? faceVerified;

  /// Apakah foto absensi tersedia untuk admin.
  final bool? hasPhoto;

  /// Cosine similarity (0..100); the API sends it to admin roles only.
  @NullableIntFromNumConverter()
  final int? faceSimilarityPercent;

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
