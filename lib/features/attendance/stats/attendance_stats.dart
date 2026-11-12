import 'package:equatable/equatable.dart';

/// Counts for `GET /attendance/stats`, computed by the server over the whole
/// date range (not only the rows loaded in the list).
class AttendanceStats extends Equatable {
  const AttendanceStats({
    required this.total,
    required this.checkIn,
    required this.checkOut,
    required this.late,
    required this.earlyLeave,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AttendanceStats(
      total: count('total'),
      checkIn: count('check_in'),
      checkOut: count('check_out'),
      late: count('late'),
      earlyLeave: count('early_leave'),
    );
  }

  final int total;
  final int checkIn;
  final int checkOut;

  /// Check-ins with late minutes.
  final int late;

  /// Check-outs before the shift end.
  final int earlyLeave;

  @override
  List<Object?> get props => [total, checkIn, checkOut, late, earlyLeave];
}
