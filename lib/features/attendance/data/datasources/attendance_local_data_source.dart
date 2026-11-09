import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/attendance/data/mappers/attendance_local_mapper.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_local_model.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';

/// Kontrak sumber data absensi lokal untuk penyimpanan, fallback offline,
/// dan kebijakan cache eviction.
abstract class AttendanceLocalDataSource implements CacheWipeable {
  /// Menyimpan daftar absensi ke cache lokal.
  Future<void> cacheAttendances(List<AttendanceModel> items);

  /// Mengambil data absensi dari cache lokal dengan filter pencarian dan
  /// rentang tanggal.
  Future<List<AttendanceModel>> getCachedAttendances({
    String? search,
    String? startDate,
    String? endDate,
  });

  /// Menghapus data absensi yang lebih lama dari [threshold]
  /// (kebijakan rolling window).
  Future<void> deleteOlderThan(DateTime threshold);

  /// Mengosongkan seluruh cache absensi lokal (kebijakan logout / reset).
  @override
  Future<void> clearCache();
}

/// Implementasi konkret [AttendanceLocalDataSource] menggunakan
/// database [Isar].
class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  /// Membuat instance [AttendanceLocalDataSourceImpl].
  AttendanceLocalDataSourceImpl({required this.isar});

  /// Instance database Isar.
  final Isar isar;

  @override
  Future<void> cacheAttendances(List<AttendanceModel> items) async {
    final collections = AttendanceLocalMapper.toLocalList(items);
    await isar.writeTxn(() async {
      await isar.attendanceLocalModels.putAll(collections);
    });
  }

  @override
  Future<List<AttendanceModel>> getCachedAttendances({
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    var query = isar.attendanceLocalModels.where().filter().idIsNotEmpty();

    if (search != null && search.isNotEmpty) {
      final q = search;
      query = query.and().group(
        (qBuilder) => qBuilder
            .userNameContains(q, caseSensitive: false)
            .or()
            .userEmailContains(q, caseSensitive: false)
            .or()
            .attendanceTypeContains(q, caseSensitive: false)
            .or()
            .locationNameContains(q, caseSensitive: false)
            .or()
            .shiftNameContains(q, caseSensitive: false),
      );
    }

    if (startDate != null) {
      final startSpace = startDate.replaceFirst('T', ' ');
      final startT = startDate.replaceFirst(' ', 'T');
      query = query.and().group(
        (q) => q
            .attendanceDtGreaterThan(startSpace, include: true)
            .or()
            .attendanceDtGreaterThan(startT, include: true),
      );
    }

    if (endDate != null) {
      final endSpace = endDate.replaceFirst('T', ' ');
      final endT = endDate.replaceFirst(' ', 'T');
      query = query.and().group(
        (q) => q
            .attendanceDtLessThan(endSpace, include: true)
            .or()
            .attendanceDtLessThan(endT, include: true),
      );
    }

    final collections = await query.sortByAttendanceDtDesc().findAll();
    return AttendanceLocalMapper.fromLocalList(collections);
  }

  @override
  Future<void> deleteOlderThan(DateTime threshold) async {
    final thresholdIso = threshold.toUtc().toIso8601String();
    await isar.writeTxn(() async {
      await isar.attendanceLocalModels
          .filter()
          .attendanceDtLessThan(thresholdIso)
          .deleteAll();
    });
  }

  @override
  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.attendanceLocalModels.clear();
    });
  }
}
