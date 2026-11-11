import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_recording_repository.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_recordings_state.dart';

/// Cursor-paginated history of recorded PTT turns.
///
/// Not a `ListFetchCubit`: that base is built around period/search filters and
/// offset paging, while this list has neither and pages by an opaque cursor.
class PttRecordingsCubit extends Cubit<PttRecordingsState> {
  PttRecordingsCubit({
    required PttRecordingRepository repository,
    this.pageSize = 20,
  }) : _repository = repository,
       super(const PttRecordingsState());

  final PttRecordingRepository _repository;
  final int pageSize;

  /// Bumped by every load/refresh so a slow response of a superseded request
  /// (or a load-more of the old list) cannot overwrite newer data.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    emit(const PttRecordingsState());
    await _fetchFirstPage(generation);
  }

  /// Keeps the current list on screen; a failure becomes a notice instead of
  /// replacing the list with an error.
  Future<void> refresh() async {
    final generation = ++_generation;
    await _fetchFirstPage(generation);
  }

  Future<void> _fetchFirstPage(int generation) async {
    final result = await _repository.getRecordings(limit: pageSize);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) {
        if (state.items.isEmpty) {
          emit(
            state.copyWith(
              status: PttRecordingsStatus.failure,
              errorMessage: () => failure.message,
            ),
          );
        } else {
          emit(state.copyWith(notice: failure.message));
        }
      },
      (page) => emit(
        PttRecordingsState(
          status: PttRecordingsStatus.loaded,
          items: page.items,
          nextBefore: page.nextBefore,
          noticeSeq: state.noticeSeq,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final cursor = state.nextBefore;
    if (state.status != PttRecordingsStatus.loaded ||
        cursor == null ||
        state.isLoadingMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _repository.getRecordings(
      before: cursor,
      limit: pageSize,
    );
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, notice: failure.message)),
      (page) {
        // A recording deleted meanwhile can shift page borders; keep ids unique.
        final known = state.items.map((r) => r.id).toSet();
        emit(
          state.copyWith(
            items: [
              ...state.items,
              ...page.items.where((r) => !known.contains(r.id)),
            ],
            nextBefore: () => page.nextBefore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  /// Deletes [id] for the whole group. The server only allows the ADMIN and
  /// SUPER_ADMIN roles (not the `allow_admin` flag, which some guards carry);
  /// the check here keeps anyone else from even trying.
  /// Returns whether the recording was deleted.
  Future<bool> delete(String id, {required AuthSessionEntity? session}) async {
    if (session == null || !session.isAdminRole) {
      emit(
        state.copyWith(
          notice: 'Hanya administrator yang dapat menghapus rekaman.',
        ),
      );
      return false;
    }
    if (state.deletingIds.contains(id)) return false;

    emit(state.copyWith(deletingIds: {...state.deletingIds, id}));
    final result = await _repository.deleteRecording(id);
    if (isClosed) return false;

    final remaining = {...state.deletingIds}..remove(id);
    result.fold(
      (failure) =>
          emit(state.copyWith(deletingIds: remaining, notice: failure.message)),
      (_) => emit(
        state.copyWith(
          items: state.items.where((r) => r.id != id).toList(),
          deletingIds: remaining,
          notice: 'Rekaman berhasil dihapus.',
        ),
      ),
    );
    return result.isRight();
  }
}
