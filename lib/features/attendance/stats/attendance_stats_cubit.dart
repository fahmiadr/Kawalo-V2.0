import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_repository.dart';

enum AttendanceStatsStatus { loading, loaded, failure }

class AttendanceStatsState extends Equatable {
  const AttendanceStatsState({
    this.status = AttendanceStatsStatus.loading,
    this.stats,
  });

  final AttendanceStatsStatus status;

  /// Kept while a reload runs so the card does not flash empty.
  final AttendanceStats? stats;

  @override
  List<Object?> get props => [status, stats];
}

class AttendanceStatsCubit extends Cubit<AttendanceStatsState> {
  AttendanceStatsCubit({required this.repository})
    : super(const AttendanceStatsState());

  final AttendanceStatsRepository repository;

  int _requestId = 0;

  Future<void> load({required String from, required String to}) async {
    final requestId = ++_requestId;
    emit(AttendanceStatsState(stats: state.stats));
    final result = await repository.getStats(from: from, to: to);
    // A newer range was requested meanwhile; its answer wins.
    if (isClosed || requestId != _requestId) return;
    emit(
      result.fold(
        (_) =>
            const AttendanceStatsState(status: AttendanceStatsStatus.failure),
        (stats) => AttendanceStatsState(
          status: AttendanceStatsStatus.loaded,
          stats: stats,
        ),
      ),
    );
  }
}
