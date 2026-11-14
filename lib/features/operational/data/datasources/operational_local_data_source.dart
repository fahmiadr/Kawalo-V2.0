import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/operational/data/mappers/operational_local_mapper.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_local_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';

/// Kontrak sumber aktivitas operasional lokal untuk penyimpanan dan fallback
/// offline.
abstract class OperationalLocalDataSource implements CacheWipeable {
  /// Menyimpan daftar kartu pekerja operasional ke cache lokal.
  Future<void> cacheOperationals(List<OperationalModel> items);

  /// Mengambil data pekerja operasional dari cache lokal dengan filter
  /// pencarian dan rentang tanggal.
  Future<List<OperationalModel>> getCachedOperationals({
    String? search,
    String? startDate,
    String? endDate,
  });

  /// Menghapus data kartu operasional lokal yang lebih lama dari [threshold]
  /// (rolling window eviction 30 hari).
  Future<void> deleteOlderThan(DateTime threshold);

  /// Mengosongkan seluruh cache aktivitas operasional.
  @override
  Future<void> clearCache();
}

/// Implementasi konkret [OperationalLocalDataSource] menggunakan
/// database [Isar].
class OperationalLocalDataSourceImpl implements OperationalLocalDataSource {
  /// Membuat instance [OperationalLocalDataSourceImpl].
  OperationalLocalDataSourceImpl({required this.isar});

  /// Instance database Isar.
  final Isar isar;

  @override
  String get collectionName => OperationalLocalModelSchema.name;

  @override
  Future<void> cacheOperationals(List<OperationalModel> items) async {
    final collections = OperationalLocalMapper.toLocalList(items);
    await isar.writeTxn(() async {
      await isar.operationalLocalModels.putAll(collections);
    });
  }

  @override
  Future<List<OperationalModel>> getCachedOperationals({
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    var query = isar.operationalLocalModels.where().filter().idIsNotEmpty();

    if (search != null && search.isNotEmpty) {
      query = query.and().searchTokensContains(search, caseSensitive: false);
    }

    if (startDate != null) {
      final startStr = startDate.length >= 10
          ? startDate.substring(0, 10)
          : startDate;
      query = query.and().dutyDateGreaterThan(startStr, include: true);
    }

    if (endDate != null) {
      final endStr = endDate.length >= 10 ? endDate.substring(0, 10) : endDate;
      query = query.and().dutyDateLessThan(endStr, include: true);
    }

    final collections = await query.sortByDutyDateDesc().findAll();
    return OperationalLocalMapper.fromLocalList(collections);
  }

  @override
  Future<void> deleteOlderThan(DateTime threshold) async {
    final thresholdStr = threshold.toIso8601String().substring(0, 10);
    await isar.writeTxn(() async {
      await isar.operationalLocalModels
          .filter()
          .dutyDateLessThan(thresholdStr)
          .deleteAll();
    });
  }

  @override
  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.operationalLocalModels.clear();
    });
  }
}
