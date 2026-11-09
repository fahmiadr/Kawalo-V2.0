import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kawalo_mobile/core/network/json_converters.dart';

part 'operational_model.g.dart';

/// Model serialisasi JSON untuk satu aktivitas linimasa tugas operasional
/// (`OperationalTimelineItemDto`).
///
/// Merupakan Pure DTO tanpa logika bisnis, tanpa fallback, dan tanpa sanitasi,
/// mengikuti standar `AttendanceModel`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DutyTimelineModel extends Equatable {
  const DutyTimelineModel({
    required this.id,
    this.journeyUid,
    this.duty,
    this.state,
    this.dutyDt,
    this.stateDt,
  });

  factory DutyTimelineModel.fromJson(Map<String, dynamic> json) =>
      _$DutyTimelineModelFromJson(json);

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
  List<Object?> get props => [id, journeyUid, duty, state, dutyDt, stateDt];
}

/// Model data personil tenaga kerja operasional yang menangani parsing
/// JSON dari API backend (`OperationalWorkerItemDto`).
///
/// Merupakan Pure DTO tanpa logika bisnis, tanpa fallback, dan tanpa sanitasi,
/// mengikuti standar `AttendanceModel`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class OperationalModel extends Equatable {
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

  factory OperationalModel.fromJson(Map<String, dynamic> json) =>
      _$OperationalModelFromJson(json);

  /// ID unik kartu operasional (UserEmail_DutyDate).
  final String id;

  /// Alamat email personil operasional.
  final String userEmail;

  /// Total aktivitas yang tercatat.
  ///
  /// Aggregate column: may arrive as a decimal or be absent when the card
  /// has no activity, so it defaults to 0.
  @JsonKey(defaultValue: 0)
  @IntFromNumConverter()
  final int totalActivities;

  /// Linimasa kronologis tugas personil.
  @JsonKey(defaultValue: <DutyTimelineModel>[])
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
