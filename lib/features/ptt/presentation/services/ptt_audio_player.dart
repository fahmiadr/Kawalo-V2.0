import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Plays one local Ogg/Opus file at a time. Exists so the playback cubit can be
/// tested without the platform plugin.
abstract interface class PttAudioPlayer {
  Stream<Duration> get positionStream;

  /// Emits when the loaded file has played to its end.
  Stream<void> get completedStream;

  Future<void> load(String filePath);

  /// Starts playback without waiting for it to finish.
  void play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> stop();

  Future<void> dispose();
}

class JustAudioPttPlayer implements PttAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<void> get completedStream => _player.processingStateStream.where(
    (state) => state == ProcessingState.completed,
  );

  @override
  Future<void> load(String filePath) => _player.setFilePath(filePath);

  // just_audio's play() resolves only when playback pauses or ends.
  @override
  void play() => unawaited(_player.play());

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
