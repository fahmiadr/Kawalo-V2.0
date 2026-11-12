import 'package:equatable/equatable.dart';

/// A shift of the active group that a schedule can point to.
class ShiftOptionEntity extends Equatable {
  const ShiftOptionEntity({
    required this.uid,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.color,
    this.locationName,
  });

  final String uid;
  final String name;

  /// Zero-padded `HH:MM`.
  final String startTime;
  final String endTime;

  final String? color;
  final String? locationName;

  @override
  List<Object?> get props => [
    uid,
    name,
    startTime,
    endTime,
    color,
    locationName,
  ];
}
