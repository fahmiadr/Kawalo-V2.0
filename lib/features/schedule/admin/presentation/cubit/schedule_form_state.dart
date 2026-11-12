import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/shift_option_entity.dart';

enum ScheduleFormStatus {
  loadingOptions,
  optionsError,
  ready,
  saving,
  saved,
  failed,
}

class ScheduleFormState extends Equatable {
  const ScheduleFormState({
    this.status = ScheduleFormStatus.loadingOptions,
    this.members = const [],
    this.shifts = const [],
    this.message,
    this.canOverwrite = false,
    this.result,
  });

  final ScheduleFormStatus status;
  final List<GroupMemberEntity> members;
  final List<ShiftOptionEntity> shifts;

  /// Server error text on failure, or the summary shown after saving.
  final String? message;

  /// The failure is the "person already has another shift that day" conflict,
  /// which the admin may resolve by replacing the old schedule.
  final bool canOverwrite;

  /// Set after a bulk request; the screen offers to replace skipped rows.
  final BulkScheduleResult? result;

  ScheduleFormState copyWith({
    ScheduleFormStatus? status,
    List<GroupMemberEntity>? members,
    List<ShiftOptionEntity>? shifts,
    String? message,
    bool canOverwrite = false,
    BulkScheduleResult? result,
  }) => ScheduleFormState(
    status: status ?? this.status,
    members: members ?? this.members,
    shifts: shifts ?? this.shifts,
    message: message,
    canOverwrite: canOverwrite,
    result: result,
  );

  @override
  List<Object?> get props => [
    status,
    members,
    shifts,
    message,
    canOverwrite,
    result,
  ];
}
