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
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_guests/get_guests_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';

/// Cubit pengelola state dan logika bisnis layar data tamu.
class GuestCubit extends Cubit<GuestState> with RequestSequenceGuard {
  /// Membuat instance [GuestCubit].
  GuestCubit({
    required this.getGuestsUseCase,
    required this.deleteGuestUseCase,
    required this.deleteBatchGuestUseCase,
    this.checkoutGuestUseCase,
    this.getGroupMembersUseCase,
    String initialGreeting = '',
    this.pageSize = AppConstants.defaultPageSize,
    SyncStorageService? syncStorageService,
  })  : _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
        super(
          GuestInitial(
            lastSync: SyncStorageService.resolveInitialGreeting(
              initialGreeting: initialGreeting,
              featureKey: AppConstants.syncKeyGuest,
              storageService: syncStorageService,
            ),
          ),
        ) {
    _initGreeting();
  }

  /// Use case untuk mengambil data tamu.
  final GetGuestsUseCase getGuestsUseCase;

  /// Use case untuk menghapus data tamu tunggal.
  final DeleteGuestUseCase deleteGuestUseCase;

  /// Use case untuk menghapus sekumpulan data tamu secara batch.
  final DeleteBatchGuestUseCase deleteBatchGuestUseCase;

  /// Use case untuk melakukan check-out tamu.
  final CheckoutGuestUseCase? checkoutGuestUseCase;

  /// Use case untuk mengambil daftar anggota grup on-demand.
  final GetGroupMembersUseCase? getGroupMembersUseCase;

  /// Layanan persistensi waktu sinkronisasi data dengan server.
  final SyncStorageService _syncStorage;

  /// Jumlah data per halaman untuk infinite scroll
  /// (default: [AppConstants.defaultPageSize]).
  final int pageSize;

  String? _activeFetchKey;
  Future<AppFetchResult>? _activeFetchFuture;

  void _initGreeting() {
    if (state.lastSync.isEmpty) {
      _syncStorage.getLastSync(AppConstants.syncKeyGuest).then((lastSync) {
        if (lastSync != null && state.lastSync.isEmpty && !isClosed) {
          final greeting = AppDateFormat.formatGreeting(lastSync);
          _updateSyncGreeting(greeting);
        }
      });
    }
  }

  void _updateSyncGreeting(String greeting) {
    final currentState = state;
    if (currentState is GuestLoaded) {
      emit(currentState.copyWith(lastSync: greeting));
    } else if (currentState is GuestInitial) {
      emit(GuestInitial(lastSync: greeting));
    } else if (currentState is GuestLoading) {
      emit(GuestLoading(lastSync: greeting));
    }
  }

  /// Label waktu greeting klien saat ini berdasarkan Single Source of Truth
  /// state.
  String get currentGreeting => state.lastSync;

  /// Mengambil data tamu dari repositori (baik mock maupun remote).
  Future<AppFetchResult> fetchGuests({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? creatorEmail,
    String? creatorName,
    bool clearCreatorFilter = false,
  }) =>
      _fetch(
        search: search,
        filterPeriod: filterPeriod,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        creatorEmail: creatorEmail,
        creatorName: creatorName,
        clearCreatorFilter: clearCreatorFilter,
        isRefresh: false,
      );

  /// Memperbarui data tamu secara reaktif melalui tarikan pull-to-refresh.
  Future<AppFetchResult> refreshGuests({
    String? search,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? creatorEmail,
    String? creatorName,
    bool clearCreatorFilter = false,
  }) =>
      _fetch(
        search: search,
        filterPeriod: filterPeriod,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        creatorEmail: creatorEmail,
        creatorName: creatorName,
        clearCreatorFilter: clearCreatorFilter,
        isRefresh: true,
      );

  /// Implementasi terpusat pemanggilan usecase pengambilan data tamu
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
    String? creatorEmail,
    String? creatorName,
    bool clearCreatorFilter = false,
  }) async {
    final currentLoaded = state is GuestLoaded ? (state as GuestLoaded) : null;
    final currentError = state is GuestError ? (state as GuestError) : null;
    final currentGuests = currentLoaded?.guests ??
        currentError?.cachedGuests ??
        const <GuestItemEntity>[];

    final effectivePeriod = filterPeriod ?? state.filterPeriod;
    final effectiveStart = effectivePeriod == AppDateFilterPeriod.custom
        ? (startDate ?? state.startDate)
        : null;
    final effectiveEnd = effectivePeriod == AppDateFilterPeriod.custom
        ? (endDate ?? state.endDate)
        : null;

    final effectiveCreatorEmail = clearCreatorFilter
        ? null
        : (creatorEmail ?? state.filterCreatorEmail);
    final effectiveCreatorName = clearCreatorFilter
        ? null
        : (creatorName ?? state.filterCreatorName);

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
        '$effectiveCreatorEmail';

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

    if (!isRefresh && state is! GuestLoaded) {
      emit(GuestLoading(lastSync: state.lastSync));
    }

    final isDefaultPeriod = effectivePeriod == AppDateFilterPeriod.today ||
        effectivePeriod == AppDateFilterPeriod.thisWeek ||
        effectivePeriod == AppDateFilterPeriod.thisMonth;
    final effectiveLimit = isDefaultPeriod ? 0 : pageSize;

    final fetchOperation = _executeFetch(
      reqId: reqId,
      effectiveSearch: effectiveSearch,
      effectivePeriod: effectivePeriod,
      effectiveCreatorEmail: effectiveCreatorEmail,
      effectiveCreatorName: effectiveCreatorName,
      effectiveStart: effectiveStart,
      effectiveEnd: effectiveEnd,
      effectiveStartIso: effectiveStartIso,
      effectiveEndIso: effectiveEndIso,
      effectiveLimit: effectiveLimit,
      isDefaultPeriod: isDefaultPeriod,
      isRefresh: isRefresh,
      currentGuests: currentGuests,
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
    required String? effectiveCreatorEmail,
    required String? effectiveCreatorName,
    required DateTime? effectiveStart,
    required DateTime? effectiveEnd,
    required String? effectiveStartIso,
    required String? effectiveEndIso,
    required int effectiveLimit,
    required bool isDefaultPeriod,
    required bool isRefresh,
    required List<GuestItemEntity> currentGuests,
    required AppCancellationToken cancelToken,
  }) async {
    try {
      final result = await getGuestsUseCase(
        GetGuestsParams(
          search: effectiveSearch,
          limit: effectiveLimit,
          offset: 0,
          startDate: effectiveStartIso,
          endDate: effectiveEndIso,
          createdBy: effectiveCreatorEmail,
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
            GuestError(
              message: failure.message,
              failure: failure,
              cachedGuests: isRefresh ? currentGuests : const [],
              lastSync: greeting,
              filterPeriod: effectivePeriod,
              filterCreatorEmail: effectiveCreatorEmail,
              filterCreatorName: effectiveCreatorName,
              startDate: effectiveStart,
              endDate: effectiveEnd,
              startDateIso: effectiveStartIso,
              endDateIso: effectiveEndIso,
              searchQuery: effectiveSearch,
            ),
          );
          return AppFetchResult.failure;
        },
        (guestResult) async {
          final isFromCache = guestResult.isFromCache;
          final syncGreeting = await _resolveGreeting(isFromCache: isFromCache);

          final hasMore = !isDefaultPeriod &&
              !isFromCache &&
              guestResult.items.length >= pageSize;

          emit(
            GuestLoaded(
              guests: guestResult.items,
              isFromCache: isFromCache,
              lastSync: syncGreeting,
              hasMore: hasMore,
              filterPeriod: effectivePeriod,
              filterCreatorEmail: effectiveCreatorEmail,
              filterCreatorName: effectiveCreatorName,
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
          GuestError(
            message: failure.message,
            failure: failure,
            cachedGuests: isRefresh ? currentGuests : const [],
            lastSync: greeting,
            filterPeriod: effectivePeriod,
            filterCreatorEmail: effectiveCreatorEmail,
            filterCreatorName: effectiveCreatorName,
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
          await _syncStorage.getLastSync(AppConstants.syncKeyGuest);
      if (lastSync != null) {
        return AppDateFormat.formatGreeting(lastSync);
      }
      return state.lastSync;
    }
    return AppDateFormat.formatGreeting(DateTime.now());
  }

  /// Memuat halaman data tamu berikutnya untuk mendukung infinite scroll.
  Future<void> loadMoreGuests() async {
    if (state is! GuestLoaded) return;
    final currentState = state as GuestLoaded;

    if (!currentState.hasMore || currentState.isLoadingMore) return;

    final isDefaultPeriod =
        currentState.filterPeriod == AppDateFilterPeriod.today ||
            currentState.filterPeriod == AppDateFilterPeriod.thisWeek ||
            currentState.filterPeriod == AppDateFilterPeriod.thisMonth;
    if (isDefaultPeriod) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getGuestsUseCase(
      GetGuestsParams(
        search: currentState.searchQuery,
        limit: pageSize,
        offset: currentState.guests.length,
        startDate: currentState.startDateIso,
        endDate: currentState.endDateIso,
        createdBy: currentState.filterCreatorEmail,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (guestResult) {
        final newGuests = guestResult.items;
        final allGuests = [...currentState.guests, ...newGuests];
        final hasMore =
            !guestResult.isFromCache && newGuests.length >= pageSize;

        emit(
          currentState.copyWith(
            guests: allGuests,
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
      fetchGuests(
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
    return fetchGuests(
      search: state.searchQuery,
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
    );
  }

  /// Mengubah filter pencatat/pembuat data tamu (Creator) oleh ADMIN.
  Future<AppFetchResult> changeCreatorFilter({
    String? email,
    String? name,
  }) =>
      fetchGuests(
        creatorEmail: email,
        creatorName: name,
        clearCreatorFilter: email == null,
      );

  /// Mengatur ulang seluruh filter waktu, pencarian, dan pembuat ke default.
  Future<AppFetchResult> resetFilters() {
    final defaultFilter = AppDateFilterResult.defaultFilter();
    return fetchGuests(
      search: '',
      filterPeriod: defaultFilter.period,
      startDate: defaultFilter.startDate,
      endDate: defaultFilter.endDate,
      startDateIso: defaultFilter.startDateIso,
      endDateIso: defaultFilter.endDateIso,
      clearCreatorFilter: true,
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

  /// Menghapus data tamu [item] atas nama [session].
  ///
  /// Otorisasi (ADMIN atau pembuat) ditegakkan oleh use case; jika ditolak
  /// mengembalikan `Left(ForbiddenFailure)`.
  /// Mengembalikan `Either<Failure, void>` hasil eksekusi.
  /// Jika berhasil, memutasi state [GuestLoaded] dengan mengeluarkan item
  /// yang dihapus secara reaktif tanpa perlu pemanggilan jaringan ulang.
  Future<Either<Failure, void>> deleteGuest(
    GuestItemEntity item, {
    required AuthSessionEntity? session,
  }) async {
    final id = item.id;
    final result = await deleteGuestUseCase(
      DeleteGuestParams(id: id, session: session, item: item),
    );

    result.fold(
      (failure) => null,
      (_) {
        final currentState = state;
        if (currentState is GuestLoaded) {
          final updated =
              currentState.guests.where((item) => item.id != id).toList();
          emit(currentState.copyWith(guests: updated));
        }
      },
    );

    return result;
  }

  /// Menghapus sekumpulan data tamu berdasarkan [ids] atas nama [session].
  ///
  /// Entitas dari [ids] di-resolve dari state aktif (Single Source of Truth);
  /// id yang tidak ditemukan diperlakukan tidak terverifikasi (ditolak).
  /// Mengembalikan `Either<Failure, DeleteBatchResult>` hasil eksekusi.
  /// Jika berhasil, memutasi state [GuestLoaded] dengan mengeluarkan
  /// item yang dihapus secara deterministik tanpa perlu fetch ulang.
  Future<Either<Failure, DeleteBatchResult>> deleteMultipleGuests(
    Set<String> ids, {
    required AuthSessionEntity? session,
  }) async {
    final loadedState = state;
    final knownItems = loadedState is GuestLoaded
        ? loadedState.guests.where((item) => ids.contains(item.id)).toList()
        : <GuestItemEntity>[];
    final result = await deleteBatchGuestUseCase(
      DeleteBatchGuestParams(
        ids: ids.toList(),
        session: session,
        items: knownItems,
      ),
    );

    result.fold(
      (failure) => null,
      (deleteResult) {
        final currentState = state;
        if (currentState is GuestLoaded) {
          final updated = currentState.guests
              .where((item) => !ids.contains(item.id))
              .toList();
          emit(currentState.copyWith(guests: updated));
        }
      },
    );

    return result;
  }

  /// Melakukan check-out tamu [item] atas nama [session].
  ///
  /// Otorisasi (ADMIN atau GUARD) ditegakkan oleh use case; jika ditolak
  /// mengembalikan `Left(ForbiddenFailure)`.
  /// Mengembalikan `Either<Failure, GuestItemEntity>` hasil eksekusi.
  /// Jika berhasil, memutasi state [GuestLoaded] dengan memperbarui item tamu
  /// yang sudah di-checkout secara reaktif via [onGuestUpdated].
  Future<Either<Failure, GuestItemEntity>> checkoutGuest(
    GuestItemEntity item, {
    required AuthSessionEntity? session,
    String? qrUid,
  }) async {
    final useCase = checkoutGuestUseCase;
    if (useCase == null) {
      return const Left(ServerFailure('Layanan checkout tamu tidak tersedia.'));
    }

    final result = await useCase(
      CheckoutGuestParams(
        id: item.id,
        session: session,
        item: item,
        qrUid: qrUid,
      ),
    );

    result.fold(
      (failure) => null,
      onGuestUpdated,
    );

    return result;
  }

  /// Menambahkan item tamu baru [item] ke dalam state aktif secara reaktif
  /// tanpa flicker atau kebutuhan re-fetch penuh.
  void onGuestCreated(GuestItemEntity item) {
    final currentState = state;
    if (currentState is GuestLoaded) {
      final updated = [item, ...currentState.guests];
      emit(currentState.copyWith(guests: updated));
    }
  }

  /// Memperbarui item tamu [item] di dalam state aktif secara reaktif.
  void onGuestUpdated(GuestItemEntity item) {
    final currentState = state;
    if (currentState is GuestLoaded) {
      final updated = currentState.guests
          .map((i) => i.id == item.id ? item : i)
          .toList();
      emit(currentState.copyWith(guests: updated));
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
