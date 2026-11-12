import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';

enum ManualRequestsPhase { loading, loaded, failure }

class ManualRequestsState extends Equatable {
  const ManualRequestsState({
    this.status = ManualRequestStatus.pending,
    this.phase = ManualRequestsPhase.loading,
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.decidingIds = const {},
    this.notice,
    this.noticeSeq = 0,
  });

  /// Tab whose requests are listed.
  final ManualRequestStatus status;
  final ManualRequestsPhase phase;
  final List<ManualRequestEntity> items;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  /// Requests with a decision in flight; their buttons stay disabled.
  final Set<String> decidingIds;

  /// One-shot message for a snackbar; [noticeSeq] makes repeats distinct.
  final String? notice;
  final int noticeSeq;

  ManualRequestsState copyWith({
    ManualRequestStatus? status,
    ManualRequestsPhase? phase,
    List<ManualRequestEntity>? items,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    Set<String>? decidingIds,
    String? notice,
  }) => ManualRequestsState(
    status: status ?? this.status,
    phase: phase ?? this.phase,
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: errorMessage,
    decidingIds: decidingIds ?? this.decidingIds,
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    status,
    phase,
    items,
    hasMore,
    isLoadingMore,
    errorMessage,
    decidingIds,
    notice,
    noticeSeq,
  ];
}

class ManualRequestsCubit extends Cubit<ManualRequestsState> {
  ManualRequestsCubit({
    required this.repository,
    this.pageSize = AppConstants.defaultPageSize,
  }) : super(const ManualRequestsState());

  final AttendanceAdminRepository repository;
  final int pageSize;

  int _requestId = 0;

  /// Lists [status] from the first page; defaults to the current tab.
  Future<void> load({ManualRequestStatus? status}) async {
    final tab = status ?? state.status;
    emit(ManualRequestsState(status: tab, decidingIds: state.decidingIds));
    await _fetchFirstPage(tab);
  }

  /// Pull-to-refresh: keeps the current rows visible while loading.
  Future<void> refresh() => _fetchFirstPage(state.status);

  Future<void> _fetchFirstPage(ManualRequestStatus tab) async {
    final requestId = ++_requestId;
    final result = await repository.getManualRequests(
      status: tab,
      limit: pageSize,
      offset: 0,
    );
    // The tab changed (or a newer load started) while this was in flight.
    if (isClosed || requestId != _requestId) return;
    result.fold(
      (failure) => emit(
        state.items.isNotEmpty && state.phase == ManualRequestsPhase.loaded
            ? state.copyWith(notice: failure.message)
            : state.copyWith(
                phase: ManualRequestsPhase.failure,
                errorMessage: failure.message,
              ),
      ),
      (items) => emit(
        state.copyWith(
          phase: ManualRequestsPhase.loaded,
          items: items,
          hasMore: items.length >= pageSize,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.phase != ManualRequestsPhase.loaded ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    final result = await repository.getManualRequests(
      status: state.status,
      limit: pageSize,
      offset: state.items.length,
    );
    if (isClosed || requestId != _requestId) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, notice: failure.message)),
      (items) => emit(
        state.copyWith(
          items: [...state.items, ...items],
          hasMore: items.length >= pageSize,
          isLoadingMore: false,
        ),
      ),
    );
  }

  /// Approves or rejects [request]; true when the server accepted it. The
  /// server enforces the role as well, this only avoids a pointless call.
  Future<bool> decide({
    required ManualRequestEntity request,
    required bool approve,
    required AuthSessionEntity? session,
    String? note,
  }) async {
    if (session == null || !session.isAdminRole) {
      emit(
        state.copyWith(
          notice: 'Hanya administrator yang dapat memutuskan permintaan ini.',
        ),
      );
      return false;
    }
    if (state.decidingIds.contains(request.id)) return false;
    emit(state.copyWith(decidingIds: {...state.decidingIds, request.id}));
    final result = await repository.decideManualRequest(
      id: request.id,
      approve: approve,
      note: note?.trim(),
    );
    if (isClosed) return false;
    final deciding = {...state.decidingIds}..remove(request.id);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(decidingIds: deciding, notice: failure.message));
      return false;
    }
    emit(
      state.copyWith(
        decidingIds: deciding,
        items: state.items.where((i) => i.id != request.id).toList(),
        notice: approve
            ? 'Permintaan disetujui. Absensi dicatat sebagai tidak '
                  'terverifikasi.'
            : 'Permintaan ditolak.',
      ),
    );
    return true;
  }
}
