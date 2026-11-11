import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_transcript_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_transcript.dart';

/// App-level sender of the native `transcriptReady` reports, independent of
/// any screen. Every report is queued first (Isar) and then uploaded; the
/// queue is retried on start, when a session with a group appears, on app
/// resume and when connectivity comes back, plus by timer while the server
/// has not written the recording yet.
///
/// Reports that arrive without a session belong to whoever was signed in
/// before; they are dropped (the server worker transcribes those turns).
class PttTranscriptUploader with WidgetsBindingObserver {
  PttTranscriptUploader({
    required this.repository,
    required Stream<PttTranscript> transcripts,
    required Stream<bool> connectivity,
    required this.session,
  }) : _transcripts = transcripts,
       _connectivity = connectivity;

  final PttTranscriptRepository repository;
  final UserSessionCubit session;
  final Stream<PttTranscript> _transcripts;
  final Stream<bool> _connectivity;

  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _timer;
  Future<void>? _running;
  bool _rerun = false;
  bool _rerunForced = false;
  bool _online = true;
  bool _disposed = false;

  bool get _hasSession => session.state?.groupUid?.isNotEmpty ?? false;

  void start() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } on Object catch (_) {}
    _subscriptions
      ..add(_transcripts.listen(_onTranscript))
      ..add(
        _connectivity.listen((online) {
          final regained = online && !_online;
          _online = online;
          if (regained) unawaited(flush(force: true));
        }),
      )
      ..add(
        session.stream
            .map<AuthSessionEntity?>((s) => s)
            .distinct((a, b) => a?.groupUid == b?.groupUid)
            .listen((_) {
              if (_hasSession) unawaited(flush(force: true));
            }),
      );
    unawaited(flush(force: true));
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } on Object catch (_) {}
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(flush(force: true));
  }

  Future<void> _onTranscript(PttTranscript transcript) async {
    developer.log(
      'Turn ${transcript.requestId}: ${transcript.status.name} '
      '(${transcript.reason ?? '-'})',
      name: 'PttTranscript',
    );
    if (!_hasSession) return;
    try {
      await repository.enqueue(transcript);
    } on Object catch (e) {
      developer.log('Queueing failed: $e', name: 'PttTranscript');
      return;
    }
    await flush();
  }

  /// Serialized: a call during a running flush schedules one more pass.
  Future<void> flush({bool force = false}) async {
    if (_disposed) return;
    final running = _running;
    if (running != null) {
      _rerun = true;
      _rerunForced |= force;
      return await running;
    }
    final pass = _flushLoop(force);
    _running = pass;
    try {
      await pass;
    } finally {
      _running = null;
    }
  }

  Future<void> _flushLoop(bool force) async {
    var forced = force;
    do {
      _rerun = false;
      _rerunForced = false;
      if (!_hasSession || _disposed) return;
      _timer?.cancel();
      Duration? wait;
      try {
        wait = await repository.flush(force: forced);
      } on Object catch (e) {
        developer.log('Flush failed: $e', name: 'PttTranscript');
      }
      if (wait != null && !_disposed) {
        _timer = Timer(wait, () => unawaited(flush()));
      }
      forced = _rerunForced;
    } while (_rerun);
  }
}
