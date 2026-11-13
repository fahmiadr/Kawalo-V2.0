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
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) => ShiftModel(
    uid: json['uid'] as String? ?? '',
    name: json['name'] as String? ?? '',
    startTime: json['start_time'] as String? ?? '',
    endTime: json['end_time'] as String? ?? '',
    color: json['color'] as String? ?? '',
    description: json['description'] as String?,
  );

  final String uid;
  final String name;

  /// `HH:MM`.
  final String startTime;

  /// `HH:MM`.
  final String endTime;
  final String color;
  final String? description;

  @override
  List<Object?> get props => [
    uid,
    name,
    startTime,
    endTime,
    color,
    description,
  ];
}
