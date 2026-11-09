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

/// Kontrak minimal state daftar: filter periode/tanggal/pencarian dan label
/// sinkronisasi. Dipenuhi oleh seluruh turunan state basis tiap fitur.
abstract interface class ListFilterState {
  /// Periode filter waktu yang sedang aktif.
  AppDateFilterPeriod get filterPeriod;

  /// Tanggal awal rentang kustom.
  DateTime? get startDate;

  /// Tanggal akhir rentang kustom.
  DateTime? get endDate;

  /// Tanggal awal filter (ISO 8601) yang telah disanitasi.
  String? get startDateIso;

  /// Tanggal akhir filter (ISO 8601) yang telah disanitasi.
  String? get endDateIso;

  /// Kata kunci pencarian yang sedang aktif.
  String? get searchQuery;

  /// Label waktu sinkronisasi terakhir.
  String get lastSync;
}

/// Kontrak state "Loaded" yang mendukung infinite scroll.
abstract interface class ListLoadedState implements ListFilterState {
  /// Apakah masih ada halaman berikutnya di server.
  bool get hasMore;

  /// Apakah halaman berikutnya sedang dimuat.
  bool get isLoadingMore;
}

/// Filter efektif hasil resolusi parameter fetch terhadap state aktif.
class ListFilter {
  /// Membuat instance [ListFilter].
  const ListFilter({
    required this.period,
    required this.start,
    required this.end,
    required this.startIso,
    required this.endIso,
    required this.search,
  });

  /// Periode filter efektif.
  final AppDateFilterPeriod period;

  /// Tanggal awal rentang kustom efektif.
  final DateTime? start;

  /// Tanggal akhir rentang kustom efektif.
  final DateTime? end;

  /// Tanggal awal efektif (ISO 8601, sudah disanitasi).
  final String? startIso;

  /// Tanggal akhir efektif (ISO 8601, sudah disanitasi).
  final String? endIso;

  /// Kata kunci pencarian efektif (`null` bila kosong).
  final String? search;

  /// Periode bawaan (hari ini/minggu ini/bulan ini) dimuat tanpa paginasi.
  bool get isDefaultPeriod => isDefaultFilterPeriod(period);
}

/// Apakah [period] termasuk periode bawaan yang dimuat tanpa paginasi.
bool isDefaultFilterPeriod(AppDateFilterPeriod period) =>
    period == AppDateFilterPeriod.today ||
    period == AppDateFilterPeriod.thisWeek ||
    period == AppDateFilterPeriod.thisMonth;

/// Satu halaman hasil use case daftar, tidak bergantung pada tipe hasil
/// spesifik fitur.
class ListPage<I> {
  /// Membuat instance [ListPage].
  const ListPage(this.items, {this.isFromCache = false});

  /// Item pada halaman ini.
  final List<I> items;

  /// Apakah data bersumber dari cache lokal.
  final bool isFromCache;
}

/// Fungsi fetch fitur yang menerima parameter filter bersama.
typedef ListFetchFn = Future<AppFetchResult> Function({
  String? search,
  AppDateFilterPeriod? filterPeriod,
  DateTime? startDate,
  DateTime? endDate,
  String? startDateIso,
  String? endDateIso,
});

/// Basis cubit daftar berpaginasi dengan filter periode/pencarian.
///
/// Memusatkan kerangka yang identik antar fitur: greeting sinkronisasi,
/// resolusi filter efektif, penjagaan urutan request (dedup + pembatalan
/// superseded), dan infinite scroll. Hal khusus fitur (filter tambahan,
/// pembentukan params use case, konstruksi state) disuplai lewat callback.
abstract class ListFetchCubit<S extends ListFilterState, I> extends Cubit<S>
    with RequestSequenceGuard {
  /// Membuat instance [ListFetchCubit].
  ListFetchCubit(
    super.initialState, {
    required this.syncKey,
    required this.pageSize,
    SyncStorageService? syncStorageService,
  }) : _syncStorage = syncStorageService ?? SyncStorageService.singleton() {
    _initGreeting();
  }

  /// Kunci penyimpanan waktu sinkronisasi fitur ini.
  final String syncKey;

  /// Ukuran data per halaman untuk paginasi.
  final int pageSize;

  final SyncStorageService _syncStorage;

  String? _activeFetchKey;
  Future<AppFetchResult>? _activeFetchFuture;

  /// Label waktu greeting klien saat ini berdasarkan Single Source of Truth
  /// state.
  String get currentGreeting => state.lastSync;

  /// Salinan state aktif dengan [greeting] sebagai `lastSync`, atau `null`
  /// bila tipe state aktif tidak perlu diperbarui.
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

  /// Menentukan label greeting. Dari cache: waktu sinkronisasi tersimpan;
  /// dari server: waktu sekarang.
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

  /// Mencatat waktu sinkronisasi [now] dan mengembalikan label greeting-nya.
  @protected
  Future<String> saveSyncGreeting(DateTime now) async {
    await _syncStorage.saveLastSync(syncKey, now);
    return AppDateFormat.formatGreeting(now);
  }

  /// Menyelesaikan filter efektif dari argumen fetch dan state aktif, lalu
  /// menyanitasi rentang tanggal ke ISO 8601.
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

  /// Menjalankan satu siklus fetch dengan penjagaan urutan request.
  ///
  /// - [extraKey]: bagian kunci dedup dari filter khusus fitur.
  /// - [currentItems]: item yang sedang tampil (dipertahankan saat refresh
  ///   gagal).
  /// - [loading]: state skeleton (hanya untuk fetch non-refresh).
  /// - [request]: memanggil use case fitur.
  /// - [loaded] / [error]: membangun state hasil.
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
      // Request dengan parameter sama sedang berjalan: gunakan kembali tanpa
      // membatalkan maupun menduplikasi panggilan ke server.
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

  /// Memuat halaman berikutnya untuk infinite scroll bila state aktif bertipe
  /// [L], masih ada data, tidak sedang memuat, dan periode bukan bawaan.
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

  /// Menerapkan filter waktu dari [filterResult] via [fetch].
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

  /// Mereset filter tanggal ke default 'Hari ini' via [fetch] tanpa
  /// menghapus kata kunci pencarian.
  @protected
  Future<AppFetchResult> resetDateFilterWith(ListFetchFn fetch) =>
      applyDateFilter(fetch, AppDateFilterResult.defaultFilter());

  /// Mereset filter tanggal dan pencarian ke default via [fetch].
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
