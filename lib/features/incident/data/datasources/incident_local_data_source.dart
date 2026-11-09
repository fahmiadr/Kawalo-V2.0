import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_local_mapper.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_local_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';

/// Kontrak sumber data insiden lokal untuk cache daftar, fallback offline,
/// dan kebijakan cache eviction.
abstract class IncidentLocalDataSource implements CacheWipeable {
  /// Menyimpan daftar insiden ke cache lokal.
  Future<void> cacheIncidents(List<IncidentModel> items);

  /// Mengambil daftar insiden dari cache lokal dengan filter grup, status,
  /// pencarian, dan rentang tanggal.
  Future<List<IncidentModel>> getCachedIncidents({
    String? groupId,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
  });

  /// Menghapus insiden yang dibuat sebelum [threshold] (rolling window).
  Future<void> deleteOlderThan(DateTime threshold);

  /// Mengosongkan seluruh cache insiden lokal (kebijakan logout / reset).
  @override
  Future<void> clearCache();
}

/// Implementasi konkret [IncidentLocalDataSource] menggunakan database [Isar].
class IncidentLocalDataSourceImpl implements IncidentLocalDataSource {
  /// Membuat instance [IncidentLocalDataSourceImpl].
  IncidentLocalDataSourceImpl({required this.isar});

  /// Instance database Isar.
  final Isar isar;

  @override
  String get collectionName => IncidentLocalModelSchema.name;

  @override
  Future<void> cacheIncidents(List<IncidentModel> items) async {
    final collections = IncidentLocalMapper.toLocalList(items);
    await isar.writeTxn(() async {
      await isar.incidentLocalModels.putAll(collections);
    });
  }

  @override
  Future<List<IncidentModel>> getCachedIncidents({
    String? groupId,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    var query = isar.incidentLocalModels.where().filter().idIsNotEmpty();

    if (groupId != null && groupId.isNotEmpty) {
      query = query.and().groupIdEqualTo(groupId);
    }

    if (status != null && status.isNotEmpty) {
      query = query.and().statusEqualTo(status);
    }

    if (search != null && search.isNotEmpty) {
      query = query.and().group(
        (q) => q
            .titleContains(search, caseSensitive: false)
            .or()
            .descriptionContains(search, caseSensitive: false),
      );
    }

    if (startDate != null && startDate.isNotEmpty) {
      query = query.and().createdAtGreaterThan(
        IncidentLocalMapper.toUtcIso(startDate),
        include: true,
      );
    }

    if (endDate != null && endDate.isNotEmpty) {
      query = query.and().createdAtLessThan(
        IncidentLocalMapper.toUtcIso(endDate),
        include: true,
      );
    }

    final collections = await query.sortByCreatedAtDesc().findAll();
    return IncidentLocalMapper.fromLocalList(collections);
  }

  @override
  Future<void> deleteOlderThan(DateTime threshold) async {
    final thresholdIso = threshold.toUtc().toIso8601String();
    await isar.writeTxn(() async {
      await isar.incidentLocalModels
          .filter()
          .createdAtLessThan(thresholdIso)
          .deleteAll();
    });
  }

  @override
  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.incidentLocalModels.clear();
    });
  }
}
