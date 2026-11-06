import 'package:isar_community/isar.dart';

part 'operational_local_model.g.dart';

/// Skema objek tertanam (embedded) Isar untuk satu entri linimasa tugas
/// operasional.
@embedded
class DutyTimelineLocalModel {
  /// ID unik rekaman tugas.
  late String id;

  /// UID rekaman tugas.
  String? journeyUid;

  /// Nama / jenis tugas operasional (misal: "Patroli", "Standby").
  String? duty;

  /// Status / kondisi tugas operasional (misal: "Aktif", "Selesai").
  String? state;

  /// Waktu pelaksanaan tugas.
  String? dutyDt;

  /// Waktu status tugas tercatat.
  String? stateDt;
}

/// Skema tabel lokal Isar untuk persistensi kartu kerja operasional personil.
///
/// Urutan field selaras dengan DTO backend dan model domain data.
@collection
class OperationalLocalModel {
  /// Primary key internal Isar.
  Id isarId = Isar.autoIncrement;

  /// ID unik kartu operasional (composite key UserEmail_DutyDate).
  @Index(unique: true, replace: true)
  late String id;

  /// Token gabungan teks untuk pencarian cepat di layer lokal tanpa
  /// mendeserialisasi embedded timeline.
  @Index(caseSensitive: false)
  String? searchTokens;

  /// Alamat email personil operasional (UserEmail).
  late String userEmail;

  /// Total aktivitas yang tercatat.
  late int totalActivities;

  /// Nama personil operasional (UserName).
  String? userName;

  /// Tanggal kartu operasional (format "YYYY-MM-DD").
  @Index()
  String? dutyDate;

  /// URL atau nama file foto profil pengguna (UserProfilePic).
  String? userProfilePic;

  /// Nama grup operasional (DutyGroupName).
  String? groupName;

  /// Tugas terakhir yang tercatat (DutyDuty).
  String? latestDuty;

  /// Status/kondisi tugas terakhir (DutyState).
  String? latestState;

  /// Waktu pelaksanaan tugas terakhir (DutyDutyDT).
  String? latestDutyDt;

  /// Waktu status tugas terakhir (DutyStateDT).
  String? latestStateDt;

  /// Linimasa kronologis tugas personil.
  List<DutyTimelineLocalModel> timeline = [];
}
