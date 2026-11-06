import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/request_sequence_guard.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/domain/usecases/get_operationals/get_operationals_usecase.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';

/// Cubit pengelola state dan logika bisnis modul Aktifitas Operasional.
class OperationalCubit extends Cubit<OperationalState>
    with RequestSequenceGuard {
  /// Membuat instance [OperationalCubit].
  OperationalCubit({
    required this.getOperationalsUseCase,
    String initialGreeting = '',
    this.pageSize = AppConstants.defaultPageSize,
    SyncStorageService? syncStorageService,
  })  : _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
        super(
          OperationalInitial(
            lastSync: SyncStorageService.resolveInitialGreeting(
              initialGreeting: initialGreeting,
              featureKey: AppConstants.syncKeyOperational,
              storageService: syncStorageService,
            ),
          ),
        ) {
    _initGreeting();
  }

  /// Use case untuk mengambil aktifitas operasional.
  final GetOperationalsUseCase getOperationalsUseCase;

  /// Layanan persistensi waktu sinkronisasi data dengan server.
  final SyncStorageService _syncStorage;

  /// Ukuran halaman untuk paginasi
  /// (default: [AppConstants.defaultPageSize]).
  final int pageSize;

  String? _activeFetchKey;
  Future<AppFetchResult>? _activeFetchFuture;

  void _initGreeting() {
    if (state.lastSync.isEmpty) {
      _syncStorage
          .getLastSync(AppConstants.syncKeyOperational)
          .then((lastSync) {
        if (lastSync != null && state.lastSync.isEmpty && !isClosed) {
          final greeting = AppDateFormat.formatGreeting(lastSync);
          _updateSyncGreeting(greeting);
        }
      });
    }
  }

  void _updateSyncGreeting(String greeting) {
    final currentState = state;
    if (currentState is OperationalLoaded) {
      emit(currentState.copyWith(lastSync: greeting));
    } else if (currentState is OperationalInitial) {
      emit(OperationalInitial(lastSync: greeting));
    } else if (currentState is OperationalLoading) {
      emit(OperationalLoading(lastSync: greeting));
    }
  }

  /// Label waktu greeting klien saat ini berdasarkan Single Source of Truth
  /// state.
  String get currentGreeting => state.lastSync;

  /// Mengambil aktifitas operasional dari repositori (baik mock maupun remote).
  Future<AppFetchResult> fetchOperationals({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) =>
      _fetch(
        search: search,
        filterPeriod: filterPeriod,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        isRefresh: false,
      );

  /// Memperbarui aktifitas operasional dengan pull-to-refresh tanpa
  /// flicker loading.
  Future<AppFetchResult> refreshOperationals({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) =>
      _fetch(
        search: search,
        filterPeriod: filterPeriod,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        isRefresh: true,
      );

  /// Implementasi terpusat pemanggilan usecase pengambilan aktifitas
  /// operasional dengan penjagaan urutan request, pembatalan search
  /// superseded, dan sanitasi rentang tanggal otomatis.
  Future<AppFetchResult> _fetch({
    required bool isRefresh,
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
  }) async {
    final currentLoaded =
        state is OperationalLoaded ? (state as OperationalLoaded) : null;
    final currentError =
        state is OperationalError ? (state as OperationalError) : null;
    final currentOperationals = currentLoaded?.operationals ??
        currentError?.cachedOperationals ??
        const <OperationalItemEntity>[];

    final effectivePeriod = filterPeriod ?? state.filterPeriod;
    final effectiveStart = effectivePeriod == AppDateFilterPeriod.custom
        ? (startDate ?? state.startDate)
        : null;
    final effectiveEnd = effectivePeriod == AppDateFilterPeriod.custom
        ? (endDate ?? state.endDate)
        : null;
    final String? effectiveSearch;
    if (search != null) {
      effectiveSearch = search.isNotEmpty ? search : null;
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
        '$effectiveEndIso|$effectiveSearch';

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

    if (!isRefresh && state is! OperationalLoaded) {
      emit(OperationalLoading(lastSync: state.lastSync));
    }

    final isDefaultPeriod = effectivePeriod == AppDateFilterPeriod.today ||
        effectivePeriod == AppDateFilterPeriod.thisWeek ||
        effectivePeriod == AppDateFilterPeriod.thisMonth;
    final effectiveLimit = isDefaultPeriod ? 0 : pageSize;

    final fetchOperation = _executeFetch(
      reqId: reqId,
      effectiveSearch: effectiveSearch,
      effectivePeriod: effectivePeriod,
      effectiveStart: effectiveStart,
      effectiveEnd: effectiveEnd,
      effectiveStartIso: effectiveStartIso,
      effectiveEndIso: effectiveEndIso,
      effectiveLimit: effectiveLimit,
      isDefaultPeriod: isDefaultPeriod,
      isRefresh: isRefresh,
      currentOperationals: currentOperationals,
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
    required String? effectiveSearch,
    required AppDateFilterPeriod effectivePeriod,
    required DateTime? effectiveStart,
    required DateTime? effectiveEnd,
    required String? effectiveStartIso,
    required String? effectiveEndIso,
    required int effectiveLimit,
    required bool isDefaultPeriod,
    required bool isRefresh,
    required List<OperationalItemEntity> currentOperationals,
    required AppCancellationToken cancelToken,
  }) async {
    try {
      final result = await getOperationalsUseCase(
        GetOperationalsParams(
          search: effectiveSearch,
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
          final greeting = await _resolveGreeting(isFromCache: true);
          emit(
            OperationalError(
              message: failure.message,
              failure: failure,
              cachedOperationals:
                  isRefresh ? currentOperationals : const [],
              lastSync: greeting,
              filterPeriod: effectivePeriod,
              startDate: effectiveStart,
              endDate: effectiveEnd,
              startDateIso: effectiveStartIso,
              endDateIso: effectiveEndIso,
              searchQuery: effectiveSearch,
            ),
          );
          return AppFetchResult.failure;
        },
        (operationalResult) async {
          final isFromCache = operationalResult.isFromCache;
          final syncGreeting =
              await _resolveGreeting(isFromCache: isFromCache);

          final hasMore = !isDefaultPeriod &&
              !isFromCache &&
              operationalResult.items.length >= pageSize;

          emit(
            OperationalLoaded(
              operationals: operationalResult.items,
              isFromCache: isFromCache,
              lastSync: syncGreeting,
              hasMore: hasMore,
              filterPeriod: effectivePeriod,
              startDate: effectiveStart,
              endDate: effectiveEnd,
              startDateIso: effectiveStartIso,
              endDateIso: effectiveEndIso,
              searchQuery: effectiveSearch,
            ),
          );
          return isFromCache
              ? AppFetchResult.cachedFallback
              : AppFetchResult.success;
        },
      );
    } on Object catch (e) {
      if (cancelToken.isCancelled || !isLatest(reqId)) {
        return AppFetchResult.cancelled;
      }
      if (isLatest(reqId)) {
        final greeting = await _resolveGreeting(isFromCache: true);
        final failure = switch (e) {
          final Failure f => f,
          _ => const ServerFailure(),
        };
        emit(
          OperationalError(
            message: failure.message,
            failure: failure,
            cachedOperationals:
                isRefresh ? currentOperationals : const [],
            lastSync: greeting,
            filterPeriod: effectivePeriod,
            startDate: effectiveStart,
            endDate: effectiveEnd,
            startDateIso: effectiveStartIso,
            endDateIso: effectiveEndIso,
            searchQuery: effectiveSearch,
          ),
        );
      }
      return AppFetchResult.failure;
    }
  }

  Future<String> _resolveGreeting({required bool isFromCache}) async {
    if (isFromCache) {
      final lastSync =
          await _syncStorage.getLastSync(AppConstants.syncKeyOperational);
      if (lastSync != null) {
        return AppDateFormat.formatGreeting(lastSync);
      }
      return state.lastSync;
    }
    return AppDateFormat.formatGreeting(DateTime.now());
  }

  /// Memuat halaman berikutnya untuk infinite scroll.
  Future<void> loadMoreOperationals() async {
    if (state is! OperationalLoaded) return;
    final currentState = state as OperationalLoaded;

    if (!currentState.hasMore || currentState.isLoadingMore) return;

    final isDefaultPeriod =
        currentState.filterPeriod == AppDateFilterPeriod.today ||
            currentState.filterPeriod == AppDateFilterPeriod.thisWeek ||
            currentState.filterPeriod == AppDateFilterPeriod.thisMonth;
    if (isDefaultPeriod) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getOperationalsUseCase(
      GetOperationalsParams(
        search: currentState.searchQuery,
        limit: pageSize,
        offset: currentState.operationals.length,
        startDate: currentState.startDateIso,
        endDate: currentState.endDateIso,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (operationalResult) {
        final newItems = operationalResult.items;
        final allItems = [...currentState.operationals, ...newItems];
        final hasMore =
            !operationalResult.isFromCache && newItems.length >= pageSize;
        emit(
          currentState.copyWith(
            operationals: allItems,
            hasMore: hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  /// Menerapkan filter rentang waktu dari bottom sheet.
  Future<AppFetchResult> setFilter(
    AppDateFilterResult filterResult,
  ) =>
      fetchOperationals(
        search: state.searchQuery,
        filterPeriod: filterResult.period,
        startDate: filterResult.startDate,
        endDate: filterResult.endDate,
        startDateIso: filterResult.startDateIso,
        endDateIso: filterResult.endDateIso,
      );

  /// Mereset filter tanggal menjadi default 'Hari ini' tanpa menghapus
  /// kata kunci pencarian.
  Future<AppFetchResult> resetDateFilter() {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetchOperationals(
      search: state.searchQuery,
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
    );
  }

  /// Mengatur ulang seluruh filter waktu dan pencarian ke kondisi default.
  Future<AppFetchResult> resetFilters() {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetchOperationals(
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
