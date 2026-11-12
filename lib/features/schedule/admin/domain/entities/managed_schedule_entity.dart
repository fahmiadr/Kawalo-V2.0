import 'package:equatable/equatable.dart';

/// One scheduled person-shift as the group admin sees it.
class ManagedScheduleEntity extends Equatable {
  const ManagedScheduleEntity({
    required this.id,
    required this.date,
    required this.email,
    required this.name,
    required this.isMember,
    required this.locked,
    this.shiftUid,
    this.shiftName,
    this.shiftColor,
    this.startTime,
    this.endTime,
    this.locationName,
    this.checkin,
    this.checkout,
    this.lateMins = 0,
    this.avatarUrl,
  });

  final String id;

  /// Calendar day at local midnight.
  final DateTime date;

  final String email;

  final String name;

  /// `false` once the person left the group; the row stays so it can be deleted.
  final bool isMember;

  /// Past or already attended: the server rejects edits and deletes.
  final bool locked;

  /// Shift fields are `null` when the shift row no longer exists (legacy data).
  final String? shiftUid;
  final String? shiftName;
  final String? shiftColor;

  /// Zero-padded `HH:MM`.
  final String? startTime;
  final String? endTime;

  final String? locationName;

  /// `HH:MM` of the attendance, `null` while not attended.
  final String? checkin;
  final String? checkout;

  final int lateMins;

  final String? avatarUrl;

  bool get hasCheckin => checkin != null;

  String get displayName => name.trim().isEmpty ? email : name;

  @override
  List<Object?> get props => [
    id,
    date,
    email,
    name,
    isMember,
    locked,
    shiftUid,
    shiftName,
    shiftColor,
    startTime,
    endTime,
    locationName,
    checkin,
    checkout,
    lateMins,
    avatarUrl,
  ];
}
