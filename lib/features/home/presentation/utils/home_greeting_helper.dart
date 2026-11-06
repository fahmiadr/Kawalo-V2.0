/// Helper utilitas presentasi untuk menghasilkan teks salam (greeting)
/// pada header Beranda sesuai standar budaya Indonesia.
abstract final class HomeGreetingHelper {
  const HomeGreetingHelper._();

  /// Menghasilkan sapaan waktu sesuai konvensi budaya lokal Indonesia:
  /// - `05:00 – 10:59`: "Selamat pagi" (fajar hingga menjelang tengah hari)
  /// - `11:00 – 14:59`: "Selamat siang" (tengah hari)
  /// - `15:00 – 17:59`: "Selamat sore" (sore hingga sebelum magrib)
  /// - `18:00 – 04:59`: "Selamat malam" (magrib, malam, dan dini hari)
  static String getTimeOfDayGreeting([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      return 'Selamat pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore';
    } else {
      return 'Selamat malam';
    }
  }

  /// Memformat teks salam lengkap untuk header Beranda:
  /// Contoh: `"Selamat siang, admin AHMAD ZAKI FAUZAN!"`
  ///
  /// Jika data nama/role belum tersedia, menghasilkan fallback ramah:
  /// Contoh: `"Selamat siang, Personil!"`
  static String formatGreeting({
    String? name,
    String? role,
    DateTime? dateTime,
  }) {
    final timeGreeting = getTimeOfDayGreeting(dateTime);
    final cleanRole = role?.trim() ?? '';
    final cleanName = name?.trim().toUpperCase() ?? '';

    if (cleanRole.isNotEmpty && cleanName.isNotEmpty) {
      return '$timeGreeting, $cleanRole $cleanName!';
    } else if (cleanName.isNotEmpty) {
      return '$timeGreeting, $cleanName!';
    }

    return '$timeGreeting, Personil!';
  }
}
