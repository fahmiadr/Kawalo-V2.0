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
    this.locationName,
    this.latitude,
    this.longitude,
    this.radius,
  });

  factory ShiftRequestModel.fromInput(ShiftInput input) => ShiftRequestModel(
    name: input.name,
    startTime: input.startTime.toString(),
    endTime: input.endTime.toString(),
    color: input.color,
    description: input.description,
    locationName: input.locationName,
    latitude: input.latitude,
    longitude: input.longitude,
    radius: input.radius,
  );

  final String name;
  final String startTime;
  final String endTime;
  final String color;
  final String? description;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? radius;

  /// Optional fields are sent as explicit nulls: PUT replaces the shift, so
  /// they must clear what was stored.
  Map<String, dynamic> toJson() => {
    'name': name,
    'start_time': startTime,
    'end_time': endTime,
    'color': color,
    'description': description,
    'location_name': locationName,
    'glat': latitude,
    'glong': longitude,
    'radius': radius,
  };

  @override
  List<Object?> get props => [
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
