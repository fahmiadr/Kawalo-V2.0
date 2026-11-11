import 'package:isar_community/isar.dart';

part 'ptt_transcript_local_model.g.dart';

/// Outbox entry for one turn's transcript report that has not reached the
/// server yet. Removed once uploaded, rejected for good, or older than 24 h.
@collection
class PttTranscriptLocalModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String requestId;

  /// Wire status: `ok`, `unsupported` or `failed`.
  late String status;

  String? text;

  String? locale;

  @Index()
  late DateTime createdAt;

  int attempts = 0;

  /// Only meaningful while [state] is `pending`.
  late DateTime nextAttemptAt;

  /// `pending`: retried by timer at [nextAttemptAt] (the server has not
  /// written the recording yet). `parked`: waits for the next app start,
  /// login, resume or reconnect.
  late String state;
}
