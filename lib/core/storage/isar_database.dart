import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Layanan terpusat untuk mengelola inisialisasi dan koneksi database Isar.
abstract final class IsarDatabase {
  /// Nama instance default database Isar.
  static const String defaultName = 'kawalo_db';

  /// Menginisialisasi dan membuka instance database Isar dengan [schemas]
  /// milik fitur yang disuplai composition root.
  static Future<Isar> init({
    required List<CollectionSchema<dynamic>> schemas,
    String? directory,
  }) async {
    final existing = Isar.getInstance(defaultName);
    if (existing != null) {
      return existing;
    }
    final path = directory ?? (await getApplicationDocumentsDirectory()).path;
    return await Isar.open(schemas, directory: path, name: defaultName);
  }
}
