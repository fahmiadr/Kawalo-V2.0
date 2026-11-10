import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/guest/data/mappers/guest_local_mapper.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_local_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';

/// Kontrak sumber data tamu lokal untuk penyimpanan dan fallback offline.
abstract class GuestLocalDataSource implements CacheWipeable {
  /// Menyimpan daftar tamu ke cache lokal Isar.
  Future<void> cacheGuests(List<GuestModel> items);

  /// Mengambil data tamu dari cache lokal Isar dengan filter pencarian,
  /// grup, rentang tanggal, pembuat data tamu (`createdBy` / `guestCreatorEmail`),
  /// dan status masih di lokasi (`isActive`, berdasarkan `guestOutDt`).
  Future<List<GuestModel>> getCachedGuests({
    String? search,
    String? startDate,
    String? endDate,
    String? createdBy,
    bool? isActive,
  });

  /// Menghapus data tamu lokal yang lebih lama dari [threshold]
  /// (rolling window eviction 30 hari).
  Future<void> deleteOlderThan(DateTime threshold);

  /// Mengosongkan seluruh cache data tamu.
  @override
  Future<void> clearCache();

  /// Menghapus data tamu tertentu dari cache lokal Isar berdasarkan [id].
  Future<bool> deleteGuest(String id);

  /// Menghapus sekumpulan data tamu dari cache lokal Isar berdasarkan [ids].
  Future<int> deleteBatchGuests(List<String> ids);
}

/// Implementasi konkret [GuestLocalDataSource] menggunakan database [Isar].
class GuestLocalDataSourceImpl implements GuestLocalDataSource {
  /// Membuat instance [GuestLocalDataSourceImpl].
  GuestLocalDataSourceImpl({required this.isar});

  /// Instance database Isar.
  final Isar isar;

  @override
  String get collectionName => GuestLocalModelSchema.name;

  @override
  Future<void> cacheGuests(List<GuestModel> items) async {
    final collections = GuestLocalMapper.toLocalList(items);
    await isar.writeTxn(() async {
      await isar.guestLocalModels.putAll(collections);
    });
  }

  @override
  Future<List<GuestModel>> getCachedGuests({
    String? search,
    String? startDate,
    String? endDate,
    String? createdBy,
    bool? isActive,
  }) async {
    var query = isar.guestLocalModels.where().filter().idIsNotEmpty();

    if (isActive != null) {
      query = isActive
          ? query.and().guestOutDtIsNull()
          : query.and().guestOutDtIsNotNull();
    }

    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.and().guestCreatorEmailEqualTo(
        createdBy,
        caseSensitive: false,
      );
    }

    if (search != null && search.isNotEmpty) {
      final q = search;
      query = query.and().group(
        (qBuilder) => qBuilder
            .guestNameContains(q, caseSensitive: false)
            .or()
            .guestNumberContains(q, caseSensitive: false)
            .or()
            .guestIdentityContains(q, caseSensitive: false)
            .or()
            .guestIdentityTypeContains(q, caseSensitive: false)
            .or()
            .guestPurposeContains(q, caseSensitive: false)
            .or()
            .guestDestinationContains(q, caseSensitive: false)
            .or()
            .guestToUserEmailContains(q, caseSensitive: false)
            .or()
            .guestToUserNameContains(q, caseSensitive: false)
            .or()
            .guestCreatorEmailContains(q, caseSensitive: false)
            .or()
            .guestCreatorNameContains(q, caseSensitive: false)
            .or()
            .guestCategoryContains(q, caseSensitive: false)
            .or()
            .guestAddressContains(q, caseSensitive: false)
            .or()
            .guestTypeContains(q, caseSensitive: false)
            .or()
            .guestCheckoutByEmailContains(q, caseSensitive: false)
            .or()
            .guestCheckoutByNameContains(q, caseSensitive: false)
            .or()
            .qrUidContains(q, caseSensitive: false),
      );
    }

    if (startDate != null) {
      final startSpace = startDate.replaceFirst('T', ' ');
      final startT = startDate.replaceFirst(' ', 'T');
      query = query.and().group(
        (q) => q
            .guestDtGreaterThan(startSpace, include: true)
            .or()
            .guestDtGreaterThan(startT, include: true),
      );
    }

    if (endDate != null) {
      final endSpace = endDate.replaceFirst('T', ' ');
      final endT = endDate.replaceFirst(' ', 'T');
      query = query.and().group(
        (q) => q
            .guestDtLessThan(endSpace, include: true)
            .or()
            .guestDtLessThan(endT, include: true),
      );
    }

    final collections = await query.sortByGuestDtDesc().findAll();
    return GuestLocalMapper.fromLocalList(collections);
  }

  @override
  Future<void> deleteOlderThan(DateTime threshold) async {
    final thresholdIso = threshold.toUtc().toIso8601String();
    await isar.writeTxn(() async {
      await isar.guestLocalModels
          .filter()
          .guestDtLessThan(thresholdIso)
          .deleteAll();
    });
  }

  @override
  Future<bool> deleteGuest(String id) async {
    return await isar.writeTxn(() async {
      return await isar.guestLocalModels.deleteById(id);
    });
  }

  @override
  Future<int> deleteBatchGuests(List<String> ids) async {
    return await isar.writeTxn(() async {
      return await isar.guestLocalModels.deleteAllById(ids);
    });
  }

  @override
  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.guestLocalModels.clear();
    });
  }
}
