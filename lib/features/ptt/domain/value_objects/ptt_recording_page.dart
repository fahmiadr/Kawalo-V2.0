import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';

/// A page of recordings, newest first.
class PttRecordingPage extends Equatable {
  const PttRecordingPage({required this.items, this.nextBefore});

  final List<PttRecordingEntity> items;

  /// Opaque cursor for the next (older) page; `null` on the last page.
  final String? nextBefore;

  @override
  List<Object?> get props => [items, nextBefore];
}
