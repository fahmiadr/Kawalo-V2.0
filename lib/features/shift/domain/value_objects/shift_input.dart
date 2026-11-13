import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';

/// A validated shift ready to be sent; PUT replaces the whole shift, so an
/// absent optional field clears it.
class ShiftInput extends Equatable {
  const ShiftInput({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.description,
  });

  final String name;
  final ShiftClock startTime;
  final ShiftClock endTime;
  final String color;
  final String? description;

  @override
  List<Object?> get props => [name, startTime, endTime, color, description];
}
