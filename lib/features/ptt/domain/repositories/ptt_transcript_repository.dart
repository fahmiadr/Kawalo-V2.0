import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_transcript.dart';

/// Persistent outbox for the transcript reports of the user's own turns.
abstract interface class PttTranscriptRepository {
  /// Stores [transcript] (one entry per `requestId`), due at once.
  Future<void> enqueue(PttTranscript transcript);

  /// Uploads due entries, oldest first. With [force] every entry is tried,
  /// including parked ones and those still backing off. Returns how long until
  /// the earliest backing-off entry is due, or `null` when none is.
  Future<Duration?> flush({bool force = false});
}
