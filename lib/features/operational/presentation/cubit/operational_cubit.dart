import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';

/// Cubit pengelola state dan logika bisnis modul Aktifitas Operasional.
///
/// The fetch, pagination and greeting skeleton lives in [ListFetchCubit]; this
/// class only maps the operational use cases and state.
class OperationalCubit
    extends ListFetchCubit<OperationalState, OperationalItemEntity> {
  /// Membuat instance [OperationalCubit].
  OperationalCubit({
    required this.repository,
    required super.syncStorageService,
    String initialGreeting = '',
    super.pageSize = AppConstants.defaultPageSize,
  }) : super(
         OperationalInitial(
           lastSync: SyncStorageService.resolveInitialGreeting(
             initialGreeting: initialGreeting,
             featureKey: AppConstants.syncKeyOperational,
             storageService: syncStorageService,
           ),
         ),
         syncKey: AppConstants.syncKeyOperational,
       );

  /// Repositori aktifitas operasional.
  final OperationalRepository repository;

  @override
  OperationalState? stateWithLastSync(String greeting) {
    final current = state;
    if (current is OperationalLoaded) {
      return current.copyWith(lastSync: greeting);
    } else if (current is OperationalInitial) {
      return OperationalInitial(lastSync: greeting);
    } else if (current is OperationalLoading) {
      return OperationalLoading(lastSync: greeting);
    }
    return null;
  }

  /// Mengambil aktifitas operasional dari repositori (mock atau REST API).
  Future<AppFetchResult> fetchOperationals({
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

  /// Memperbarui aktifitas operasional via pull-to-refresh tanpa skeleton.
  Future<AppFetchResult> refreshOperationals({
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
      currentItems: state.displayedOperationals,
      loading: (lastSync) => OperationalLoading(lastSync: lastSync),
      request: (limit, cancelToken) async => (await repository.getOperationals(
        GetOperationalsParams(
          search: filter.search,
          limit: limit,
          offset: 0,
          startDate: filter.startIso,
          endDate: filter.endIso,
          cancelToken: cancelToken,
          isRefresh: isRefresh,
        ),
      )).map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
      loaded: (page, lastSync, {required hasMore}) => OperationalLoaded(
        operationals: page.items,
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
      error: (failure, cached, lastSync) => OperationalError(
        message: failure.message,
        failure: failure,
        cachedOperationals: cached,
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
  Future<void> loadMoreOperationals() => runLoadMore<OperationalLoaded>(
    request: (current) async => (await repository.getOperationals(
      GetOperationalsParams(
        search: current.searchQuery,
        limit: pageSize,
        offset: current.operationals.length,
        startDate: current.startDateIso,
        endDate: current.endDateIso,
      ),
    )).map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
    setLoadingMore: (current, {required loadingMore}) =>
        current.copyWith(isLoadingMore: loadingMore),
    append: (current, newItems, {required hasMore}) => current.copyWith(
      operationals: [...current.operationals, ...newItems],
      hasMore: hasMore,
      isLoadingMore: false,
    ),
  );

  /// Menerapkan filter waktu dari hasil [AppDateFilterResult].
  Future<AppFetchResult> setFilter(AppDateFilterResult filterResult) =>
      applyDateFilter(fetchOperationals, filterResult);

  /// Mereset filter tanggal menjadi default 'Hari ini' tanpa menghapus
  /// kata kunci pencarian.
  Future<AppFetchResult> resetDateFilter() =>
      resetDateFilterWith(fetchOperationals);

  /// Mengatur ulang seluruh filter waktu dan pencarian ke kondisi default.
  Future<AppFetchResult> resetFilters() =>
      resetAllFiltersWith(fetchOperationals);
}
