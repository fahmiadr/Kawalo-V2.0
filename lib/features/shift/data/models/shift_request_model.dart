import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_input.dart';

/// Body of `POST /v1/shifts` and `PUT /v1/shifts/{uid}`.
class ShiftRequestModel extends Equatable {
  const ShiftRequestModel({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.description,
  });

  factory ShiftRequestModel.fromInput(ShiftInput input) => ShiftRequestModel(
    name: input.name,
    startTime: input.startTime.toString(),
    endTime: input.endTime.toString(),
    color: input.color,
    description: input.description,
  );

  final String name;
  final String startTime;
  final String endTime;
  final String color;
  final String? description;

  /// The description is sent as an explicit null: PUT replaces the shift, so
  /// it must clear what was stored.
  Map<String, dynamic> toJson() => {
    'name': name,
    'start_time': startTime,
    'end_time': endTime,
    'color': color,
    'description': description,
  };

  @override
  List<Object?> get props => [name, startTime, endTime, color, description];
}
