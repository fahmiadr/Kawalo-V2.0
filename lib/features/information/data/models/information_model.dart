import 'package:equatable/equatable.dart';

/// Model serialisasi data feed informasi untuk pertukaran data JSON dengan API
/// (`InformationItemDto`).
///
/// Merupakan Pure DTO tanpa logika bisnis, tanpa fallback, dan tanpa sanitasi,
/// mengikuti standar `AttendanceModel`.
class InformationModel extends Equatable {
  /// Membuat instance [InformationModel].
  const InformationModel({
    required this.id,
    required this.photos,
    this.title,
    this.text,
    this.userEmail,
    this.userName,
    this.userProfilePic,
    this.feedDt,
    this.feedFile,
    this.feedType,
    this.groupName,
    this.eventLocation,
    this.eventStartDt,
    this.eventEndDt,
    this.eventDuration,
    this.glat,
    this.glong,
  });

  /// Mengonversi JSON Map dari backend menjadi objek [InformationModel]
  /// tanpa fallback ataupun sanitasi data.
  factory InformationModel.fromJson(Map<String, dynamic> json) {
    return InformationModel(
      id: json['id'] as String,
      photos: (json['photos'] as List<dynamic>).cast<String>().toList(),
      title: json['title'] as String?,
      text: json['text'] as String?,
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
      userProfilePic: json['user_profile_pic'] as String?,
      feedDt: json['feed_dt'] as String?,
      feedFile: json['feed_file'] as String?,
      feedType: json['feed_type'] as String?,
      groupName: json['group_name'] as String?,
      eventLocation: json['event_location'] as String?,
      eventStartDt: json['event_start_dt'] as String?,
      eventEndDt: json['event_end_dt'] as String?,
      eventDuration: json['event_duration'] as int?,
      glat: json['glat'] as String?,
      glong: json['glong'] as String?,
    );
  }

  /// ID unik internal baris data.
  final String id;

  /// Daftar berkas foto feed.
  final List<String> photos;

  /// Judul informasi.
  final String? title;

  /// Deskripsi isi informasi lengkap.
  final String? text;

  /// Email pembuat feed.
  final String? userEmail;

  /// Nama pembuat feed.
  final String? userName;

  /// URL foto profil pembuat feed.
  final String? userProfilePic;

  /// Waktu pembuatan feed.
  final String? feedDt;

  /// Berkas lampiran feed.
  final String? feedFile;

  /// Tipe informasi (GENERAL, INCIDENT, JOIN, EVENT, OTHER).
  final String? feedType;

  /// Nama grup / kawasan.
  final String? groupName;

  /// Lokasi acara atau tempat kejadian.
  final String? eventLocation;

  /// Waktu mulai acara.
  final String? eventStartDt;

  /// Waktu selesai acara.
  final String? eventEndDt;

  /// Durasi acara.
  final int? eventDuration;

  /// Garis lintang GPS.
  final String? glat;

  /// Garis bujur GPS.
  final String? glong;

  @override
  List<Object?> get props => [
        id,
        photos,
        title,
        text,
        userEmail,
        userName,
        userProfilePic,
        feedDt,
        feedFile,
        feedType,
        groupName,
        eventLocation,
        eventStartDt,
        eventEndDt,
        eventDuration,
        glat,
        glong,
      ];
}
