import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';

/// Cubit pengelola state dan logika bisnis layar daftar insiden.
///
/// Kerangka fetch/paginasi/greeting ada di [ListFetchCubit]; kelas ini
/// menambahkan filter status, parameter sesi, dan mutasi item insiden.
class IncidentListCubit extends ListFetchCubit<IncidentState, IncidentEntity> {
  /// Membuat instance [IncidentListCubit].
  IncidentListCubit({
    required this.getIncidentsUseCase,
    String initialGreeting = '',
    super.pageSize = AppConstants.defaultPageSize,
    super.syncStorageService,
  }) : super(
          IncidentInitial(
            lastSync: SyncStorageService.resolveInitialGreeting(
              initialGreeting: initialGreeting,
              featureKey: AppConstants.syncKeyIncident,
              storageService: syncStorageService,
            ),
          ),
          syncKey: AppConstants.syncKeyIncident,
        );

  /// Use case untuk mengambil data insiden.
  final GetIncidentsUseCase getIncidentsUseCase;

  @override
  IncidentState? stateWithLastSync(String greeting) {
    final current = state;
    if (current is IncidentLoaded) {
      return current.copyWith(lastSync: greeting);
    } else if (current is IncidentInitial) {
      return IncidentInitial(lastSync: greeting);
    } else if (current is IncidentLoading) {
      return IncidentLoading(lastSync: greeting);
    }
    return null;
  }

  /// Insiden selalu dari server (tanpa cache): setiap penentuan greeting
  /// (termasuk saat gagal) mencatat waktu sinkronisasi sekarang.
  @override
  Future<String> resolveGreeting({required bool isFromCache}) =>
      saveSyncGreeting(DateTime.now());

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
  }) {
    final effectiveStatus =
        clearStatusFilter ? null : (status ?? state.selectedFilter);
    final filter = resolveFilter(
      search: search?.trim(),
      filterPeriod: filterPeriod,
      startDate: startDate,
      endDate: endDate,
      startDateIso: startDateIso,
      endDateIso: endDateIso,
    );
    return runFetch(
      isRefresh: isRefresh,
      filter: filter,
      extraKey: '$effectiveStatus',
      currentItems: state.displayedIncidents,
      loading: (lastSync) => IncidentLoading(lastSync: lastSync),
      request: (limit, cancelToken) async => (await getIncidentsUseCase(
        GetIncidentsParams(
          session: session,
          search: filter.search,
          status: effectiveStatus,
          limit: limit,
          offset: 0,
          startDate: filter.startIso,
          endDate: filter.endIso,
          cancelToken: cancelToken,
          isRefresh: isRefresh,
        ),
      ))
          .map(ListPage.new),
      loaded: (page, lastSync, {required hasMore}) => IncidentLoaded(
        incidents: page.items,
        lastSync: lastSync,
        hasMore: hasMore,
        filterPeriod: filter.period,
        selectedFilter: effectiveStatus,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
      error: (failure, cached, lastSync) => IncidentError(
        message: failure.message,
        failure: failure,
        cachedIncidents: cached,
        lastSync: lastSync,
        filterPeriod: filter.period,
        selectedFilter: effectiveStatus,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
    );
  }

  /// Memuat halaman data insiden berikutnya untuk mendukung infinite scroll.
  Future<void> loadMore({required AuthSessionEntity? session}) =>
      runLoadMore<IncidentLoaded>(
        request: (current) async => (await getIncidentsUseCase(
          GetIncidentsParams(
            session: session,
            search: current.searchQuery,
            status: current.selectedFilter,
            limit: pageSize,
            offset: current.incidents.length,
            startDate: current.startDateIso,
            endDate: current.endDateIso,
          ),
        ))
            .map(ListPage.new),
        setLoadingMore: (current, {required loadingMore}) =>
            current.copyWith(isLoadingMore: loadingMore),
        append: (current, newItems, {required hasMore}) => current.copyWith(
          incidents: [...current.incidents, ...newItems],
          hasMore: hasMore,
          isLoadingMore: false,
        ),
      );

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
