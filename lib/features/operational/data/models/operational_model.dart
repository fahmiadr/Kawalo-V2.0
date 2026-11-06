import 'package:equatable/equatable.dart';

/// Model serialisasi JSON untuk satu aktivitas linimasa tugas operasional
/// (`OperationalTimelineItemDto`).
///
/// Merupakan Pure DTO tanpa logika bisnis, tanpa fallback, dan tanpa sanitasi,
/// mengikuti standar `AttendanceModel`.
class DutyTimelineModel extends Equatable {
  /// Membuat instance [DutyTimelineModel].
  const DutyTimelineModel({
    required this.id,
    this.journeyUid,
    this.duty,
    this.state,
    this.dutyDt,
    this.stateDt,
  });

  /// Mengonversi map JSON dari backend menjadi objek [DutyTimelineModel]
  /// tanpa fallback ataupun sanitasi data.
  factory DutyTimelineModel.fromJson(Map<String, dynamic> json) {
    return DutyTimelineModel(
      id: json['id'] as String,
      journeyUid: json['journey_uid'] as String?,
      duty: json['duty'] as String?,
      state: json['state'] as String?,
      dutyDt: json['duty_dt'] as String?,
      stateDt: json['state_dt'] as String?,
    );
  }

  /// ID unik rekaman tugas.
  final String id;

  /// UID rekaman tugas.
  final String? journeyUid;

  /// Nama / jenis tugas operasional. Misal: "Patroli", "Standby".
  final String? duty;

  /// Status / kondisi tugas operasional. Misal: "Aktif", "Selesai".
  final String? state;

  /// Waktu pelaksanaan tugas.
  final String? dutyDt;

  /// Waktu status tugas tercatat.
  final String? stateDt;

  @override
  List<Object?> get props => [
        id,
        journeyUid,
        duty,
        state,
        dutyDt,
        stateDt,
      ];
}

/// Model data personil tenaga kerja operasional yang menangani parsing
/// JSON dari API backend (`OperationalWorkerItemDto`).
///
/// Merupakan Pure DTO tanpa logika bisnis, tanpa fallback, dan tanpa sanitasi,
/// mengikuti standar `AttendanceModel`.
class OperationalModel extends Equatable {
  /// Membuat instance [OperationalModel].
  const OperationalModel({
    required this.id,
    required this.userEmail,
    required this.totalActivities,
    required this.timeline,
    this.userName,
    this.userProfilePic,
    this.groupName,
    this.latestDuty,
    this.latestState,
    this.latestDutyDt,
    this.latestStateDt,
    this.dutyDate,
  });

  /// Mengonversi map JSON dari backend menjadi objek [OperationalModel]
  /// tanpa fallback ataupun sanitasi data.
  factory OperationalModel.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'] as List<dynamic>;

    return OperationalModel(
      id: json['id'] as String,
      userEmail: json['user_email'] as String,
      totalActivities: json['total_activities'] as int,
      userName: json['user_name'] as String?,
      userProfilePic: json['user_profile_pic'] as String?,
      groupName: json['group_name'] as String?,
      latestDuty: json['latest_duty'] as String?,
      latestState: json['latest_state'] as String?,
      latestDutyDt: json['latest_duty_dt'] as String?,
      latestStateDt: json['latest_state_dt'] as String?,
      dutyDate: json['duty_date'] as String?,
      timeline: rawTimeline
          .map(
            (item) => DutyTimelineModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// ID unik kartu operasional (UserEmail_DutyDate).
  final String id;

  /// Alamat email personil operasional.
  final String userEmail;

  /// Total aktivitas yang tercatat.
  final int totalActivities;

  /// Linimasa kronologis tugas personil.
  final List<DutyTimelineModel> timeline;

  /// Nama personil operasional.
  final String? userName;

  /// Foto profil personil.
  final String? userProfilePic;

  /// Nama grup operasional.
  final String? groupName;

  /// Tugas terakhir yang tercatat.
  final String? latestDuty;

  /// Kondisi / status terakhir tugas.
  final String? latestState;

  /// Waktu pelaksanaan tugas terakhir.
  final String? latestDutyDt;

  /// Waktu status terakhir tugas.
  final String? latestStateDt;

  /// Tanggal kartu operasional (format "YYYY-MM-DD").
  final String? dutyDate;

  @override
  List<Object?> get props => [
        id,
        userEmail,
        totalActivities,
        userName,
        userProfilePic,
        groupName,
        latestDuty,
        latestState,
        latestDutyDt,
        latestStateDt,
        dutyDate,
        timeline,
      ];
}
