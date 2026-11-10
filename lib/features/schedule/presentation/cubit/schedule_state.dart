import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';

sealed class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => const [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

/// [schedules] is empty when nothing is assigned in the window.
class ScheduleLoaded extends ScheduleState {
  const ScheduleLoaded(this.schedules);

  final List<ScheduleEntity> schedules;

  @override
  List<Object?> get props => [schedules];
}

class ScheduleError extends ScheduleState {
  const ScheduleError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
