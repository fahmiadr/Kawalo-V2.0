import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';

class ShiftEntity extends Equatable {
  const ShiftEntity({
    required this.uid,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.description,
    this.locationName,
    this.latitude,
    this.longitude,
    this.radius,
  });

  final String uid;
  final String name;
  final ShiftClock startTime;
  final ShiftClock endTime;

  /// `#RRGGBB`; legacy rows may hold colours outside the app palette.
  final String color;
  final String? description;
  final String? locationName;

  /// Both coordinates are null when attendance is not limited to a location.
  final double? latitude;
  final double? longitude;

  /// Metres; non-null exactly when the coordinates are.
  final int? radius;

  bool get hasLocation => latitude != null && longitude != null;

  bool get endsNextDay => startTime.endsNextDay(endTime);

  int get durationMinutes => startTime.minutesUntil(endTime);

  @override
  List<Object?> get props => [
    uid,
    name,
    startTime,
    endTime,
    color,
    description,
    locationName,
    latitude,
    longitude,
    radius,
  ];
}
