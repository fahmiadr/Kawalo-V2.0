import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_recording_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/mappers/ptt_recording_mapper.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_recording_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_recording_page.dart';
import 'package:path_provider/path_provider.dart';

class PttRecordingRepositoryImpl implements PttRecordingRepository {
  PttRecordingRepositoryImpl({
    required this.remoteDataSource,
    Future<Directory> Function() temporaryDirectory = getTemporaryDirectory,
  }) : _temporaryDirectory = temporaryDirectory;

  final PttRecordingRemoteDataSource remoteDataSource;
  final Future<Directory> Function() _temporaryDirectory;

  Future<Directory> _audioDirectory() async {
    final root = await _temporaryDirectory();
    return Directory('${root.path}/ptt_recordings');
  }

  @override
  Future<Either<Failure, PttRecordingPage>> getRecordings({
    String? before,
    int? limit,
  }) async {
    try {
      final model = await remoteDataSource.getRecordings(
        before: before,
        limit: limit,
      );
      return Right(PttRecordingMapper.toPage(model));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> fetchAudio(String id) async {
    try {
      final directory = await _audioDirectory();
      final file = File('${directory.path}/$id.ogg');
      if (file.existsSync() && file.lengthSync() > 0) return Right(file.path);

      await directory.create(recursive: true);
      // Download to a side file so an interrupted transfer never leaves a
      // truncated .ogg that the check above would later reuse.
      final partial = '${file.path}.part';
      await remoteDataSource.downloadAudio(id, partial);
      await File(partial).rename(file.path);
      return Right(file.path);
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecording(String id) async {
    try {
      await remoteDataSource.deleteRecording(id);
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
    try {
      final file = File('${(await _audioDirectory()).path}/$id.ogg');
      if (file.existsSync()) await file.delete();
    } on Object catch (_) {
      // The recording is already gone on the server; the cache is cleared on
      // leaving the history screen anyway.
    }
    return const Right(null);
  }

  @override
  Future<void> clearAudioCache() async {
    try {
      final directory = await _audioDirectory();
      if (directory.existsSync()) await directory.delete(recursive: true);
    } on Object catch (_) {
      // The OS clears the temporary directory eventually.
    }
  }
}
