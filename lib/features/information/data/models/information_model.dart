import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kawalo_mobile/core/network/json_converters.dart';

part 'information_model.g.dart';

/// Model serialisasi data feed informasi untuk pertukaran data JSON dengan API
/// (`InformationItemDto`).
///
/// Merupakan Pure DTO tanpa logika bisnis dan tanpa sanitasi,
/// mengikuti standar `AttendanceModel`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class InformationModel extends Equatable {
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

  factory InformationModel.fromJson(Map<String, dynamic> json) =>
      _$InformationModelFromJson(json);

  /// ID unik internal baris data.
  final String id;

  /// Daftar berkas foto feed.
  ///
  /// A missing or null list becomes empty; the mapper and entity already
  /// treat "no photos" as an empty list.
  @JsonKey(defaultValue: <String>[])
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
  @NullableIntFromNumConverter()
  final int? eventDuration;

  /// Garis lintang GPS.
  @StringFromNumOrStringConverter()
  final String? glat;

  /// Garis bujur GPS.
  @StringFromNumOrStringConverter()
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
