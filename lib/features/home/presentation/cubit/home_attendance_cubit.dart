import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';

sealed class HomeAttendanceState extends Equatable {
  const HomeAttendanceState();

  @override
  List<Object?> get props => [];
}

final class HomeAttendanceLoading extends HomeAttendanceState {
  const HomeAttendanceLoading();
}

final class HomeAttendanceLoaded extends HomeAttendanceState {
  const HomeAttendanceLoaded(this.plan);

  final AttendancePlan plan;

  @override
  List<Object?> get props => [plan];
}

/// Offline or server error. The card still offers the check screen, which
/// runs its own checks and explains the problem.
final class HomeAttendanceFailed extends HomeAttendanceState {
  const HomeAttendanceFailed();
}

/// Today's duty status for the "Lainnya" card: the same slots and
/// [planAttendance] forecast the check-in screen uses to label its button.
class HomeAttendanceCubit extends Cubit<HomeAttendanceState> {
  HomeAttendanceCubit({required this.repository, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const HomeAttendanceLoading());

  final AttendanceCheckRepository repository;
  final DateTime Function() _clock;

  Future<void> load() async {
    final now = _clock();
    final result = await repository.getSlots(now);
    if (isClosed) return;
    emit(
      result.fold(
        (_) => const HomeAttendanceFailed(),
        (slots) => HomeAttendanceLoaded(planAttendance(slots, now)),
      ),
    );
  }
}
