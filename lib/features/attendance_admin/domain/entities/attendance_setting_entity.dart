import 'package:equatable/equatable.dart';

/// Per-group attendance rule: how similar a face must be to pass check-in/out.
class AttendanceSettingEntity extends Equatable {
  const AttendanceSettingEntity({
    required this.faceMatchPercent,
    required this.defaultPercent,
    required this.minPercent,
    required this.maxPercent,
    required this.isDefault,
    this.updatedBy,
    this.updatedAt,
  });

  final int faceMatchPercent;
  final int defaultPercent;
  final int minPercent;
  final int maxPercent;
  final bool isDefault;
  final String? updatedBy;
  final String? updatedAt;

  @override
  List<Object?> get props => [
    faceMatchPercent,
    defaultPercent,
    minPercent,
    maxPercent,
    isDefault,
    updatedBy,
    updatedAt,
  ];
}
