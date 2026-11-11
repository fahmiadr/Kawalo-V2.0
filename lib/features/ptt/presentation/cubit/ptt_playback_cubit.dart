import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_recording_repository.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/services/ptt_audio_player.dart';

/// Plays recordings one at a time. The audio endpoint needs the access token,
/// so the file is fetched through the repository (`ApiClient`, which refreshes
/// an expired token) and then played from disk.
class PttPlaybackCubit extends Cubit<PttPlaybackState> {
  PttPlaybackCubit({
    required PttRecordingRepository repository,
    required PttAudioPlayer player,
  }) : _repository = repository,
       _player = player,
       super(const PttPlaybackState()) {
    _positionSub = _player.positionStream.listen(_onPosition);
    _completedSub = _player.completedStream.listen((_) => _onCompleted());
  }

  final PttRecordingRepository _repository;
  final PttAudioPlayer _player;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<void> _completedSub;

  /// Bumped whenever a different recording is requested or playback is
  /// stopped, so a slow download of a superseded request is dropped.
  int _request = 0;

  void _onPosition(Duration position) {
    if (state.status == PttPlaybackStatus.playing) {
      emit(state.copyWith(position: position));
    }
  }

  void _onCompleted() {
    if (state.activeId == null) return;
    _request++;
    emit(state.idle());
  }

  Future<void> toggle(PttRecordingEntity recording) async {
    if (state.isActive(recording.id)) {
      switch (state.status) {
        case PttPlaybackStatus.playing:
          emit(state.copyWith(status: PttPlaybackStatus.paused));
          await _player.pause();
          return;
        case PttPlaybackStatus.paused:
          emit(state.copyWith(status: PttPlaybackStatus.playing));
          _player.play();
          return;
        case PttPlaybackStatus.loading:
          return;
        case PttPlaybackStatus.idle:
          break;
      }
    }

    final request = ++_request;
    await _player.stop();
    emit(
      PttPlaybackState(
        activeId: recording.id,
        status: PttPlaybackStatus.loading,
        errorSeq: state.errorSeq,
      ),
    );

    final result = await _repository.fetchAudio(recording.id);
    if (request != _request || isClosed) return;
    final path = result.fold<String?>((failure) {
      emit(state.failed(failure.message));
      return null;
    }, (path) => path);
    if (path == null) return;

    try {
      await _player.load(path);
    } on Object catch (_) {
      if (request == _request && !isClosed) {
        emit(state.failed('Rekaman tidak dapat diputar.'));
      }
      return;
    }
    if (request != _request || isClosed) return;
    emit(state.copyWith(status: PttPlaybackStatus.playing));
    _player.play();
  }

  /// Only the recording that is loaded can be seeked.
  Future<void> seek(String id, Duration position) async {
    if (!state.isActive(id) ||
        state.status == PttPlaybackStatus.loading ||
        state.status == PttPlaybackStatus.idle) {
      return;
    }
    emit(state.copyWith(position: position));
    await _player.seek(position);
  }

  /// Used before a recording is deleted, so nothing keeps playing from it.
  Future<void> stopIfActive(String id) async {
    if (!state.isActive(id)) return;
    _request++;
    emit(state.idle());
    await _player.stop();
  }

  @override
  Future<void> close() async {
    _request++;
    await _positionSub.cancel();
    await _completedSub.cancel();
    await _player.dispose();
    await _repository.clearAudioCache();
    await super.close();
  }
}
