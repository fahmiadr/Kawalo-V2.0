import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';

/// Scriptable [UploadRepository] for form tests: uploads succeed with
/// `https://cdn.test/<name>` unless the file name is in [failing] (which then
/// stops failing after [healAfterFirstAttempt] is called).
class FakeUploadRepository implements UploadRepository {
  /// File names that fail with an Indonesian message.
  final Set<String> failing = <String>{};

  /// Names of images uploaded so far, in call order.
  final List<String> images = <String>[];

  /// Names of documents uploaded so far, in call order.
  final List<String> documents = <String>[];

  /// When set, every upload waits for this future before completing.
  Future<void>? gate;

  /// Highest number of uploads that were in flight at once.
  int maxInFlight = 0;
  int _inFlight = 0;

  /// Makes every previously failing file succeed on its next attempt.
  void healAfterFirstAttempt() => failing.clear();

  @override
  Future<Either<Failure, String>> uploadImage(
    AppMediaFile file, {
    UploadProgress? onProgress,
  }) {
    images.add(file.name);
    return _run(file, onProgress);
  }

  @override
  Future<Either<Failure, String>> uploadDocument(
    AppMediaFile file, {
    UploadProgress? onProgress,
  }) {
    documents.add(file.name);
    return _run(file, onProgress);
  }

  Future<Either<Failure, String>> _run(
    AppMediaFile file,
    UploadProgress? onProgress,
  ) async {
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    onProgress?.call(0.5);
    await gate;
    onProgress?.call(1);
    _inFlight--;
    if (failing.contains(file.name)) {
      return const Left(NetworkFailure('Koneksi terputus.'));
    }
    return Right('https://cdn.test/${file.name}');
  }
}
