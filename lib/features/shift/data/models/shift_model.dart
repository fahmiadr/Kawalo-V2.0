import 'package:equatable/equatable.dart';

/// Item of `/v1/shifts`. `crosses_midnight` and `duration_mins` are ignored:
/// the entity derives them from the clocks.
class ShiftModel extends Equatable {
  const ShiftModel({
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

  factory ShiftModel.fromJson(Map<String, dynamic> json) => ShiftModel(
    uid: json['uid'] as String? ?? '',
    name: json['name'] as String? ?? '',
    startTime: json['start_time'] as String? ?? '',
    endTime: json['end_time'] as String? ?? '',
    color: json['color'] as String? ?? '',
    description: json['description'] as String?,
    locationName: json['location_name'] as String?,
    latitude: (json['glat'] as num?)?.toDouble(),
    longitude: (json['glong'] as num?)?.toDouble(),
    radius: (json['radius'] as num?)?.toInt(),
  );

  final String uid;
  final String name;

  /// `HH:MM`.
  final String startTime;

  /// `HH:MM`.
  final String endTime;
  final String color;
  final String? description;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? radius;

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
