import 'package:equatable/equatable.dart';

enum PttPlaybackStatus { idle, loading, playing, paused }

class PttPlaybackState extends Equatable {
  const PttPlaybackState({
    this.activeId,
    this.status = PttPlaybackStatus.idle,
    this.position = Duration.zero,
    this.error,
    this.errorSeq = 0,
  });

  /// Recording that is loading, playing or paused; `null` when idle.
  final String? activeId;
  final PttPlaybackStatus status;
  final Duration position;

  /// One-shot message for a snackbar; [errorSeq] keeps repeats distinct.
  final String? error;
  final int errorSeq;

  bool isActive(String id) => activeId == id;

  PttPlaybackState copyWith({
    String? activeId,
    PttPlaybackStatus? status,
    Duration? position,
  }) {
    return PttPlaybackState(
      activeId: activeId ?? this.activeId,
      status: status ?? this.status,
      position: position ?? this.position,
      errorSeq: errorSeq,
    );
  }

  PttPlaybackState idle() => PttPlaybackState(errorSeq: errorSeq);

  PttPlaybackState failed(String message) =>
      PttPlaybackState(error: message, errorSeq: errorSeq + 1);

  @override
  List<Object?> get props => [activeId, status, position, error, errorSeq];
}
