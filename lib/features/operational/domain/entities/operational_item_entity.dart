import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/duty_timeline_entity.dart';

export 'package:kawalo_mobile/features/operational/domain/entities/duty_timeline_entity.dart';

/// Entitas domain murni personil tenaga kerja operasional yang menaungi
/// riwayat tugas.
class OperationalItemEntity extends Equatable {
  /// Membuat instance [OperationalItemEntity].
  const OperationalItemEntity({
    required this.id,
    required this.totalActivities,
    required this.userEmail,
    required this.timeline,
    this.userName,
    this.groupName,
    this.userProfilePic,
    this.latestDuty,
    this.latestState,
    this.latestDutyDt,
    this.latestStateDt,
    this.dutyDate,
  });

  /// ID unik kartu operasional (UserEmail_DutyDate).
  final String id;

  /// Alamat email tenaga kerja operasional (UserEmail).
  final String userEmail;

  /// Total aktivitas yang tercatat pada hari bersangkutan.
  final int totalActivities;

  /// Nama lengkap tenaga kerja operasional (UserName).
  final String? userName;

  /// Foto profil personil operasional (UserProfilePic).
  final String? userProfilePic;

  /// Nama grup operasional (DutyGroupName).
  final String? groupName;

  /// Tugas terakhir yang tercatat (DutyDuty).
  final String? latestDuty;

  /// Kondisi / status terakhir tugas (DutyState).
  final String? latestState;

  /// Waktu pelaksanaan tugas terakhir (DutyDutyDT).
  final String? latestDutyDt;

  /// Waktu status terakhir tugas (DutyStateDT).
  final String? latestStateDt;

  /// Tanggal kartu operasional (format "YYYY-MM-DD", opsional).
  final String? dutyDate;

  /// Linimasa kronologis tugas personil pada hari bersangkutan.
  final List<DutyTimelineEntity> timeline;

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
