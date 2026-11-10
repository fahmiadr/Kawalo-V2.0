import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule_model.g.dart';

/// Item of `GET /v1/schedules/me`. Fields the app does not show (shift uid,
/// check-in/out, late minutes) are ignored.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ScheduleModel extends Equatable {
  const ScheduleModel({
    required this.id,
    required this.date,
    this.shiftName,
    this.shiftColor,
    this.startTime,
    this.endTime,
    this.locationName,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);

  final String id;

  /// `YYYY-MM-DD`.
  final String date;

  final String? shiftName;

  final String? shiftColor;

  /// `HH:MM`.
  final String? startTime;

  /// `HH:MM`.
  final String? endTime;

  final String? locationName;

  @override
  List<Object?> get props => [
    id,
    date,
    shiftName,
    shiftColor,
    startTime,
    endTime,
    locationName,
  ];
}
