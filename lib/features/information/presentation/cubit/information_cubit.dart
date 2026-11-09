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
///
/// Kerangka fetch/paginasi/greeting ada di [ListFetchCubit]; kelas ini
/// menambahkan filter pembuat, use case, dan mutasi item informasi.
class InformationCubit
    extends ListFetchCubit<InformationState, InformationItemEntity> {
  /// Membuat instance [InformationCubit].
  InformationCubit({
    required this.getInformationUseCase,
    required this.deleteInformationUseCase,
    required this.deleteBatchInformationUseCase,
    this.getGroupMembersUseCase,
    String initialGreeting = '',
    super.pageSize = AppConstants.defaultPageSize,
    super.syncStorageService,
  }) : super(
          InformationInitial(
            lastSync: SyncStorageService.resolveInitialGreeting(
              initialGreeting: initialGreeting,
              featureKey: AppConstants.syncKeyInformation,
              storageService: syncStorageService,
            ),
          ),
          syncKey: AppConstants.syncKeyInformation,
        );

  /// Use case untuk mengambil data informasi.
  final GetInformationUseCase getInformationUseCase;

  /// Use case untuk menghapus data informasi tunggal.
  final DeleteInformationUseCase deleteInformationUseCase;

  /// Use case untuk menghapus beberapa data informasi sekaligus (batch).
  final DeleteBatchInformationUseCase deleteBatchInformationUseCase;

  /// Use case untuk memuat daftar anggota grup on-demand.
  final GetGroupMembersUseCase? getGroupMembersUseCase;

  @override
  InformationState? stateWithLastSync(String greeting) {
    final current = state;
    if (current is InformationLoaded) {
      return current.copyWith(lastSync: greeting);
    } else if (current is InformationInitial) {
      return InformationInitial(lastSync: greeting);
    } else if (current is InformationLoading) {
      return InformationLoading(lastSync: greeting);
    }
    return null;
  }

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

  /// Memperbarui data informasi secara reaktif melalui tarikan pull-to-refresh.
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
  }) {
    final effectiveAuthorEmail =
        clearAuthorFilter ? null : (authorEmail ?? state.filterAuthorEmail);
    final effectiveAuthorName =
        clearAuthorFilter ? null : (authorName ?? state.filterAuthorName);
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
      extraKey: '$effectiveAuthorEmail',
      currentItems: state.displayedInformation,
      loading: (lastSync) => InformationLoading(lastSync: lastSync),
      request: (limit, cancelToken) async => (await getInformationUseCase(
        GetInformationParams(
          search: filter.search,
          limit: limit,
          offset: 0,
          startDate: filter.startIso,
          endDate: filter.endIso,
          createdBy: effectiveAuthorEmail,
          cancelToken: cancelToken,
          isRefresh: isRefresh,
        ),
      ))
          .map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
      loaded: (page, lastSync, {required hasMore}) => InformationLoaded(
        information: page.items,
        isFromCache: page.isFromCache,
        lastSync: lastSync,
        hasMore: hasMore,
        filterPeriod: filter.period,
        filterAuthorEmail: effectiveAuthorEmail,
        filterAuthorName: effectiveAuthorName,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
      error: (failure, cached, lastSync) => InformationError(
        message: failure.message,
        failure: failure,
        cachedInformation: cached,
        lastSync: lastSync,
        filterPeriod: filter.period,
        filterAuthorEmail: effectiveAuthorEmail,
        filterAuthorName: effectiveAuthorName,
        startDate: filter.start,
        endDate: filter.end,
        startDateIso: filter.startIso,
        endDateIso: filter.endIso,
        searchQuery: filter.search,
      ),
    );
  }

  /// Memuat halaman data informasi berikutnya untuk mendukung infinite scroll.
  Future<void> loadMoreInformation() => runLoadMore<InformationLoaded>(
        request: (current) async => (await getInformationUseCase(
          GetInformationParams(
            search: current.searchQuery,
            limit: pageSize,
            offset: current.information.length,
            startDate: current.startDateIso,
            endDate: current.endDateIso,
            createdBy: current.filterAuthorEmail,
          ),
        ))
            .map((r) => ListPage(r.items, isFromCache: r.isFromCache)),
        setLoadingMore: (current, {required loadingMore}) =>
            current.copyWith(isLoadingMore: loadingMore),
        append: (current, newItems, {required hasMore}) => current.copyWith(
          information: [...current.information, ...newItems],
          hasMore: hasMore,
          isLoadingMore: false,
        ),
      );

  /// Menerapkan filter waktu dari hasil [AppDateFilterResult].
  Future<AppFetchResult> setFilter(AppDateFilterResult filterResult) =>
      applyDateFilter(fetchInformation, filterResult);

  /// Mereset filter tanggal menjadi default 'Hari ini' tanpa menghapus
  /// kata kunci pencarian maupun filter pembuat.
  Future<AppFetchResult> resetDateFilter() =>
      resetDateFilterWith(fetchInformation);

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
  Future<AppFetchResult> resetFilters() => resetAllFiltersWith(
        ({
          search,
          filterPeriod,
          startDate,
          endDate,
          startDateIso,
          endDateIso,
        }) =>
            fetchInformation(
          search: search,
          filterPeriod: filterPeriod,
          startDate: startDate,
          endDate: endDate,
          startDateIso: startDateIso,
          endDateIso: endDateIso,
          clearAuthorFilter: true,
        ),
      );

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
          final updated =
              currentState.information.where((item) => item.id != id).toList();
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
}
