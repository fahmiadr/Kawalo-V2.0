import 'package:isar_community/isar.dart';

part 'information_local_model.g.dart';

/// Skema tabel lokal Isar untuk persistensi data informasi / feed.
///
/// Urutan field identik dengan DTO backend dan model domain data.
@collection
class InformationLocalModel {
  /// Primary key internal Isar.
  Id isarId = Isar.autoIncrement;

  /// Identifier unik feed (FeedID).
  @Index(unique: true, replace: true)
  late String id;

  /// Daftar URL atau path berkas foto valid publikasi.
  late List<String> photos;

  /// Judul informasi (FeedTitle).
  @Index(caseSensitive: false)
  String? title;

  /// Deskripsi isi informasi lengkap (FeedText).
  @Index(caseSensitive: false)
  String? text;

  /// Email personil pembuat feed (FeedByEmail / user_email).
  @Index(caseSensitive: false)
  String? userEmail;

  /// Nama personil pembuat feed (FeedByName / user_name).
  @Index(caseSensitive: false)
  String? userName;

  /// Waktu pembuatan feed (FeedDT).
  @Index()
  String? feedDt;

  /// Tipe informasi (FeedType: GENERAL, INCIDENT, EVENT, dll.).
  @Index(caseSensitive: false)
  String? feedType;

  /// Lokasi acara atau tempat kejadian (FeedEventLocation).
  @Index(caseSensitive: false)
  String? eventLocation;

  /// URL atau nama file foto profil pembuat feed (FeedByProfilePic).
  String? userProfilePic;

  /// Berkas lampiran feed (FeedFile).
  String? feedFile;

  /// Nama grup kawasan (FeedGroupName).
  String? groupName;

  /// Waktu mulai acara (FeedEventStartDT).
  String? eventStartDt;

  /// Waktu selesai acara (FeedEventEndDT).
  String? eventEndDt;

  /// Durasi acara (FeedEventDuration).
  int? eventDuration;

  /// Koordinat garis lintang GPS (GLat).
  String? glat;

  /// Koordinat garis bujur GPS (GLong).
  String? glong;
}
