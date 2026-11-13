import 'package:equatable/equatable.dart';

/// The single per-group attendance point; check-in/out is valid only within
/// [radius] metres of it. When [configured] is false the point and radius are
/// null.
class AttendanceLocationEntity extends Equatable {
  const AttendanceLocationEntity({
    required this.configured,
    required this.minRadius,
    required this.maxRadius,
    this.locationName,
    this.latitude,
    this.longitude,
    this.radius,
    this.updatedBy,
    this.updatedAt,
  });

  final bool configured;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  /// Metres.
  final int? radius;
  final int minRadius;
  final int maxRadius;
  final String? updatedBy;
  final String? updatedAt;

  @override
  List<Object?> get props => [
    configured,
    locationName,
    latitude,
    longitude,
    radius,
    minRadius,
    maxRadius,
    updatedBy,
    updatedAt,
  ];
}
