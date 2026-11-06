import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_local_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_local_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_local_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_local_model.dart';
import 'package:path_provider/path_provider.dart';

/// Layanan terpusat untuk mengelola inisialisasi dan koneksi database Isar.
abstract final class IsarDatabase {
  /// Nama instance default database Isar.
  static const String defaultName = 'kawalo_db';

  /// Menginisialisasi dan membuka instance database Isar dengan seluruh skema
  /// fitur terdaftar.
  static Future<Isar> init({String? directory}) async {
    final existing = Isar.getInstance(defaultName);
    if (existing != null) {
      return existing;
    }
    final path = directory ?? (await getApplicationDocumentsDirectory()).path;
    return await Isar.open(
      [
        AttendanceLocalModelSchema,
        OperationalLocalModelSchema,
        InformationLocalModelSchema,
        GuestLocalModelSchema,
      ],
      directory: path,
      name: defaultName,
    );
  }
}
