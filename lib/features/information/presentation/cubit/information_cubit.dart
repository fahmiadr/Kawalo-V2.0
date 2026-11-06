import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/request_sequence_guard.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_params.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/get_information/get_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/get_information_params.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';

/// Cubit pengelola state dan logika bisnis modul Data Informasi.
class InformationCubit extends Cubit<InformationState>
    with RequestSequenceGuard {
  /// Membuat instance [InformationCubit].
  InformationCubit({
    required this.getInformationUseCase,
    required this.deleteInformationUseCase,
    required this.deleteBatchInformationUseCase,
    this.getGroupMembersUseCase,
    String initialGreeting = '',
    this.pageSize = AppConstants.defaultPageSize,
    SyncStorageService? syncStorageService,
  })  : _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
        super(
          InformationInitial(
            lastSync: SyncStorageService.resolveInitialGreeting(
              initialGreeting: initialGreeting,
              featureKey: AppConstants.syncKeyInformation,
              storageService: syncStorageService,
            ),
          ),
        ) {
    _initGreeting();
  }

  /// Use case untuk mengambil data informasi.
  final GetInformationUseCase getInformationUseCase;

  /// Use case untuk menghapus data informasi tunggal.
  final DeleteInformationUseCase deleteInformationUseCase;

  /// Use case untuk menghapus beberapa data informasi sekaligus (batch).
  final DeleteBatchInformationUseCase deleteBatchInformationUseCase;

  /// Use case untuk memuat daftar anggota grup on-demand.
  final GetGroupMembersUseCase? getGroupMembersUseCase;

  /// Layanan persistensi waktu sinkronisasi data dengan server.
  final SyncStorageService _syncStorage;

  /// Ukuran data per halaman untuk paginasi
  /// (default: [AppConstants.defaultPageSize]).
  final int pageSize;

  String? _activeFetchKey;
  Future<AppFetchResult>? _activeFetchFuture;

  void _initGreeting() {
    if (state.lastSync.isEmpty) {
      _syncStorage
          .getLastSync(AppConstants.syncKeyInformation)
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
    if (currentState is InformationLoaded) {
      emit(currentState.copyWith(lastSync: greeting));
    } else if (currentState is InformationInitial) {
      emit(InformationInitial(lastSync: greeting));
    } else if (currentState is InformationLoading) {
      emit(InformationLoading(lastSync: greeting));
    }
  }

  /// Label waktu greeting klien saat ini berdasarkan Single Source of Truth
  /// state.
  String get currentGreeting => state.lastSync;

  /// Mengambil data informasi dari repositori (mock atau REST API backend).
  Future<AppFetchResult> fetchInformation({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? authorEmail,
    String? authorName,
    bool clearAuthorFilter = false,
  }) =>
      _fetch(
        search: search,
        filterPeriod: filterPeriod,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        authorEmail: authorEmail,
        authorName: authorName,
        clearAuthorFilter: clearAuthorFilter,
        isRefresh: false,
      );

  /// Memperbarui data informasi melalui pull-to-refresh tanpa flicker skeleton.
  Future<AppFetchResult> refreshInformation({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? authorEmail,
    String? authorName,
    bool clearAuthorFilter = false,
  }) =>
      _fetch(
        search: search,
        filterPeriod: filterPeriod,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        authorEmail: authorEmail,
        authorName: authorName,
        clearAuthorFilter: clearAuthorFilter,
        isRefresh: true,
      );

  /// Implementasi terpusat pemanggilan usecase pengambilan data informasi
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
    String? authorEmail,
    String? authorName,
    bool clearAuthorFilter = false,
  }) async {
    final currentLoaded =
        state is InformationLoaded ? (state as InformationLoaded) : null;
    final currentError =
        state is InformationError ? (state as InformationError) : null;
    final currentInformation = currentLoaded?.information ??
        currentError?.cachedInformation ??
        const <InformationItemEntity>[];

    final effectivePeriod = filterPeriod ?? state.filterPeriod;
    final effectiveStart = effectivePeriod == AppDateFilterPeriod.custom
        ? (startDate ?? state.startDate)
        : null;
    final effectiveEnd = effectivePeriod == AppDateFilterPeriod.custom
        ? (endDate ?? state.endDate)
        : null;

    final effectiveAuthorEmail = clearAuthorFilter
        ? null
        : (authorEmail ?? state.filterAuthorEmail);
    final effectiveAuthorName = clearAuthorFilter
        ? null
        : (authorName ?? state.filterAuthorName);

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
        '$effectiveEndIso|$effectiveSearch|'
        '$effectiveAuthorEmail';

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

    if (!isRefresh && state is! InformationLoaded) {
      emit(InformationLoading(lastSync: state.lastSync));
    }

    final isDefaultPeriod = effectivePeriod == AppDateFilterPeriod.today ||
        effectivePeriod == AppDateFilterPeriod.thisWeek ||
        effectivePeriod == AppDateFilterPeriod.thisMonth;
    final effectiveLimit = isDefaultPeriod ? 0 : pageSize;

    final fetchOperation = _executeFetch(
      reqId: reqId,
      effectiveSearch: effectiveSearch,
      effectivePeriod: effectivePeriod,
      effectiveAuthorEmail: effectiveAuthorEmail,
      effectiveAuthorName: effectiveAuthorName,
      effectiveStart: effectiveStart,
      effectiveEnd: effectiveEnd,
      effectiveStartIso: effectiveStartIso,
      effectiveEndIso: effectiveEndIso,
      effectiveLimit: effectiveLimit,
      isDefaultPeriod: isDefaultPeriod,
      isRefresh: isRefresh,
      currentInformation: currentInformation,
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
    required String? effectiveAuthorEmail,
    required String? effectiveAuthorName,
    required DateTime? effectiveStart,
    required DateTime? effectiveEnd,
    required String? effectiveStartIso,
    required String? effectiveEndIso,
    required int effectiveLimit,
    required bool isDefaultPeriod,
    required bool isRefresh,
    required List<InformationItemEntity> currentInformation,
    required AppCancellationToken cancelToken,
  }) async {
    try {
      final result = await getInformationUseCase(
        GetInformationParams(
          search: effectiveSearch,
          limit: effectiveLimit,
          offset: 0,
          startDate: effectiveStartIso,
          endDate: effectiveEndIso,
          createdBy: effectiveAuthorEmail,
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
            InformationError(
              message: failure.message,
              failure: failure,
              cachedInformation:
                  isRefresh ? currentInformation : const [],
              lastSync: greeting,
              filterPeriod: effectivePeriod,
              filterAuthorEmail: effectiveAuthorEmail,
              filterAuthorName: effectiveAuthorName,
              startDate: effectiveStart,
              endDate: effectiveEnd,
              startDateIso: effectiveStartIso,
              endDateIso: effectiveEndIso,
              searchQuery: effectiveSearch,
            ),
          );
          return AppFetchResult.failure;
        },
        (informationResult) async {
          final isFromCache = informationResult.isFromCache;
          final syncGreeting =
              await _resolveGreeting(isFromCache: isFromCache);

          final hasMore = !isDefaultPeriod &&
              !isFromCache &&
              informationResult.items.length >= pageSize;

          emit(
            InformationLoaded(
              information: informationResult.items,
              isFromCache: isFromCache,
              lastSync: syncGreeting,
              hasMore: hasMore,
              filterPeriod: effectivePeriod,
              filterAuthorEmail: effectiveAuthorEmail,
              filterAuthorName: effectiveAuthorName,
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
          InformationError(
            message: failure.message,
            failure: failure,
            cachedInformation:
                isRefresh ? currentInformation : const [],
            lastSync: greeting,
            filterPeriod: effectivePeriod,
            filterAuthorEmail: effectiveAuthorEmail,
            filterAuthorName: effectiveAuthorName,
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
          await _syncStorage.getLastSync(AppConstants.syncKeyInformation);
      if (lastSync != null) {
        return AppDateFormat.formatGreeting(lastSync);
      }
      return state.lastSync;
    }
    return AppDateFormat.formatGreeting(DateTime.now());
  }

  /// Memuat halaman berikutnya untuk infinite scroll.
  Future<void> loadMoreInformation() async {
    if (state is! InformationLoaded) return;
    final currentState = state as InformationLoaded;

    if (!currentState.hasMore || currentState.isLoadingMore) return;

    final isDefaultPeriod =
        currentState.filterPeriod == AppDateFilterPeriod.today ||
            currentState.filterPeriod == AppDateFilterPeriod.thisWeek ||
            currentState.filterPeriod == AppDateFilterPeriod.thisMonth;
    if (isDefaultPeriod) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getInformationUseCase(
      GetInformationParams(
        search: currentState.searchQuery,
        limit: pageSize,
        offset: currentState.information.length,
        startDate: currentState.startDateIso,
        endDate: currentState.endDateIso,
        createdBy: currentState.filterAuthorEmail,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (informationResult) {
        final newItems = informationResult.items;
        final allItems = [...currentState.information, ...newItems];
        final hasMore =
            !informationResult.isFromCache && newItems.length >= pageSize;
        emit(
          currentState.copyWith(
            information: allItems,
            hasMore: hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  /// Menerapkan filter waktu dari hasil [AppDateFilterResult].
  Future<AppFetchResult> setFilter(AppDateFilterResult filterResult) =>
      fetchInformation(
        search: state.searchQuery,
        filterPeriod: filterResult.period,
        startDate: filterResult.startDate,
        endDate: filterResult.endDate,
        startDateIso: filterResult.startDateIso,
        endDateIso: filterResult.endDateIso,
      );

  /// Mereset filter tanggal menjadi default 'Hari ini' tanpa menghapus
  /// kata kunci pencarian maupun filter pembuat.
  Future<AppFetchResult> resetDateFilter() {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetchInformation(
      search: state.searchQuery,
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
    );
  }

  /// Mengubah filter pembuat informasi (Author / Creator) oleh ADMIN.
  Future<AppFetchResult> changeAuthorFilter({
    String? email,
    String? name,
  }) =>
      fetchInformation(
        authorEmail: email,
        authorName: name,
        clearAuthorFilter: email == null,
      );

  /// Mengatur ulang seluruh filter waktu, pencarian, dan pembuat ke default.
  Future<AppFetchResult> resetFilters() {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetchInformation(
      search: '',
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
      clearAuthorFilter: true,
    );
  }

  /// Memuat daftar anggota grup secara segar on-demand dari remote service.
  ///
  /// Mengembalikan `Either<Failure, List<GroupMemberEntity>>` hasil eksekusi.
  Future<Either<Failure, List<GroupMemberEntity>>> loadGroupMembers({
    AppCancellationToken? cancelToken,
  }) async {
    final useCase = getGroupMembersUseCase;
    if (useCase == null) {
      return const Left(ServerFailure('Layanan anggota grup tidak tersedia.'));
    }
    return await useCase.call(
      GetGroupMembersParams(cancelToken: cancelToken),
    );
  }

  /// Menghapus data informasi [item] atas nama [session].
  ///
  /// Otorisasi (ADMIN atau pembuat) ditegakkan oleh use case; jika ditolak
  /// mengembalikan `Left(ForbiddenFailure)`.
  /// Mengembalikan `Either<Failure, void>` hasil eksekusi.
  /// Jika berhasil, memutasi state [InformationLoaded] dengan mengeluarkan item
  /// yang dihapus secara reaktif tanpa perlu pemanggilan jaringan ulang.
  Future<Either<Failure, void>> deleteInformation(
    InformationItemEntity item, {
    required AuthSessionEntity? session,
  }) async {
    final id = item.id;
    final result = await deleteInformationUseCase(
      DeleteInformationParams(id: id, session: session, item: item),
    );

    result.fold(
      (failure) => null,
      (_) {
        final currentState = state;
        if (currentState is InformationLoaded) {
          final updated = currentState.information
              .where((item) => item.id != id)
              .toList();
          emit(currentState.copyWith(information: updated));
        }
      },
    );

    return result;
  }

  /// Menghapus beberapa data informasi sekaligus berdasarkan sekumpulan [ids]
  /// atas nama [session].
  ///
  /// Entitas dari [ids] di-resolve dari state aktif (Single Source of Truth);
  /// id yang tidak ditemukan diperlakukan tidak terverifikasi (ditolak).
  /// Mengembalikan `Either<Failure, DeleteBatchResult>` hasil eksekusi.
  /// Jika berhasil, memutasi state [InformationLoaded] dengan mengeluarkan
  /// item yang dihapus secara deterministik tanpa perlu fetch ulang.
  Future<Either<Failure, DeleteBatchResult>> deleteMultipleInformation(
    Set<String> ids, {
    required AuthSessionEntity? session,
  }) async {
    final loadedState = state;
    final knownItems = loadedState is InformationLoaded
        ? loadedState.information
            .where((item) => ids.contains(item.id))
            .toList()
        : <InformationItemEntity>[];
    final result = await deleteBatchInformationUseCase(
      DeleteBatchInformationParams(
        ids: ids.toList(),
        session: session,
        items: knownItems,
      ),
    );

    result.fold(
      (failure) => null,
      (deleteResult) {
        final currentState = state;
        if (currentState is InformationLoaded) {
          final updated = currentState.information
              .where((item) => !ids.contains(item.id))
              .toList();
          emit(currentState.copyWith(information: updated));
        }
      },
    );

    return result;
  }

  /// Menambahkan item informasi baru [item] ke dalam state aktif secara reaktif
  /// tanpa flicker atau kebutuhan re-fetch penuh.
  void onInformationCreated(InformationItemEntity item) {
    final currentState = state;
    if (currentState is InformationLoaded) {
      final updated = [item, ...currentState.information];
      emit(currentState.copyWith(information: updated));
    }
  }

  /// Memperbarui item informasi [item] di dalam state aktif secara reaktif.
  void onInformationUpdated(InformationItemEntity item) {
    final currentState = state;
    if (currentState is InformationLoaded) {
      final updated = currentState.information
          .map((existing) => existing.id == item.id ? item : existing)
          .toList();
      emit(currentState.copyWith(information: updated));
    }
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
