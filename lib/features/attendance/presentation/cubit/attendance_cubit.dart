import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/domain/usecases/get_attendances/get_attendances_usecase.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_state.dart';

/// Cubit pengelola state dan logika bisnis modul Data Absensi.
///
/// The fetch, pagination and greeting skeleton lives in [ListFetchCubit]; this
/// class only maps the attendance use cases and state.
class AttendanceCubit
    extends ListFetchCubit<AttendanceState, AttendanceItemEntity> {
  /// Membuat instance [AttendanceCubit].
  AttendanceCubit({
    required this.getAttendancesUseCase,
    String initialGreeting = '',
    super.pageSize = AppConstants.defaultPageSize,
    super.syncStorageService,
  }) : super(
         AttendanceInitial(
           lastSync: SyncStorageService.resolveInitialGreeting(
             initialGreeting: initialGreeting,
             featureKey: AppConstants.syncKeyAttendance,
             storageService: syncStorageService,
           ),
         ),
         syncKey: AppConstants.syncKeyAttendance,
       );

  /// Use case untuk mengambil data absensi.
  final GetAttendancesUseCase getAttendancesUseCase;

  @override
  AttendanceState? stateWithLastSync(String greeting) {
    final current = state;
    if (current is AttendanceLoaded) {
      return current.copyWith(lastSync: greeting);
    } else if (current is AttendanceInitial) {
      return AttendanceInitial(lastSync: greeting);
    } else if (current is AttendanceLoading) {
      return AttendanceLoading(lastSync: greeting);
    }
    return null;
  }

  /// Mengambil data absensi dari repositori (mock atau REST API backend).
  Future<AppFetchResult> fetchAttendances({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) => _fetch(
    search: search,
    filterPeriod: filterPeriod,
    startDate: startDate,
    endDate: endDate,
    startDateIso: startDateIso,
    endDateIso: endDateIso,
    isRefresh: false,
  );

  /// Memperbarui data absensi melalui pull-to-refresh tanpa flicker skeleton.
  Future<AppFetchResult> refreshAttendances({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) => _fetch(
    search: search,
    filterPeriod: filterPeriod,
    startDate: startDate,
    endDate: endDate,
    startDateIso: startDateIso,
    endDateIso: endDateIso,
    isRefresh: true,
  );

  Future<AppFetchResult> _fetch({
    required bool isRefresh,
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) {
    final filter = resolveFilter(
      search: search,
      filterPeriod: filterPeriod,
      startDate: startDate,
      endDate: endDate,
      startDateIso: startDateIso,
      endDateIso: endDateIso,
    );
    return runFetch(
      isRefresh: isRefresh,
      filter: filter,
      currentItems: state.displayedAttendances,
      loading: (lastSync) => AttendanceLoading(lastSync: lastSync),
      request: (limit, cancelToken) async => (await getAttendancesUseCase(
        GetAttendancesParams(
          search: filter.search,
          limit: limit,
          offset: 0,
          startDate: filter.startIso,
          endDate: filter.endIso,
          cancelToken: cancelToken,
          isRefresh: isRefresh,
        ),
      )).map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
      loaded: (page, lastSync, {required hasMore}) => AttendanceLoaded(
        attendances: page.items,
        isFromCache: page.isFromCache,
        lastSync: lastSync,
        hasMore: hasMore,
        filterPeriod: filter.period,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
      error: (failure, cached, lastSync) => AttendanceError(
        message: failure.message,
        failure: failure,
        cachedAttendances: cached,
        lastSync: lastSync,
        filterPeriod: filter.period,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
    );
  }

  /// Memuat halaman berikutnya untuk infinite scroll.
  Future<void> loadMoreAttendances() => runLoadMore<AttendanceLoaded>(
    request: (current) async => (await getAttendancesUseCase(
      GetAttendancesParams(
        search: current.searchQuery,
        limit: pageSize,
        offset: current.attendances.length,
        startDate: current.startDateIso,
        endDate: current.endDateIso,
      ),
    )).map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
    setLoadingMore: (current, {required loadingMore}) =>
        current.copyWith(isLoadingMore: loadingMore),
    append: (current, newItems, {required hasMore}) => current.copyWith(
      attendances: [...current.attendances, ...newItems],
      hasMore: hasMore,
      isLoadingMore: false,
    ),
  );

  /// Menerapkan filter waktu dari hasil [AppDateFilterResult].
  Future<AppFetchResult> setFilter(AppDateFilterResult filterResult) =>
      applyDateFilter(fetchAttendances, filterResult);

  /// Mereset filter tanggal menjadi default 'Hari ini' tanpa menghapus
  /// kata kunci pencarian.
  Future<AppFetchResult> resetDateFilter() =>
      resetDateFilterWith(fetchAttendances);

  /// Mengatur ulang seluruh filter waktu dan pencarian ke kondisi default.
  Future<AppFetchResult> resetFilters() =>
      resetAllFiltersWith(fetchAttendances);
}
