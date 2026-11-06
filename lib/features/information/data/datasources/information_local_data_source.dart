import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/information/data/mappers/information_local_mapper.dart';
import 'package:kawalo_mobile/features/information/data/models/information_local_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';

/// Kontrak sumber data informasi / feed lokal untuk penyimpanan,
/// fallback offline, dan kebijakan cache eviction.
abstract class InformationLocalDataSource implements CacheWipeable {
  /// Menyimpan daftar informasi ke cache lokal Isar.
  Future<void> cacheInformation(List<InformationModel> items);

  /// Mengambil data informasi dari cache lokal Isar dengan filter pencarian,
  /// rentang tanggal, dan pembuat informasi (`createdBy` / `userEmail`).
  Future<List<InformationModel>> getCachedInformation({
    String? search,
    String? startDate,
    String? endDate,
    String? createdBy,
  });

  /// Menghapus data informasi yang lebih lama dari [threshold]
  /// (kebijakan rolling window).
  Future<void> deleteOlderThan(DateTime threshold);

  /// Menghapus data informasi tertentu dari cache lokal Isar berdasarkan [id].
  Future<bool> deleteInformation(String id);

  /// Menghapus batch data informasi dari cache lokal Isar berdasarkan [ids].
  ///
  /// Mengembalikan jumlah record yang berhasil dihapus dari cache.
  Future<int> deleteBatchInformation(List<String> ids);

  /// Mengosongkan cache informasi lokal (kebijakan logout / reset).
  @override
  Future<void> clearCache();
}

/// Implementasi konkret [InformationLocalDataSource] menggunakan database
/// [Isar].
class InformationLocalDataSourceImpl implements InformationLocalDataSource {
  /// Membuat instance [InformationLocalDataSourceImpl].
  InformationLocalDataSourceImpl({required this.isar});

  /// Instance database Isar.
  final Isar isar;

  @override
  Future<void> cacheInformation(List<InformationModel> items) async {
    final collections = InformationLocalMapper.toLocalList(items);
    await isar.writeTxn(() async {
      await isar.informationLocalModels.putAll(collections);
    });
  }

  @override
  Future<List<InformationModel>> getCachedInformation({
    String? search,
    String? startDate,
    String? endDate,
    String? createdBy,
  }) async {
    var query = isar.informationLocalModels.where().filter().idIsNotEmpty();

    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.and().userEmailEqualTo(createdBy, caseSensitive: false);
    }

    if (search != null && search.isNotEmpty) {
      final q = search;
      query = query.and().group(
            (qBuilder) => qBuilder
                .titleContains(q, caseSensitive: false)
                .or()
                .textContains(q, caseSensitive: false)
                .or()
                .userNameContains(q, caseSensitive: false)
                .or()
                .userEmailContains(q, caseSensitive: false)
                .or()
                .feedTypeContains(q, caseSensitive: false)
                .or()
                .eventLocationContains(q, caseSensitive: false),
          );
    }

    if (startDate != null) {
      final startSpace = startDate.replaceFirst('T', ' ');
      final startT = startDate.replaceFirst(' ', 'T');
      query = query.and().group(
            (q) => q
                .feedDtGreaterThan(startSpace, include: true)
                .or()
                .feedDtGreaterThan(startT, include: true),
          );
    }

    if (endDate != null) {
      final endSpace = endDate.replaceFirst('T', ' ');
      final endT = endDate.replaceFirst(' ', 'T');
      query = query.and().group(
            (q) => q
                .feedDtLessThan(endSpace, include: true)
                .or()
                .feedDtLessThan(endT, include: true),
          );
    }

    final collections = await query.sortByFeedDtDesc().findAll();
    return InformationLocalMapper.fromLocalList(collections);
  }

  @override
  Future<void> deleteOlderThan(DateTime threshold) async {
    final thresholdIso = threshold.toUtc().toIso8601String();
    await isar.writeTxn(() async {
      await isar.informationLocalModels
          .filter()
          .feedDtLessThan(thresholdIso)
          .deleteAll();
    });
  }

  @override
  Future<bool> deleteInformation(String id) async {
    return await isar.writeTxn(() async {
      return await isar.informationLocalModels.deleteById(id);
    });
  }

  @override
  Future<int> deleteBatchInformation(List<String> ids) async {
    return await isar.writeTxn(() async {
      return await isar.informationLocalModels.deleteAllById(ids);
    });
  }

  @override
  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.informationLocalModels.clear();
    });
  }
}
