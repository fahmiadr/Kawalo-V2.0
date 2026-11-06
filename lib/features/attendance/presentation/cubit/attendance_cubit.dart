import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/request_sequence_guard.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/domain/usecases/get_attendances/get_attendances_usecase.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_state.dart';

/// Cubit pengelola state dan logika bisnis modul Data Absensi.
class AttendanceCubit extends Cubit<AttendanceState> with RequestSequenceGuard {
  /// Membuat instance [AttendanceCubit].
  AttendanceCubit({
    required this.getAttendancesUseCase,
    String initialGreeting = '',
    this.pageSize = AppConstants.defaultPageSize,
    SyncStorageService? syncStorageService,
  })  : _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
        super(
          AttendanceInitial(
            lastSync: SyncStorageService.resolveInitialGreeting(
              initialGreeting: initialGreeting,
              featureKey: AppConstants.syncKeyAttendance,
              storageService: syncStorageService,
            ),
          ),
        ) {
    _initGreeting();
  }

  /// Use case untuk mengambil data absensi.
  final GetAttendancesUseCase getAttendancesUseCase;

  /// Layanan persistensi waktu sinkronisasi data dengan server.
  final SyncStorageService _syncStorage;

  /// Ukuran data per halaman untuk paginasi
  /// (default: [AppConstants.defaultPageSize]).
  final int pageSize;

  String? _activeFetchKey;
  Future<AppFetchResult>? _activeFetchFuture;

  void _initGreeting() {
    if (state.lastSync.isEmpty) {
      _syncStorage.getLastSync(AppConstants.syncKeyAttendance).then((lastSync) {
        if (lastSync != null && state.lastSync.isEmpty && !isClosed) {
          final greeting = AppDateFormat.formatGreeting(lastSync);
          _updateSyncGreeting(greeting);
        }
      });
    }
  }

  void _updateSyncGreeting(String greeting) {
    final currentState = state;
    if (currentState is AttendanceLoaded) {
      emit(currentState.copyWith(lastSync: greeting));
    } else if (currentState is AttendanceInitial) {
      emit(AttendanceInitial(lastSync: greeting));
    } else if (currentState is AttendanceLoading) {
      emit(AttendanceLoading(lastSync: greeting));
    }
  }

  /// Label waktu greeting klien saat ini berdasarkan Single Source of Truth
  /// state.
  String get currentGreeting => state.lastSync;

  /// Mengambil data absensi dari repositori (mock atau REST API backend).
  Future<AppFetchResult> fetchAttendances({
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

  /// Memperbarui data absensi melalui pull-to-refresh tanpa flicker skeleton.
  Future<AppFetchResult> refreshAttendances({
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

  /// Implementasi terpusat pemanggilan usecase pengambilan data absensi
  /// dengan penjagaan urutan request, pembatalan search superseded, dan
  /// sanitasi rentang tanggal otomatis.
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
        state is AttendanceLoaded ? (state as AttendanceLoaded) : null;
    final currentError =
        state is AttendanceError ? (state as AttendanceError) : null;
    final currentAttendances = currentLoaded?.attendances ??
        currentError?.cachedAttendances ??
        const <AttendanceItemEntity>[];

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
      // Jika request dengan parameter sama sedang berjalan di latar belakang,
      // gunakan kembali request tersebut dan tunggu hingga selesai tanpa
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

    if (!isRefresh && state is! AttendanceLoaded) {
      emit(AttendanceLoading(lastSync: state.lastSync));
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
      currentAttendances: currentAttendances,
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
    required List<AttendanceItemEntity> currentAttendances,
    required AppCancellationToken cancelToken,
  }) async {
    try {
      final result = await getAttendancesUseCase(
        GetAttendancesParams(
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
            AttendanceError(
              message: failure.message,
              failure: failure,
              cachedAttendances: isRefresh ? currentAttendances : const [],
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
        (attendanceResult) async {
          final isFromCache = attendanceResult.isFromCache;
          final syncGreeting =
              await _resolveGreeting(isFromCache: isFromCache);

          final hasMore = !isDefaultPeriod &&
              !isFromCache &&
              attendanceResult.items.length >= pageSize;
          emit(
            AttendanceLoaded(
              attendances: attendanceResult.items,
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
          AttendanceError(
            message: failure.message,
            failure: failure,
            cachedAttendances: isRefresh ? currentAttendances : const [],
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
          await _syncStorage.getLastSync(AppConstants.syncKeyAttendance);
      if (lastSync != null) {
        return AppDateFormat.formatGreeting(lastSync);
      }
      return state.lastSync;
    }
    return AppDateFormat.formatGreeting(DateTime.now());
  }

  /// Memuat halaman berikutnya untuk infinite scroll.
  Future<void> loadMoreAttendances() async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

    if (!currentState.hasMore || currentState.isLoadingMore) return;

    final isDefaultPeriod =
        currentState.filterPeriod == AppDateFilterPeriod.today ||
            currentState.filterPeriod == AppDateFilterPeriod.thisWeek ||
            currentState.filterPeriod == AppDateFilterPeriod.thisMonth;
    if (isDefaultPeriod) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getAttendancesUseCase(
      GetAttendancesParams(
        search: currentState.searchQuery,
        limit: pageSize,
        offset: currentState.attendances.length,
        startDate: currentState.startDateIso,
        endDate: currentState.endDateIso,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (attendanceResult) {
        final newItems = attendanceResult.items;
        final allItems = [...currentState.attendances, ...newItems];
        final hasMore =
            !attendanceResult.isFromCache && newItems.length >= pageSize;
        emit(
          currentState.copyWith(
            attendances: allItems,
            hasMore: hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  /// Menerapkan filter waktu dari hasil [AppDateFilterResult].
  Future<AppFetchResult> setFilter(
    AppDateFilterResult filterResult,
  ) =>
      fetchAttendances(
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
    return fetchAttendances(
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
    return fetchAttendances(
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
