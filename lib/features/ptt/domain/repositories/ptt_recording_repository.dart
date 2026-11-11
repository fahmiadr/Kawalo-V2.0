import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_recording_page.dart';

abstract interface class PttRecordingRepository {
  Future<Either<Failure, PttRecordingPage>> getRecordings({
    String? before,
    int? limit,
  });

  /// Downloads the (authenticated) audio of [id] and returns the local file
  /// path. A file already fetched in this session is reused.
  Future<Either<Failure, String>> fetchAudio(String id);

  Future<Either<Failure, void>> deleteRecording(String id);

  /// Removes every audio file fetched by [fetchAudio]; recordings are private
  /// so nothing should outlive the history screen.
  Future<void> clearAudioCache();
}
