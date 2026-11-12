import 'package:equatable/equatable.dart';

/// Payload of one schedule to create or move.
class ScheduleEntry extends Equatable {
  const ScheduleEntry({
    required this.email,
    required this.shiftUid,
    required this.date,
  });

  final String email;
  final String shiftUid;
  final DateTime date;

  @override
  List<Object?> get props => [email, shiftUid, date];
}

/// An entry the server left out of a bulk request.
class SkippedEntry extends Equatable {
  const SkippedEntry({required this.index, required this.reason, this.code});

  /// Position in the request.
  final int index;

  /// Indonesian text from the server.
  final String reason;

  /// Machine-readable conflict code; only set when the app acts on it.
  final String? code;

  @override
  List<Object?> get props => [index, reason, code];
}

class BulkScheduleResult extends Equatable {
  const BulkScheduleResult({
    required this.created,
    required this.replaced,
    required this.skipped,
    required this.skippedItems,
  });

  final int created;

  /// Rows removed to make room (only with `overwrite`).
  final int replaced;

  final int skipped;

  final List<SkippedEntry> skippedItems;

  @override
  List<Object?> get props => [created, replaced, skipped, skippedItems];
}

class DeleteSchedulesResult extends Equatable {
  const DeleteSchedulesResult({
    required this.deletedCount,
    required this.skippedCount,
  });

  final int deletedCount;

  /// Locked or already gone.
  final int skippedCount;

  @override
  List<Object?> get props => [deletedCount, skippedCount];
}
