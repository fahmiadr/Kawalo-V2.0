import 'package:equatable/equatable.dart';

/// One work shift assigned to the signed-in user on a calendar day.
class ScheduleEntity extends Equatable {
  const ScheduleEntity({
    required this.id,
    required this.date,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    this.shiftColor,
    this.locationName,
  });

  final String id;

  /// Calendar day of the shift at local midnight.
  final DateTime date;

  final String shiftName;

  /// Zero-padded `HH:MM`.
  final String startTime;

  /// Zero-padded `HH:MM`. A value not after [startTime] means the shift ends
  /// on the following day.
  final String endTime;

  final String? shiftColor;

  final String? locationName;

  @override
  List<Object?> get props => [
    id,
    date,
    shiftName,
    startTime,
    endTime,
    shiftColor,
    locationName,
  ];
}
