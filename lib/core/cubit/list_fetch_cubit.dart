import 'package:flutter/foundation.dart' show protected;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/request_sequence_guard.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';

/// Minimal contract of a list state: period/date/search filters and the sync
/// label. Implemented by every feature's base state.
abstract interface class ListFilterState {
  AppDateFilterPeriod get filterPeriod;

  DateTime? get startDate;

  DateTime? get endDate;

  /// Sanitized start date of the filter (ISO 8601).
  String? get startDateIso;

  /// Sanitized end date of the filter (ISO 8601).
  String? get endDateIso;

  String? get searchQuery;

  String get lastSync;
}

/// Contract of the "Loaded" state that supports infinite scroll.
abstract interface class ListLoadedState implements ListFilterState {
  bool get hasMore;

  bool get isLoadingMore;
}

/// Effective filter resolved from the fetch arguments and the current state.
class ListFilter {
  const ListFilter({
    required this.period,
    required this.start,
    required this.end,
    required this.startIso,
    required this.endIso,
    required this.search,
  });

  final AppDateFilterPeriod period;

  final DateTime? start;

  final DateTime? end;

  /// Effective start date (ISO 8601, sanitized).
  final String? startIso;

  /// Effective end date (ISO 8601, sanitized).
  final String? endIso;

  /// Effective search keyword (`null` when empty).
  final String? search;

  /// Default periods (today/this week/this month) are loaded without
  /// pagination.
  bool get isDefaultPeriod => isDefaultFilterPeriod(period);
}

/// Whether [period] is a default period, which is loaded without pagination.
bool isDefaultFilterPeriod(AppDateFilterPeriod period) =>
    period == AppDateFilterPeriod.today ||
    period == AppDateFilterPeriod.thisWeek ||
    period == AppDateFilterPeriod.thisMonth;

/// One page of results from a list use case, independent of the feature-
/// specific result type.
class ListPage<I> {
  const ListPage(this.items, {this.isFromCache = false});

  final List<I> items;

  final bool isFromCache;
}

/// Feature fetch function that accepts the shared filter parameters.
typedef ListFetchFn = Future<AppFetchResult> Function({
  String? search,
  AppDateFilterPeriod? filterPeriod,
  DateTime? startDate,
  DateTime? endDate,
  String? startDateIso,
  String? endDateIso,
});

/// Base cubit for paginated lists with period/search filters.
///
/// Centralizes the skeleton shared by every feature: sync greeting, effective
/// filter resolution, request ordering guard (dedup plus cancellation of
/// superseded requests) and infinite scroll. Feature-specific parts (extra
/// filters, use case params, state construction) are supplied through
/// callbacks.
abstract class ListFetchCubit<S extends ListFilterState, I> extends Cubit<S>
    with RequestSequenceGuard {
  ListFetchCubit(
    super.initialState, {
    required this.syncKey,
    required this.pageSize,
    SyncStorageService? syncStorageService,
  }) : _syncStorage = syncStorageService ?? SyncStorageService.singleton() {
    _initGreeting();
  }

  final String syncKey;

  final int pageSize;

  final SyncStorageService _syncStorage;

  String? _activeFetchKey;
  Future<AppFetchResult>? _activeFetchFuture;

  /// Current greeting label; the state is the single source of truth.
  String get currentGreeting => state.lastSync;

  /// Copy of the current state with [greeting] as `lastSync`, or `null` when
  /// the current state type needs no update.
  @protected
  S? stateWithLastSync(String greeting);

  void _initGreeting() {
    if (state.lastSync.isEmpty) {
      _syncStorage.getLastSync(syncKey).then((lastSync) {
        if (lastSync != null && state.lastSync.isEmpty && !isClosed) {
          final next =
              stateWithLastSync(AppDateFormat.formatGreeting(lastSync));
          if (next != null) emit(next);
        }
      });
    }
  }

  /// Resolves the greeting label: the stored sync time for cached data, the
  /// current time for server data.
  @protected
  Future<String> resolveGreeting({required bool isFromCache}) async {
    if (isFromCache) {
      final lastSync = await _syncStorage.getLastSync(syncKey);
      if (lastSync != null) {
        return AppDateFormat.formatGreeting(lastSync);
      }
      return state.lastSync;
    }
    return AppDateFormat.formatGreeting(DateTime.now());
  }

  /// Records the sync time [now] and returns its greeting label.
  @protected
  Future<String> saveSyncGreeting(DateTime now) async {
    await _syncStorage.saveLastSync(syncKey, now);
    return AppDateFormat.formatGreeting(now);
  }

  /// Resolves the effective filter from the fetch arguments and the current
  /// state, then sanitizes the date range to ISO 8601.
  @protected
  ListFilter resolveFilter({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) {
    final period = filterPeriod ?? state.filterPeriod;
    final isCustom = period == AppDateFilterPeriod.custom;
    final start = isCustom ? (startDate ?? state.startDate) : null;
    final end = isCustom ? (endDate ?? state.endDate) : null;
    final String? effectiveSearch;
    if (search != null) {
      effectiveSearch = search.isNotEmpty ? search : null;
    } else {
      effectiveSearch = state.searchQuery;
    }

    final sanitized = AppDateFilterResult.sanitize(
      period: period,
      startDate: start,
      endDate: end,
      startDateIso: startDateIso ?? (isCustom ? state.startDateIso : null),
      endDateIso: endDateIso ?? (isCustom ? state.endDateIso : null),
    );

    return ListFilter(
      period: period,
      start: start,
      end: end,
      startIso: sanitized.startDateIso,
      endIso: sanitized.endDateIso,
      search: effectiveSearch,
    );
  }

  /// Runs one fetch cycle guarded by the request sequence.
  ///
  /// - [extraKey]: feature-specific part of the dedup key.
  /// - [currentItems]: items currently shown (kept when a refresh fails).
  /// - [loading]: skeleton state (non-refresh fetches only).
  /// - [request]: calls the feature use case.
  /// - [loaded] / [error]: build the resulting state.
  @protected
  Future<AppFetchResult> runFetch({
    required bool isRefresh,
    required ListFilter filter,
    required List<I> currentItems,
    required S Function(String lastSync) loading,
    required Future<Either<Failure, ListPage<I>>> Function(
      int limit,
      AppCancellationToken cancelToken,
    ) request,
    required S Function(
      ListPage<I> page,
      String lastSync, {
      required bool hasMore,
    }) loaded,
    required S Function(
      Failure failure,
      List<I> cachedItems,
      String lastSync,
    ) error,
    String extraKey = '',
  }) async {
    final fetchKey = '${filter.period}|${filter.startIso}|${filter.endIso}|'
        '${filter.search}|$extraKey';

    if (isFetching && _activeFetchKey == fetchKey) {
      // A request with the same parameters is already in flight: reuse it
      // without cancelling it or duplicating the server call.
      if (_activeFetchFuture != null) {
        return await _activeFetchFuture!;
      }
      return AppFetchResult.cancelled;
    }

    final reqId = nextRequestId();
    isFetching = true;
    _activeFetchKey = fetchKey;
    final cancelToken = renewSearchCancelToken();

    if (!isRefresh && state is! ListLoadedState) {
      emit(loading(state.lastSync));
    }

    final fetchOperation = _execute(
      reqId: reqId,
      isRefresh: isRefresh,
      filter: filter,
      currentItems: currentItems,
      cancelToken: cancelToken,
      request: request,
      loaded: loaded,
      error: error,
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

  Future<AppFetchResult> _execute({
    required int reqId,
    required bool isRefresh,
    required ListFilter filter,
    required List<I> currentItems,
    required AppCancellationToken cancelToken,
    required Future<Either<Failure, ListPage<I>>> Function(
      int limit,
      AppCancellationToken cancelToken,
    ) request,
    required S Function(
      ListPage<I> page,
      String lastSync, {
      required bool hasMore,
    }) loaded,
    required S Function(Failure failure, List<I> cachedItems, String lastSync)
        error,
  }) async {
    Future<AppFetchResult> fail(Failure failure) async {
      final greeting = await resolveGreeting(isFromCache: true);
      emit(
        error(failure, isRefresh ? currentItems : const [], greeting),
      );
      return AppFetchResult.failure;
    }

    try {
      final result = await request(
        filter.isDefaultPeriod ? 0 : pageSize,
        cancelToken,
      );

      if (!isLatest(reqId)) {
        return AppFetchResult.cancelled;
      }

      return await result.fold(
        (failure) async {
          if (failure is RequestCancelledFailure) {
            return AppFetchResult.cancelled;
          }
          return await fail(failure);
        },
        (page) async {
          final syncGreeting =
              await resolveGreeting(isFromCache: page.isFromCache);
          final hasMore = !filter.isDefaultPeriod &&
              !page.isFromCache &&
              page.items.length >= pageSize;
          emit(loaded(page, syncGreeting, hasMore: hasMore));
          return page.isFromCache
              ? AppFetchResult.cachedFallback
              : AppFetchResult.success;
        },
      );
    } on Object catch (e) {
      if (cancelToken.isCancelled || !isLatest(reqId)) {
        return AppFetchResult.cancelled;
      }
      return await fail(
        switch (e) {
          final Failure f => f,
          _ => const ServerFailure(),
        },
      );
    }
  }

  /// Loads the next page for infinite scroll when the current state is [L],
  /// more data exists, no page is loading and the period is not a default one.
  @protected
  Future<void> runLoadMore<L extends ListLoadedState>({
    required Future<Either<Failure, ListPage<I>>> Function(L current) request,
    required S Function(L current, {required bool loadingMore}) setLoadingMore,
    required S Function(L current, List<I> newItems, {required bool hasMore})
        append,
  }) async {
    final current = state;
    if (current is! L) return;
    if (!current.hasMore || current.isLoadingMore) return;
    if (isDefaultFilterPeriod(current.filterPeriod)) return;

    emit(setLoadingMore(current, loadingMore: true));

    final result = await request(current);

    result.fold(
      (failure) => emit(setLoadingMore(current, loadingMore: false)),
      (page) => emit(
        append(
          current,
          page.items,
          hasMore: !page.isFromCache && page.items.length >= pageSize,
        ),
      ),
    );
  }

  /// Applies the time filter from [filterResult] via [fetch].
  @protected
  Future<AppFetchResult> applyDateFilter(
    ListFetchFn fetch,
    AppDateFilterResult filterResult,
  ) =>
      fetch(
        search: state.searchQuery,
        filterPeriod: filterResult.period,
        startDate: filterResult.startDate,
        endDate: filterResult.endDate,
        startDateIso: filterResult.startDateIso,
        endDateIso: filterResult.endDateIso,
      );

  /// Resets the date filter to the "today" default via [fetch] without clearing
  /// the search keyword.
  @protected
  Future<AppFetchResult> resetDateFilterWith(ListFetchFn fetch) =>
      applyDateFilter(fetch, AppDateFilterResult.defaultFilter());

  /// Resets both the date filter and the search keyword to their defaults via
  /// [fetch].
  @protected
  Future<AppFetchResult> resetAllFiltersWith(ListFetchFn fetch) {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetch(
      search: '',
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
    );
  }

  @override
  Future<void> close() {
    cancelActiveSearch();
    invalidateRequests();
    _activeFetchKey = null;
    _activeFetchFuture = null;
    return super.close();
  }
}
