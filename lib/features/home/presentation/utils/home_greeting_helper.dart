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

  /// Short Beranda header greeting: time word plus first name in title case,
  /// e.g. `"Pagi, Budi"` for "BUDI SANTOSO". Without a name: `"Selamat pagi"`.
  static String formatShort({String? name, DateTime? dateTime}) {
    final full = getTimeOfDayGreeting(dateTime);
    final first = name?.trim().split(RegExp(r'\s+')).first ?? '';
    if (first.isEmpty) return full;
    final word = full.substring('Selamat '.length);
    final time = word[0].toUpperCase() + word.substring(1);
    final who = first[0].toUpperCase() + first.substring(1).toLowerCase();
    return '$time, $who';
  }
}
