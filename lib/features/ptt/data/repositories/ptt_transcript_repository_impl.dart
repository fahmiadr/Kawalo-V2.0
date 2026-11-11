import 'dart:developer' as developer;

import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_local_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_transcript_local_model.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_transcript_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_transcript.dart';

/// Retry rules for the outbox:
/// - 404: the server writes the recording only after the turn ends, so retry
///   with backoff for [notFoundWindow] after enqueueing. A 404 after that
///   window means the turn was never recorded (no frames, or the save failed:
///   `recorder.rs` then writes nothing), so the entry is dropped rather than
///   retried on every trigger for 24 h.
/// - other 4xx (400, 403, 409, 422, ...): permanent, drop.
/// - network errors, timeouts, 408, 429, 5xx, 401 after a failed refresh:
///   park until the next app start, login, resume or reconnect.
/// - entries older than [maxAge] are dropped; at most [maxEntries] are kept.
class PttTranscriptRepositoryImpl implements PttTranscriptRepository {
  PttTranscriptRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  static const maxEntries = 50;
  static const maxAge = Duration(hours: 24);
  static const notFoundWindow = Duration(minutes: 2);
  static const notFoundBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];

  static const _pending = 'pending';
  static const _parked = 'parked';

  final PttTranscriptRemoteDataSource remoteDataSource;
  final PttTranscriptLocalDataSource localDataSource;
  final DateTime Function() _now;

  @override
  Future<void> enqueue(PttTranscript transcript) async {
    final now = _now();
    await localDataSource.put(
      PttTranscriptLocalModel()
        ..requestId = transcript.requestId
        ..status = transcript.status.name
        ..text = transcript.text
        ..locale = transcript.locale
        ..createdAt = now
        ..nextAttemptAt = now
        ..state = _pending,
      maxEntries: maxEntries,
    );
  }

  @override
  Future<Duration?> flush({bool force = false}) async {
    DateTime? nextDue;
    // After a network-level failure the remaining entries would fail the same
    // way (and a dead session would 401 once per entry), so stop uploading.
    var stopped = false;
    for (final entry in await localDataSource.getAll()) {
      final now = _now();
      if (now.difference(entry.createdAt) > maxAge) {
        await localDataSource.delete(entry.requestId);
        continue;
      }
      final due = entry.state == _pending && !entry.nextAttemptAt.isAfter(now);
      if (stopped || (!force && !due)) {
        // Once stopped, the reconnect/resume trigger retries them instead.
        if (!stopped && entry.state == _pending) {
          nextDue = _earlier(nextDue, entry.nextAttemptAt);
        }
        continue;
      }

      final outcome = await _upload(entry);
      switch (outcome) {
        case _Outcome.done:
          await localDataSource.delete(entry.requestId);
        case _Outcome.notYetWritten:
          entry.attempts++;
          final at = _now();
          if (at.difference(entry.createdAt) < notFoundWindow) {
            final step =
                notFoundBackoff[(entry.attempts - 1).clamp(
                  0,
                  notFoundBackoff.length - 1,
                )];
            entry
              ..state = _pending
              ..nextAttemptAt = at.add(step);
            nextDue = _earlier(nextDue, entry.nextAttemptAt);
            await localDataSource.updateIfPresent(entry);
          } else {
            await localDataSource.delete(entry.requestId);
          }
        case _Outcome.retryLater:
          stopped = true;
          entry
            ..attempts += 1
            ..state = _parked;
          await localDataSource.updateIfPresent(entry);
      }
    }
    if (nextDue == null) return null;
    final wait = nextDue.difference(_now());
    return wait.isNegative ? Duration.zero : wait;
  }

  Future<_Outcome> _upload(PttTranscriptLocalModel entry) async {
    try {
      await remoteDataSource.putTranscript(
        requestId: entry.requestId,
        status: entry.status,
        text: entry.text,
        locale: entry.locale,
      );
      return _Outcome.done;
    } on ServerException catch (e) {
      final code = e.statusCode;
      if (code == 404) return _Outcome.notYetWritten;
      if (code != null &&
          code >= 400 &&
          code < 500 &&
          code != 408 &&
          code != 429) {
        developer.log(
          'Dropping transcript ${entry.requestId}: HTTP $code ${e.message}',
          name: 'PttTranscript',
        );
        return _Outcome.done;
      }
      return _Outcome.retryLater;
    } on Object {
      return _Outcome.retryLater;
    }
  }

  static DateTime _earlier(DateTime? a, DateTime b) =>
      a == null || b.isBefore(a) ? b : a;
}

enum _Outcome { done, notYetWritten, retryLater }
