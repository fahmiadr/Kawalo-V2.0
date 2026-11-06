import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/request_sequence_guard.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';

/// Cubit pengelola state dan logika bisnis layar daftar insiden.
///
/// Mengadopsi arsitektur terpusat GuestCubit dengan State Polimorfik,
/// RequestSequenceGuard, dan sinkronisasi cap waktu lokal.
class IncidentListCubit extends Cubit<IncidentState> with RequestSequenceGuard {
  /// Membuat instance [IncidentListCubit].
  IncidentListCubit({
    required this.getIncidentsUseCase,
    String initialGreeting = '',
    this.pageSize = AppConstants.defaultPageSize,
    SyncStorageService? syncStorageService,
  })  : _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
        super(
          IncidentInitial(
            lastSync: SyncStorageService.resolveInitialGreeting(
              initialGreeting: initialGreeting,
              featureKey: AppConstants.syncKeyIncident,
              storageService: syncStorageService,
            ),
          ),
        ) {
    _initGreeting();
  }

  /// Use case untuk mengambil data insiden.
  final GetIncidentsUseCase getIncidentsUseCase;

  /// Layanan persistensi waktu sinkronisasi data dengan server.
  final SyncStorageService _syncStorage;

  /// Jumlah data default per halaman untuk infinite scroll.
  final int pageSize;

  String? _activeFetchKey;
  Future<AppFetchResult>? _activeFetchFuture;

  void _initGreeting() {
    if (state.lastSync.isEmpty) {
      _syncStorage.getLastSync(AppConstants.syncKeyIncident).then((lastSync) {
        if (lastSync != null && state.lastSync.isEmpty && !isClosed) {
          final greeting = AppDateFormat.formatGreeting(lastSync);
          _updateSyncGreeting(greeting);
        }
      });
    }
  }

  void _updateSyncGreeting(String greeting) {
    final currentState = state;
    if (currentState is IncidentLoaded) {
      emit(currentState.copyWith(lastSync: greeting));
    } else if (currentState is IncidentInitial) {
      emit(IncidentInitial(lastSync: greeting));
    } else if (currentState is IncidentLoading) {
      emit(IncidentLoading(lastSync: greeting));
    }
  }

  /// Label waktu greeting klien saat ini berdasarkan Single Source of Truth.
  String get currentGreeting => state.lastSync;

  @override
  Future<void> close() {
    invalidateRequests();
    return super.close();
  }

  /// Mengambil data insiden dari repositori (baik remote maupun mock).
  Future<AppFetchResult> fetchIncidents({
    required AuthSessionEntity? session,
    String? search,
    AppDateFilterPeriod? filterPeriod,
    IncidentStatus? status,
    bool clearStatusFilter = false,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) =>
      _fetch(
        session: session,
        search: search,
        filterPeriod: filterPeriod,
        status: status,
        clearStatusFilter: clearStatusFilter,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        isRefresh: false,
      );

  /// Memperbarui data insiden secara reaktif melalui tarikan pull-to-refresh.
  Future<AppFetchResult> refreshIncidents({
    required AuthSessionEntity? session,
    String? search,
    AppDateFilterPeriod? filterPeriod,
    IncidentStatus? status,
    bool clearStatusFilter = false,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) =>
      _fetch(
        session: session,
        search: search,
        filterPeriod: filterPeriod,
        status: status,
        clearStatusFilter: clearStatusFilter,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        isRefresh: true,
      );

  /// Implementasi terpusat pemanggilan usecase pengambilan data insiden
  /// dengan penjagaan urutan request, pembatalan search superseded, dan
  /// sanitasi rentang tanggal otomatis.
  Future<AppFetchResult> _fetch({
    required AuthSessionEntity? session,
    required bool isRefresh,
    String? search,
    AppDateFilterPeriod? filterPeriod,
    IncidentStatus? status,
    bool clearStatusFilter = false,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) async {
    final currentLoaded =
        state is IncidentLoaded ? (state as IncidentLoaded) : null;
    final currentError =
        state is IncidentError ? (state as IncidentError) : null;
    final currentIncidents = currentLoaded?.incidents ??
        currentError?.cachedIncidents ??
        const <IncidentEntity>[];

    final effectivePeriod = filterPeriod ?? state.filterPeriod;
    final effectiveStart = effectivePeriod == AppDateFilterPeriod.custom
        ? (startDate ?? state.startDate)
        : null;
    final effectiveEnd = effectivePeriod == AppDateFilterPeriod.custom
        ? (endDate ?? state.endDate)
        : null;

    final effectiveStatus =
        clearStatusFilter ? null : (status ?? state.selectedFilter);

    final String? effectiveSearch;
    if (search != null) {
      final trimmed = search.trim();
      effectiveSearch = trimmed.isNotEmpty ? trimmed : null;
    } else {
      effectiveSearch = state.searchQuery;
    }

    // Resolusi dan sanitasi rentang tanggal ke format ISO 8601 string
    // langsung menggunakan logika form AppDateFilterResult.
    final sanitizedFilter = AppDateFilterResult.sanitize(
      period: effectivePeriod,
      startDate: effectiveStart,
      endDate: effectiveEnd,
      startDateIso: startDateIso ??
          (effectivePeriod == AppDateFilterPeriod.custom
              ? state.startDateIso
              : null),
      endDateIso: endDateIso ??
          (effectivePeriod == AppDateFilterPeriod.custom
              ? state.endDateIso
              : null),
    );

    final effectiveStartIso = sanitizedFilter.startDateIso;
    final effectiveEndIso = sanitizedFilter.endDateIso;

    final fetchKey = '$effectivePeriod|'
        '$effectiveStartIso|'
        '$effectiveEndIso|$effectiveSearch|'
        '$effectiveStatus';

    if (isFetching && _activeFetchKey == fetchKey) {
      if (_activeFetchFuture != null) {
        return await _activeFetchFuture!;
      }
      return AppFetchResult.cancelled;
    }

    final reqId = nextRequestId();
    isFetching = true;
    _activeFetchKey = fetchKey;
    final cancelToken = renewSearchCancelToken();

    if (!isRefresh && state is! IncidentLoaded) {
      emit(IncidentLoading(lastSync: state.lastSync));
    }

    final isDefaultPeriod = effectivePeriod == AppDateFilterPeriod.today ||
        effectivePeriod == AppDateFilterPeriod.thisWeek ||
        effectivePeriod == AppDateFilterPeriod.thisMonth;
    final effectiveLimit = isDefaultPeriod ? 0 : pageSize;

    final fetchOperation = _executeFetch(
      reqId: reqId,
      session: session,
      effectiveSearch: effectiveSearch,
      effectivePeriod: effectivePeriod,
      effectiveStatus: effectiveStatus,
      effectiveStart: effectiveStart,
      effectiveEnd: effectiveEnd,
      effectiveStartIso: effectiveStartIso,
      effectiveEndIso: effectiveEndIso,
      effectiveLimit: effectiveLimit,
      isDefaultPeriod: isDefaultPeriod,
      isRefresh: isRefresh,
      currentIncidents: currentIncidents,
      cancelToken: cancelToken,
    );

    _activeFetchFuture = fetchOperation;

    try {
      return await fetchOperation;
    } finally {
      if (isLatest(reqId)) {
        isFetching = false;
        _activeFetchKey = null;
        _activeFetchFuture = null;
      }
    }
  }

  Future<AppFetchResult> _executeFetch({
    required int reqId,
    required AuthSessionEntity? session,
    required String? effectiveSearch,
    required AppDateFilterPeriod effectivePeriod,
    required IncidentStatus? effectiveStatus,
    required DateTime? effectiveStart,
    required DateTime? effectiveEnd,
    required String? effectiveStartIso,
    required String? effectiveEndIso,
    required int effectiveLimit,
    required bool isDefaultPeriod,
    required bool isRefresh,
    required List<IncidentEntity> currentIncidents,
    required AppCancellationToken cancelToken,
  }) async {
    try {
      final result = await getIncidentsUseCase(
        GetIncidentsParams(
          session: session,
          search: effectiveSearch,
          status: effectiveStatus,
          limit: effectiveLimit,
          offset: 0,
          startDate: effectiveStartIso,
          endDate: effectiveEndIso,
          cancelToken: cancelToken,
          isRefresh: isRefresh,
        ),
      );

      if (!isLatest(reqId)) {
        return AppFetchResult.cancelled;
      }

      return await result.fold(
        (failure) async {
          if (failure is RequestCancelledFailure) {
            return AppFetchResult.cancelled;
          }
          final greeting = await _resolveGreeting();
          emit(
            IncidentError(
              message: failure.message,
              failure: failure,
              cachedIncidents: isRefresh ? currentIncidents : const [],
              lastSync: greeting,
              filterPeriod: effectivePeriod,
              selectedFilter: effectiveStatus,
              startDate: effectiveStart,
              endDate: effectiveEnd,
              startDateIso: effectiveStartIso,
              endDateIso: effectiveEndIso,
              searchQuery: effectiveSearch,
            ),
          );
          return AppFetchResult.failure;
        },
        (items) async {
          final syncGreeting = await _resolveGreeting();
          final hasMore = !isDefaultPeriod && items.length >= pageSize;

          emit(
            IncidentLoaded(
              incidents: items,
              lastSync: syncGreeting,
              hasMore: hasMore,
              filterPeriod: effectivePeriod,
              selectedFilter: effectiveStatus,
              startDate: effectiveStart,
              endDate: effectiveEnd,
              startDateIso: effectiveStartIso,
              endDateIso: effectiveEndIso,
              searchQuery: effectiveSearch,
            ),
          );
          return AppFetchResult.success;
        },
      );
    } on Object catch (e) {
      if (cancelToken.isCancelled || !isLatest(reqId)) {
        return AppFetchResult.cancelled;
      }
      final greeting = await _resolveGreeting();
      final failure = switch (e) {
        final Failure f => f,
        _ => const ServerFailure(),
      };
      emit(
        IncidentError(
          message: failure.message,
          failure: failure,
          cachedIncidents: isRefresh ? currentIncidents : const [],
          lastSync: greeting,
          filterPeriod: effectivePeriod,
          selectedFilter: effectiveStatus,
          startDate: effectiveStart,
          endDate: effectiveEnd,
          startDateIso: effectiveStartIso,
          endDateIso: effectiveEndIso,
          searchQuery: effectiveSearch,
        ),
      );
      return AppFetchResult.failure;
    }
  }

  Future<String> _resolveGreeting() async {
    final now = DateTime.now();
    await _syncStorage.saveLastSync(AppConstants.syncKeyIncident, now);
    return AppDateFormat.formatGreeting(now);
  }

  /// Memuat halaman data insiden berikutnya untuk mendukung infinite scroll.
  Future<void> loadMore({required AuthSessionEntity? session}) async {
    if (state is! IncidentLoaded) return;
    final currentState = state as IncidentLoaded;

    if (!currentState.hasMore || currentState.isLoadingMore) return;

    final isDefaultPeriod =
        currentState.filterPeriod == AppDateFilterPeriod.today ||
            currentState.filterPeriod == AppDateFilterPeriod.thisWeek ||
            currentState.filterPeriod == AppDateFilterPeriod.thisMonth;
    if (isDefaultPeriod) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getIncidentsUseCase(
      GetIncidentsParams(
        session: session,
        search: currentState.searchQuery,
        status: currentState.selectedFilter,
        limit: pageSize,
        offset: currentState.incidents.length,
        startDate: currentState.startDateIso,
        endDate: currentState.endDateIso,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newItems) {
        final allItems = [...currentState.incidents, ...newItems];
        final hasMore = newItems.length >= pageSize;

        emit(
          currentState.copyWith(
            incidents: allItems,
            hasMore: hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  /// Mengubah filter status insiden ('Semua', 'Terbuka', 'Selesai').
  Future<AppFetchResult> setFilter(
    IncidentStatus? filter, {
    required AuthSessionEntity? session,
  }) =>
      fetchIncidents(
        session: session,
        status: filter,
        clearStatusFilter: filter == null,
      );

  /// Menerapkan filter waktu dari hasil [AppDateFilterResult].
  Future<AppFetchResult> setDateFilter(
    AppDateFilterResult filterResult, {
    required AuthSessionEntity? session,
  }) =>
      fetchIncidents(
        session: session,
        search: state.searchQuery,
        filterPeriod: filterResult.period,
        startDate: filterResult.startDate,
        endDate: filterResult.endDate,
        startDateIso: filterResult.startDateIso,
        endDateIso: filterResult.endDateIso,
      );

  /// Mereset filter tanggal menjadi default 'Hari ini'.
  Future<AppFetchResult> resetDateFilter({
    required AuthSessionEntity? session,
  }) {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetchIncidents(
      session: session,
      search: state.searchQuery,
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
    );
  }

  /// Memperbarui kata kunci pencarian insiden dan memicu fetch remote.
  Future<AppFetchResult> searchIncidents(
    String query, {
    required AuthSessionEntity? session,
  }) {
    final sanitized = query.trim();
    return fetchIncidents(
      session: session,
      search: sanitized,
    );
  }

  /// Memperbarui kata kunci pencarian lokal insiden (jika tanpa refetch).
  void setSearchQuery(String? query) {
    final currentState = state;
    if (currentState is IncidentLoaded) {
      emit(
        currentState.copyWith(
          searchQuery:
              query == null || query.trim().isEmpty ? null : query.trim(),
        ),
      );
    }
  }

  /// Mengatur ulang seluruh filter status, tanggal, dan kata kunci pencarian.
  Future<AppFetchResult> resetFilters({AuthSessionEntity? session}) {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetchIncidents(
      session: session,
      search: '',
      clearStatusFilter: true,
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
    );
  }

  /// Menyisipkan insiden baru di paling atas daftar jika memenuhi kriteria
  /// filter.
  void onIncidentCreated(IncidentEntity created) {
    final currentState = state;
    if (currentState is IncidentLoaded) {
      if (currentState.selectedFilter != null &&
          created.status != currentState.selectedFilter) {
        return;
      }
      final existingIndex =
          currentState.incidents.indexWhere((i) => i.id == created.id);
      if (existingIndex != -1) {
        final updated = List<IncidentEntity>.from(currentState.incidents);
        updated[existingIndex] = created;
        emit(currentState.copyWith(incidents: updated));
      } else {
        emit(
          currentState.copyWith(
            incidents: [created, ...currentState.incidents],
          ),
        );
      }
    }
  }

  /// Memperbarui entitas insiden di dalam list tanpa refetch jaringan.
  void onIncidentUpdated(IncidentEntity updated) {
    final currentState = state;
    if (currentState is IncidentLoaded) {
      final existingIndex =
          currentState.incidents.indexWhere((i) => i.id == updated.id);
      if (existingIndex == -1) return;

      if (currentState.selectedFilter != null &&
          updated.status != currentState.selectedFilter) {
        final filtered =
            currentState.incidents.where((i) => i.id != updated.id).toList();
        emit(currentState.copyWith(incidents: filtered));
        return;
      }

      final updatedList = List<IncidentEntity>.from(currentState.incidents);
      updatedList[existingIndex] = updated;
      emit(currentState.copyWith(incidents: updatedList));
    }
  }

  /// Menghapus insiden dari list saat insiden dihapus secara administratif.
  void onIncidentDeleted(String incidentId) {
    final currentState = state;
    if (currentState is IncidentLoaded) {
      final updatedList =
          currentState.incidents.where((i) => i.id != incidentId).toList();
      emit(currentState.copyWith(incidents: updatedList));
    }
  }
}
