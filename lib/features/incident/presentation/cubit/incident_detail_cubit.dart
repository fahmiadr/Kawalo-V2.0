import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/delete_incident/delete_incident_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/delete_incident/delete_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incident_detail/get_incident_detail_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incident_detail/get_incident_detail_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/post_incident_reply/post_incident_reply_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/post_incident_reply/post_incident_reply_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/watch_incident_replies/watch_incident_replies_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/watch_incident_replies/watch_incident_replies_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_photo_uploader.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Cubit yang mengelola state detail insiden, langganan realtime HTTP+SSE,
/// posting balasan (termasuk unggah foto), penyelesaian insiden, dan
/// penanganan konkurensi (balasan ke insiden yang sudah selesai).
class IncidentDetailCubit extends Cubit<IncidentDetailState> {
  /// Membuat instance [IncidentDetailCubit].
  IncidentDetailCubit({
    required this.incidentId,
    required this.getIncidentDetailUseCase,
    required this.watchIncidentRepliesUseCase,
    required this.postIncidentReplyUseCase,
    required this.resolveIncidentUseCase,
    required this.deleteIncidentUseCase,
    required UploadRepository uploadRepository,
  }) : _uploader = IncidentPhotoUploader(uploadRepository),
       super(const IncidentDetailState());

  /// ID insiden aktif yang dikelola.
  final String incidentId;

  /// Use case detail insiden.
  final GetIncidentDetailUseCase getIncidentDetailUseCase;

  /// Use case SSE realtime.
  final WatchIncidentRepliesUseCase watchIncidentRepliesUseCase;

  /// Use case kirim balasan thread.
  final PostIncidentReplyUseCase postIncidentReplyUseCase;

  /// Use case selesaikan insiden.
  final ResolveIncidentUseCase resolveIncidentUseCase;

  /// Use case hapus insiden.
  final DeleteIncidentUseCase deleteIncidentUseCase;

  final IncidentPhotoUploader _uploader;

  StreamSubscription<dynamic>? _sseSubscription;
  Timer? _reconnectTimer;
  DioCancellationToken? _streamCancelToken;
  int _retryCount = 0;
  final math.Random _random = math.Random();
  AuthSessionEntity? _currentSession;

  /// Inisialisasi memuat data awal insiden dan membuka stream SSE realtime.
  Future<void> init({required AuthSessionEntity? session}) async {
    _currentSession = session;
    emit(
      state.copyWith(
        status: IncidentDetailStatus.loading,
        errorMessage: () => null,
      ),
    );

    final params = GetIncidentDetailParams(
      incidentId: incidentId,
      session: session,
    );

    final result = await getIncidentDetailUseCase(params);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: IncidentDetailStatus.failure,
            errorMessage: () => failure.message,
          ),
        );
      },
      (detail) {
        final isReadOnly = detail.incident.isResolved;
        emit(
          state.copyWith(
            status: IncidentDetailStatus.success,
            incident: detail.incident,
            replies: detail.replies,
            isReadOnly: isReadOnly,
            errorMessage: () => null,
          ),
        );

        _subscribeToSse(
          session: session,
          lastEventId: detail.replies.lastOrNull?.id,
        );
      },
    );
  }

  /// Membuka koneksi SSE stream dengan penanganan rekoneksi otomatis.
  void _subscribeToSse({
    required AuthSessionEntity? session,
    String? lastEventId,
  }) {
    _sseSubscription?.cancel();
    _reconnectTimer?.cancel();
    _streamCancelToken = DioCancellationToken();

    final params = WatchIncidentRepliesParams(
      incidentId: incidentId,
      session: session,
      lastEventId: lastEventId ?? state.latestReplyId,
      cancelToken: _streamCancelToken,
    );

    _sseSubscription = watchIncidentRepliesUseCase(params).listen(
      (eventResult) {
        eventResult.fold((failure) => _handleStreamError(session: session), (
          streamEvent,
        ) {
          _retryCount = 0;
          if (state.isReconnecting) {
            emit(state.copyWith(isReconnecting: false));
          }
          _handleIncomingEvent(streamEvent);
        });
      },
      onError: (_) => _handleStreamError(session: session),
      onDone: () => _handleStreamError(session: session),
    );
  }

  /// Menangani setiap event domain yang datang dari SSE stream.
  void _handleIncomingEvent(IncidentStreamEvent event) {
    switch (event) {
      case IncidentReplyStreamEvent(:final reply):
        // Abaikan jika balasan sudah ada di list (deduplikasi id)
        final alreadyExists = state.replies.any((r) => r.id == reply.id);
        if (alreadyExists) return;

        // Umpan balik haptic ringan saat pesan baru masuk di foreground
        HapticFeedback.lightImpact();

        final updatedReplies = List<IncidentReplyEntity>.from(state.replies)
          ..add(reply);
        emit(state.copyWith(replies: updatedReplies));

      case IncidentResolvedStreamEvent(
        :final resolvedBy,
        :final resolvedByName,
        :final resolvedAt,
      ):
        final updatedIncident = state.incident?.copyWith(
          status: IncidentStatus.resolved,
          resolvedBy: resolvedBy,
          resolvedByName: resolvedByName,
          resolvedAt: resolvedAt,
        );
        emit(
          state.copyWith(
            incident: updatedIncident,
            isReadOnly: true,
            infoNotice: () =>
                'Insiden telah diselesaikan oleh $resolvedByName.',
          ),
        );

      case IncidentDeletedStreamEvent():
        emit(
          state.copyWith(
            isTerminated: true,
            errorMessage: () => 'Insiden ini telah dihapus oleh Administrator.',
          ),
        );

      case IncidentResyncedStreamEvent(:final incident, :final replies):
        emit(
          state.copyWith(
            incident: incident,
            replies: replies,
            isReadOnly: incident.isResolved,
            isReconnecting: false,
          ),
        );
    }
  }

  /// Menangani kegagalan stream atau disconnection dengan exponential backoff
  /// dan jitter.
  void _handleStreamError({required AuthSessionEntity? session}) {
    if (isClosed || state.isTerminated) return;

    emit(state.copyWith(isReconnecting: true));
    _sseSubscription?.cancel();

    _retryCount++;
    final maxBackoff = math.min(10, math.pow(2, _retryCount).toInt());
    final waitSeconds = _random.nextInt(maxBackoff + 1);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: waitSeconds), () {
      if (!isClosed && !state.isTerminated) {
        _subscribeToSse(session: session, lastEventId: state.latestReplyId);
      }
    });
  }

  /// Memperbarui isi draf pesan teks di composer bar.
  void updateDraftMessage(String text) {
    emit(state.copyWith(draftMessage: text));
  }

  /// Menambahkan foto lampiran draf (maksimal 2 untuk balasan).
  void addDraftPhoto(IncidentMediaItem photo) {
    if (state.draftPhotos.length >= 2) return;
    emit(state.copyWith(draftPhotos: [...state.draftPhotos, photo]));
  }

  /// Menghapus foto lampiran draf berdasarkan ID.
  void removeDraftPhoto(String photoId) {
    emit(
      state.copyWith(
        draftPhotos: state.draftPhotos.where((p) => p.id != photoId).toList(),
      ),
    );
  }

  void _patchDraftPhoto(
    String id,
    IncidentMediaItem Function(IncidentMediaItem current) change,
  ) {
    if (isClosed) return;
    emit(
      state.copyWith(
        draftPhotos: [
          for (final p in state.draftPhotos)
            if (p.id == id) change(p) else p,
        ],
      ),
    );
  }

  /// Retries the upload of a single failed draft photo.
  Future<void> retryDraftPhotoUpload(String photoId) async {
    if (state.isPostingReply) return;
    final photo = state.draftPhotos.where((p) => p.id == photoId).firstOrNull;
    if (photo == null || !photo.needsUpload) return;
    await _uploader.upload([photo], _patchDraftPhoto);
  }

  /// Whether [failure] is the server rejecting a reply because the incident
  /// was resolved in the meantime (HTTP 400, no dedicated error code).
  static bool _isAlreadyResolved(Failure failure) {
    return failure.statusCode == 400 &&
        failure.message.toLowerCase().contains('diselesaikan');
  }

  /// Reloads incident and replies after the server reported a state we did not
  /// know about. Keeps the current data when the reload fails.
  Future<void> _refreshDetail(AuthSessionEntity? session) async {
    final result = await getIncidentDetailUseCase(
      GetIncidentDetailParams(incidentId: incidentId, session: session),
    );
    if (isClosed) return;
    result.fold(
      (_) {},
      (detail) => emit(
        state.copyWith(
          incident: detail.incident,
          replies: detail.replies,
          isReadOnly: detail.incident.isResolved,
        ),
      ),
    );
  }

  /// Mengirim pesan balasan atau foto ke thread insiden.
  Future<void> postReply({required AuthSessionEntity? session}) async {
    final incident = state.incident;
    if (incident == null ||
        state.isReadOnly ||
        state.isPostingReply ||
        state.isUploadingPhotos) {
      return;
    }

    final trimmedText = state.draftMessage.trim();
    if (trimmedText.isEmpty && state.draftPhotos.isEmpty) return;

    emit(
      state.copyWith(
        isPostingReply: true,
        errorMessage: () => null,
        conflictNotice: () => null,
      ),
    );

    await _uploader.upload(state.draftPhotos, _patchDraftPhoto);
    if (isClosed) return;

    // Only uploaded URLs may reach the payload; a local file must never leak.
    final failedCount = state.draftPhotos.where((p) => !p.isUploaded).length;
    if (failedCount > 0) {
      emit(
        state.copyWith(
          isPostingReply: false,
          errorMessage: () =>
              '$failedCount foto gagal diunggah. Ketuk foto yang gagal untuk '
              'mencoba lagi, lalu kirim ulang.',
        ),
      );
      return;
    }

    final photoUrls = state.draftPhotos.map((p) => p.remoteUrl!).toList();

    final params = PostIncidentReplyParams(
      incident: incident,
      message: trimmedText,
      photos: photoUrls,
      session: session,
    );

    final result = await postIncidentReplyUseCase(params);
    if (isClosed) return;

    var refreshAfter = false;
    result.fold(
      (failure) {
        if (_isAlreadyResolved(failure)) {
          // The server answers 400 (not 409) when the incident was resolved by
          // someone else while the user was typing; the draft is kept.
          refreshAfter = true;
          emit(
            state.copyWith(
              isPostingReply: false,
              isReadOnly: true,
              conflictNotice: () =>
                  'Insiden telah diselesaikan oleh rekan Anda.',
            ),
          );
        } else {
          // Pertahankan draf agar catatan petugas tidak hilang
          emit(
            state.copyWith(
              isPostingReply: false,
              errorMessage: () => failure.message,
            ),
          );
        }
      },
      (reply) {
        // Hapus draf hanya jika posting berhasil (HTTP 201)
        final alreadyInList = state.replies.any((r) => r.id == reply.id);
        final updatedReplies = alreadyInList
            ? state.replies
            : (List<IncidentReplyEntity>.from(state.replies)..add(reply));

        emit(
          state.copyWith(
            isPostingReply: false,
            draftMessage: '',
            draftPhotos: const [],
            replies: updatedReplies,
            errorMessage: () => null,
          ),
        );
      },
    );
    if (refreshAfter) await _refreshDetail(session);
  }

  /// Menyelesaikan insiden dan mengunci thread diskusi.
  Future<void> resolveIncident({required AuthSessionEntity? session}) async {
    final incident = state.incident;
    if (incident == null || state.isReadOnly || state.isResolving) return;

    emit(
      state.copyWith(
        isResolving: true,
        errorMessage: () => null,
        conflictNotice: () => null,
      ),
    );

    final params = ResolveIncidentParams(incident: incident, session: session);

    final result = await resolveIncidentUseCase(params);

    result.fold(
      (failure) {
        // Resolving is idempotent server-side (200), so there is no conflict
        // case here.
        emit(
          state.copyWith(
            isResolving: false,
            errorMessage: () => failure.message,
          ),
        );
      },
      (resolvedIncident) {
        emit(
          state.copyWith(
            isResolving: false,
            incident: resolvedIncident,
            isReadOnly: true,
            infoNotice: () => 'Insiden berhasil diselesaikan.',
          ),
        );
      },
    );
  }

  /// Menghapus insiden secara administratif (soft-delete).
  Future<void> deleteIncident({required AuthSessionEntity? session}) async {
    final incident = state.incident;
    if (incident == null || state.isDeleting) return;

    emit(state.copyWith(isDeleting: true, errorMessage: () => null));

    final params = DeleteIncidentParams(incident: incident, session: session);

    final result = await deleteIncidentUseCase(params);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isDeleting: false,
            errorMessage: () => failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            isDeleting: false,
            isTerminated: true,
            infoNotice: () => 'Insiden berhasil dihapus.',
          ),
        );
      },
    );
  }

  /// Membersihkan notifikasi pesan toast / banner yang sudah ditampilkan.
  void clearNotices() {
    emit(
      state.copyWith(
        conflictNotice: () => null,
        infoNotice: () => null,
        errorMessage: () => null,
      ),
    );
  }

  /// Menghentikan koneksi stream saat layar dijeda (misal backgrounding).
  void pauseStream() {
    _streamCancelToken?.cancel('App paused');
    _sseSubscription?.cancel();
    _reconnectTimer?.cancel();
  }

  /// Memulihkan koneksi stream saat layar kembali aktif.
  void resumeStream() {
    if (!state.isTerminated) {
      _subscribeToSse(
        session: _currentSession,
        lastEventId: state.latestReplyId,
      );
    }
  }

  @override
  Future<void> close() {
    _streamCancelToken?.cancel('Cubit closed');
    _sseSubscription?.cancel();
    _reconnectTimer?.cancel();
    return super.close();
  }
}
