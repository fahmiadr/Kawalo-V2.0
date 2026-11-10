import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/acknowledge_guest/acknowledge_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/acknowledge_guest/acknowledge_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';

/// Cubit pengelola state dan logika bisnis layar data tamu.
///
/// The fetch, pagination and greeting skeleton lives in [ListFetchCubit]; this
/// class only maps the guest use cases and state.
class GuestCubit extends ListFetchCubit<GuestState, GuestItemEntity> {
  /// Membuat instance [GuestCubit].
  GuestCubit({
    required this.guestRepository,
    required this.deleteGuestUseCase,
    required this.deleteBatchGuestUseCase,
    required super.syncStorageService,
    this.checkoutGuestUseCase,
    this.acknowledgeGuestUseCase,
    this.groupRepository,
    String initialGreeting = '',
    super.pageSize = AppConstants.defaultPageSize,
  }) : super(
         GuestInitial(
           lastSync: SyncStorageService.resolveInitialGreeting(
             initialGreeting: initialGreeting,
             featureKey: AppConstants.syncKeyGuest,
             storageService: syncStorageService,
           ),
         ),
         syncKey: AppConstants.syncKeyGuest,
       );

  /// Repositori data tamu.
  final GuestRepository guestRepository;

  /// Use case untuk menghapus data tamu tunggal.
  final DeleteGuestUseCase deleteGuestUseCase;

  /// Use case untuk menghapus sekumpulan data tamu secara batch.
  final DeleteBatchGuestUseCase deleteBatchGuestUseCase;

  /// Use case untuk melakukan check-out tamu.
  final CheckoutGuestUseCase? checkoutGuestUseCase;

  /// Use case untuk mengonfirmasi kunjungan tamu.
  final AcknowledgeGuestUseCase? acknowledgeGuestUseCase;

  /// Repositori grup untuk mengambil daftar anggota on-demand.
  final GroupRepository? groupRepository;

  @override
  GuestState? stateWithLastSync(String greeting) {
    final current = state;
    if (current is GuestLoaded) {
      return current.copyWith(lastSync: greeting);
    } else if (current is GuestInitial) {
      return GuestInitial(lastSync: greeting);
    } else if (current is GuestLoading) {
      return GuestLoading(lastSync: greeting);
    }
    return null;
  }

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
    bool? isActive,
    bool clearActiveFilter = false,
  }) => _fetch(
    search: search,
    filterPeriod: filterPeriod,
    startDate: startDate,
    endDate: endDate,
    startDateIso: startDateIso,
    endDateIso: endDateIso,
    creatorEmail: creatorEmail,
    creatorName: creatorName,
    clearCreatorFilter: clearCreatorFilter,
    isActive: isActive,
    clearActiveFilter: clearActiveFilter,
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
    bool? isActive,
    bool clearActiveFilter = false,
  }) => _fetch(
    search: search,
    filterPeriod: filterPeriod,
    startDate: startDate,
    endDate: endDate,
    startDateIso: startDateIso,
    endDateIso: endDateIso,
    creatorEmail: creatorEmail,
    creatorName: creatorName,
    clearCreatorFilter: clearCreatorFilter,
    isActive: isActive,
    clearActiveFilter: clearActiveFilter,
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
    String? creatorEmail,
    String? creatorName,
    bool clearCreatorFilter = false,
    bool? isActive,
    bool clearActiveFilter = false,
  }) {
    final effectiveIsActive = clearActiveFilter
        ? null
        : (isActive ?? state.filterIsActive);
    final effectiveCreatorEmail = clearCreatorFilter
        ? null
        : (creatorEmail ?? state.filterCreatorEmail);
    final effectiveCreatorName = clearCreatorFilter
        ? null
        : (creatorName ?? state.filterCreatorName);
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
      extraKey: '$effectiveCreatorEmail|$effectiveIsActive',
      currentItems: state.displayedGuests,
      loading: (lastSync) => GuestLoading(lastSync: lastSync),
      request: (limit, cancelToken) async => (await guestRepository.getGuests(
        GetGuestsParams(
          search: filter.search,
          limit: limit,
          offset: 0,
          startDate: filter.startIso,
          endDate: filter.endIso,
          createdBy: effectiveCreatorEmail,
          isActive: effectiveIsActive,
          cancelToken: cancelToken,
          isRefresh: isRefresh,
        ),
      )).map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
      loaded: (page, lastSync, {required hasMore}) => GuestLoaded(
        guests: page.items,
        isFromCache: page.isFromCache,
        lastSync: lastSync,
        hasMore: hasMore,
        filterPeriod: filter.period,
        filterCreatorEmail: effectiveCreatorEmail,
        filterCreatorName: effectiveCreatorName,
        filterIsActive: effectiveIsActive,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
      error: (failure, cached, lastSync) => GuestError(
        message: failure.message,
        failure: failure,
        cachedGuests: cached,
        lastSync: lastSync,
        filterPeriod: filter.period,
        filterCreatorEmail: effectiveCreatorEmail,
        filterCreatorName: effectiveCreatorName,
        filterIsActive: effectiveIsActive,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
    );
  }

  /// Memuat halaman data tamu berikutnya untuk mendukung infinite scroll.
  Future<void> loadMoreGuests() => runLoadMore<GuestLoaded>(
    request: (current) async => (await guestRepository.getGuests(
      GetGuestsParams(
        search: current.searchQuery,
        limit: pageSize,
        offset: current.guests.length,
        startDate: current.startDateIso,
        endDate: current.endDateIso,
        createdBy: current.filterCreatorEmail,
        isActive: current.filterIsActive,
      ),
    )).map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
    setLoadingMore: (current, {required loadingMore}) =>
        current.copyWith(isLoadingMore: loadingMore),
    append: (current, newItems, {required hasMore}) => current.copyWith(
      guests: [...current.guests, ...newItems],
      hasMore: hasMore,
      isLoadingMore: false,
    ),
  );

  /// Menerapkan filter waktu dari hasil [AppDateFilterResult].
  Future<AppFetchResult> setFilter(AppDateFilterResult filterResult) =>
      applyDateFilter(fetchGuests, filterResult);

  /// Mereset filter tanggal menjadi default 'Hari ini' tanpa menghapus
  /// kata kunci pencarian maupun filter pembuat.
  Future<AppFetchResult> resetDateFilter() => resetDateFilterWith(fetchGuests);

  /// Mengubah filter pencatat/pembuat data tamu (Creator) oleh ADMIN.
  Future<AppFetchResult> changeCreatorFilter({String? email, String? name}) =>
      fetchGuests(
        creatorEmail: email,
        creatorName: name,
        clearCreatorFilter: email == null,
      );

  /// Menyalakan (`true`) atau mematikan (`null`) filter "Masih di lokasi".
  Future<AppFetchResult> changeActiveFilter({bool? isActive}) =>
      fetchGuests(isActive: isActive, clearActiveFilter: isActive == null);

  /// Mengatur ulang seluruh filter waktu, pencarian, pembuat, dan status ke
  /// default.
  Future<AppFetchResult> resetFilters() => resetAllFiltersWith(
    ({search, filterPeriod, startDate, endDate, startDateIso, endDateIso}) =>
        fetchGuests(
          search: search,
          filterPeriod: filterPeriod,
          startDate: startDate,
          endDate: endDate,
          startDateIso: startDateIso,
          endDateIso: endDateIso,
          clearCreatorFilter: true,
          clearActiveFilter: true,
        ),
  );

  /// Memuat daftar anggota grup secara segar on-demand dari remote service.
  ///
  /// Mengembalikan `Either<Failure, List<GroupMemberEntity>>` hasil eksekusi.
  Future<Either<Failure, List<GroupMemberEntity>>> loadGroupMembers({
    AppCancellationToken? cancelToken,
  }) async {
    final repo = groupRepository;
    if (repo == null) {
      return const Left(ServerFailure('Layanan anggota grup tidak tersedia.'));
    }
    return await repo.getMembers(cancelToken: cancelToken);
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

    result.fold((failure) => null, (_) {
      final currentState = state;
      if (currentState is GuestLoaded) {
        final updated = currentState.guests
            .where((item) => item.id != id)
            .toList();
        emit(currentState.copyWith(guests: updated));
      }
    });

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

    result.fold((failure) => null, (deleteResult) {
      final currentState = state;
      if (currentState is GuestLoaded) {
        final updated = currentState.guests
            .where((item) => !ids.contains(item.id))
            .toList();
        emit(currentState.copyWith(guests: updated));
      }
    });

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

    result.fold((failure) => null, onGuestUpdated);

    return result;
  }

  /// Mengonfirmasi kunjungan tamu [item] atas nama [session].
  ///
  /// Otorisasi (ADMIN, GUARD, atau penghuni tujuan) ditegakkan oleh use case.
  /// Jika berhasil, item di state aktif diganti dengan hasil dari server.
  Future<Either<Failure, GuestItemEntity>> acknowledgeGuest(
    GuestItemEntity item, {
    required AuthSessionEntity? session,
    String? qrUid,
  }) async {
    final useCase = acknowledgeGuestUseCase;
    if (useCase == null) {
      return const Left(
        ServerFailure('Layanan konfirmasi tamu tidak tersedia.'),
      );
    }

    final result = await useCase(
      AcknowledgeGuestParams(
        id: item.id,
        session: session,
        item: item,
        qrUid: qrUid,
      ),
    );

    result.fold((failure) => null, onGuestUpdated);

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
}
