import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';

enum PttRecordingsStatus { loading, loaded, failure }

class PttRecordingsState extends Equatable {
  const PttRecordingsState({
    this.status = PttRecordingsStatus.loading,
    this.items = const [],
    this.nextBefore,
    this.isLoadingMore = false,
    this.deletingIds = const {},
    this.errorMessage,
    this.notice,
    this.noticeSeq = 0,
  });

  final PttRecordingsStatus status;

  /// Newest first.
  final List<PttRecordingEntity> items;

  /// Cursor of the next (older) page; `null` when everything is loaded.
  final String? nextBefore;
  final bool isLoadingMore;
  final Set<String> deletingIds;

  /// Set with [PttRecordingsStatus.failure] only.
  final String? errorMessage;

  /// One-shot message for a snackbar (failed refresh, load more or delete).
  /// [noticeSeq] makes two identical messages in a row distinct states.
  final String? notice;
  final int noticeSeq;

  bool get hasMore => nextBefore != null;

  PttRecordingsState copyWith({
    PttRecordingsStatus? status,
    List<PttRecordingEntity>? items,
    String? Function()? nextBefore,
    bool? isLoadingMore,
    Set<String>? deletingIds,
    String? Function()? errorMessage,
    String? notice,
  }) {
    return PttRecordingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextBefore: nextBefore != null ? nextBefore() : this.nextBefore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      deletingIds: deletingIds ?? this.deletingIds,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      notice: notice,
      noticeSeq: notice != null ? noticeSeq + 1 : noticeSeq,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    nextBefore,
    isLoadingMore,
    deletingIds,
    errorMessage,
    notice,
    noticeSeq,
  ];
}
