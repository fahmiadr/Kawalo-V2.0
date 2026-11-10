import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({
    required this.repository,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock,
       super(const ScheduleInitial());

  /// Days after today covered by a fetch (the API allows at most 62).
  static const horizonDays = 30;

  final ScheduleRepository repository;
  final DateTime Function() _clock;

  int _requestId = 0;

  /// Loads today plus the next [horizonDays] days and returns whether it
  /// succeeded. With [silent] (pull-to-refresh) the content on screen stays
  /// while loading, and a failure keeps it instead of replacing it by an error.
  Future<bool> fetch({bool silent = false}) async {
    final id = ++_requestId;
    final previous = state;
    final keepPrevious = silent && previous is ScheduleLoaded;
    if (!keepPrevious) emit(const ScheduleLoading());

    final now = _clock();
    final result = await repository.getMySchedules(
      from: DateTime(now.year, now.month, now.day),
      to: DateTime(now.year, now.month, now.day + horizonDays),
    );
    if (id != _requestId || isClosed) return false;

    final succeeded = result.fold(
      (failure) {
        if (!keepPrevious) emit(ScheduleError(failure.message));
        return false;
      },
      (schedules) {
        emit(ScheduleLoaded(schedules));
        return true;
      },
    );
    return succeeded;
  }
}
