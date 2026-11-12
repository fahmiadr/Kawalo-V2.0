import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/repositories/schedule_admin_repository.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_state.dart';

/// Month calendar of the whole group for the admin.
class ScheduleAdminCubit extends Cubit<ScheduleAdminState> {
  ScheduleAdminCubit({
    required this.repository,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock,
       super(_initial(clock()));

  static ScheduleAdminState _initial(DateTime now) {
    final today = dateOnly(now);
    return ScheduleAdminState(
      month: DateTime(today.year, today.month),
      selectedDay: today,
    );
  }

  final ScheduleAdminRepository repository;
  final DateTime Function() _clock;

  int _requestId = 0;

  DateTime get today => dateOnly(_clock());

  /// Loads the visible grid and returns whether it succeeded. With [silent]
  /// the content stays on screen and a failure keeps it.
  Future<bool> load({bool silent = false}) async {
    final id = ++_requestId;
    final keep = silent && state.status == ScheduleAdminStatus.loaded;
    if (!keep) emit(state.copyWith(status: ScheduleAdminStatus.loading));

    final month = state.month;
    final result = await repository.getSchedules(
      from: gridStart(month),
      to: gridEnd(month),
      email: state.filterEmail,
    );
    if (id != _requestId || isClosed) return false;

    final succeeded = result.fold(
      (failure) {
        if (!keep) {
          emit(
            state.copyWith(
              status: ScheduleAdminStatus.error,
              message: failure.message,
            ),
          );
        }
        return false;
      },
      (items) {
        emit(state.copyWith(status: ScheduleAdminStatus.loaded, items: items));
        return true;
      },
    );
    return succeeded;
  }

  Future<void> goToMonth(DateTime month, {DateTime? selectDay}) {
    final first = DateTime(month.year, month.month);
    emit(
      state.copyWith(
        month: first,
        selectedDay:
            selectDay ??
            (first.year == today.year && first.month == today.month
                ? today
                : first),
        items: const [],
      ),
    );
    return load();
  }

  /// Shows [day] after a change made elsewhere (form saved, forecast applied).
  Future<void> reveal(DateTime day) {
    final picked = dateOnly(day);
    if (picked.year != state.month.year || picked.month != state.month.month) {
      return goToMonth(picked, selectDay: picked);
    }
    emit(state.copyWith(selectedDay: picked));
    return load(silent: true);
  }

  Future<void> goToToday() => goToMonth(today, selectDay: today);

  Future<void> selectDay(DateTime day) {
    final picked = dateOnly(day);
    if (picked.year != state.month.year || picked.month != state.month.month) {
      return goToMonth(picked, selectDay: picked);
    }
    emit(state.copyWith(selectedDay: picked));
    return Future.value();
  }

  Future<void> setPersonFilter({String? email, String? name}) {
    emit(
      email == null
          ? state.copyWith(clearFilter: true)
          : state.copyWith(filterEmail: email, filterName: name),
    );
    return load();
  }

  /// Deletes [ids] and reloads. The server skips locked rows; the caller gets
  /// the counts to tell the user.
  Future<Either<Failure, DeleteSchedulesResult>> deleteMany(
    List<String> ids,
  ) async {
    final result = await repository.deleteMany(ids);
    if (!isClosed) await load(silent: true);
    return result;
  }
}
