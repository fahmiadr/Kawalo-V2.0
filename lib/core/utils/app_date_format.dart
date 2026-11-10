/// Utility fungsi pemformatan tanggal dan waktu lokal aplikasi Kawalo.
class AppDateFormat {
  const AppDateFormat._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const Map<String, int> _monthMap = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'mei': 5,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'agu': 8,
    'aug': 8,
    'sep': 9,
    'okt': 10,
    'oct': 10,
    'nov': 11,
    'des': 12,
    'dec': 12,
  };

  /// Memeriksa apakah string bernilai null, kosong, atau penampung nilai
  /// kosong.
  static bool _isPlaceholder(String? str) {
    if (str == null) return true;
    final trimmed = str.trim();
    return trimmed.isEmpty || trimmed == '-' || trimmed == 'null';
  }

  /// Mencoba parsing string tanggal/waktu menjadi [DateTime].
  ///
  /// Mendukung format ISO-8601 ("2026-07-08T15:21:00.000Z"), teks
  /// Indonesia/Inggris ("08 Jul 2026 15:21"), epoch integer, maupun
  /// format jam ("15:21").
  static DateTime? tryParse(String? raw) {
    if (_isPlaceholder(raw)) return null;
    final trimmed = raw!.trim();

    final isoParsed = DateTime.tryParse(trimmed);
    if (isoParsed != null) {
      return isoParsed;
    }

    final customMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{1,2})[:.](\d{1,2})$',
    ).firstMatch(trimmed);
    if (customMatch != null) {
      final day = int.parse(customMatch.group(1)!);
      final monthStr = customMatch.group(2)!.toLowerCase();
      final year = int.parse(customMatch.group(3)!);
      final hour = int.parse(customMatch.group(4)!);
      final minute = int.parse(customMatch.group(5)!);
      final month = _monthMap[monthStr] ?? 1;
      return DateTime(year, month, day, hour, minute);
    }

    final dateSlashMatch = RegExp(
      r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})\s+(\d{1,2})[:.](\d{1,2})$',
    ).firstMatch(trimmed);
    if (dateSlashMatch != null) {
      final year = int.parse(dateSlashMatch.group(1)!);
      final month = int.parse(dateSlashMatch.group(2)!);
      final day = int.parse(dateSlashMatch.group(3)!);
      final hour = int.parse(dateSlashMatch.group(4)!);
      final minute = int.parse(dateSlashMatch.group(5)!);
      return DateTime(year, month, day, hour, minute);
    }

    final epoch = int.tryParse(trimmed);
    if (epoch != null && epoch > 1000000000) {
      if (epoch > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(epoch);
      }
      return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    }

    final todayMatch = RegExp(
      r'^(?:diperbarui\s+)?(?:hari\s+ini|today)[,\s]+(\d{1,2})[:.](\d{1,2})$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (todayMatch != null) {
      final now = DateTime.now();
      final hour = int.parse(todayMatch.group(1)!);
      final minute = int.parse(todayMatch.group(2)!);
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    final yesterdayMatch = RegExp(
      r'^(?:kemarin|yesterday)[,\s]+(\d{1,2})[:.](\d{1,2})$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (yesterdayMatch != null) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final hour = int.parse(yesterdayMatch.group(1)!);
      final minute = int.parse(yesterdayMatch.group(2)!);
      return DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        hour,
        minute,
      );
    }

    final timeMatch = RegExp(r'^(\d{1,2})[:.](\d{1,2})$').firstMatch(trimmed);
    if (timeMatch != null) {
      final now = DateTime.now();
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    return null;
  }

  /// Format objek [DateTime] menjadi tanggal standar: "08 Jul 2026 15:21".
  static String formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $year $hour:$minute';
  }

  /// Format objek [DateTime] menjadi tanggal saja: "08 Jul 2026".
  static String formatDateOnly(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _months[dateTime.month - 1];
    final year = dateTime.year;
    return '$day $month $year';
  }

  /// Format objek [DateTime] menjadi tanggal dan bulan saja: "8 Jul".
  static String formatDayMonth(DateTime dateTime) =>
      '${dateTime.day} ${_months[dateTime.month - 1]}';

  /// Format objek [DateTime] dengan nama hari: "Rabu, 8 Jul 2026".
  static String formatWeekdayDate(DateTime dateTime) =>
      '${_weekdays[dateTime.weekday - 1]}, '
      '${dateTime.day} ${_months[dateTime.month - 1]} ${dateTime.year}';

  /// Format rentang dua objek [DateTime] secara ringkas dan manusiawi
  /// mengikuti kaidah Material Design 3 Expressive, UX Writing, dan PUEBI:
  ///
  /// - Hari yang sama: "13 Sep 2026"
  /// - Bulan & tahun sama: "13–14 Sep 2026"
  /// - Tahun sama, beda bulan: "13 Sep – 14 Okt 2026"
  /// - Beda tahun: "13 Sep 2026 – 14 Sep 2027"
  ///
  /// Menggunakan tanda pisah en dash (`–`) dengan penataan spasi yang tepat
  /// untuk meningkatkan scannability dan menghindari pengulangan teks.
  static String formatDateRange(
    DateTime start,
    DateTime end, {
    bool useLeadingZero = false,
  }) {
    final s = start.isBefore(end) ? start : end;
    final e = start.isBefore(end) ? end : start;

    final sDay = useLeadingZero ? s.day.toString().padLeft(2, '0') : '${s.day}';
    final eDay = useLeadingZero ? e.day.toString().padLeft(2, '0') : '${e.day}';
    final sMonth = _months[s.month - 1];
    final eMonth = _months[e.month - 1];
    final sYear = s.year;
    final eYear = e.year;

    // 1. Hari, bulan, dan tahun sama persis (single day)
    if (sYear == eYear && s.month == e.month && s.day == e.day) {
      return '$sDay $sMonth $sYear';
    }

    // 2. Bulan dan tahun sama (rentang tanggal dalam 1 bulan)
    if (sYear == eYear && s.month == e.month) {
      return '$sDay–$eDay $sMonth $sYear';
    }

    // 3. Tahun sama, bulan berbeda
    if (sYear == eYear) {
      return '$sDay $sMonth – $eDay $eMonth $sYear';
    }

    // 4. Tahun berbeda
    return '$sDay $sMonth $sYear – $eDay $eMonth $eYear';
  }

  /// Format objek [DateTime] menjadi greeting sinkronisasi dengan perbandingan
  /// relatif terhadap [now] (default: `DateTime.now()`):
  /// - Hari ini: "Diperbarui Hari ini, 15.20"
  /// - Kemarin: "Diperbarui Kemarin, 15.20"
  /// - Tahun yang sama: "Diperbarui 08 Jul, 15.20"
  /// - Tahun berbeda: "Diperbarui 08 Jul 2025, 15.20"
  static String formatGreeting(DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    // 1. Hari ini
    if (dateTime.year == reference.year &&
        dateTime.month == reference.month &&
        dateTime.day == reference.day) {
      return 'Diperbarui Hari ini, $hour.$minute';
    }

    // 2. Kemarin
    final yesterday = reference.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'Diperbarui Kemarin, $hour.$minute';
    }

    // 3. Tanggal lampau
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _months[dateTime.month - 1];
    if (dateTime.year == reference.year) {
      return 'Diperbarui $day $month, $hour.$minute';
    }

    return 'Diperbarui $day $month ${dateTime.year}, $hour.$minute';
  }

  /// Format string tanggal/waktu mentah menjadi tanggal standar:
  /// "08 Jul 2026 15:21".
  ///
  /// Mengembalikan "-" jika nilai kosong, null, atau "-".
  static String formatRawDate(String? raw) {
    if (_isPlaceholder(raw)) return '-';
    final parsed = tryParse(raw);
    if (parsed != null) {
      return formatDate(parsed.toLocal());
    }
    return raw!.trim();
  }

  /// Format string tanggal/waktu mentah menjadi teks greeting:
  /// "Diperbarui Hari ini, 15.20" atau "Diperbarui Kemarin, 15.20".
  ///
  /// Mengembalikan "-" jika nilai kosong, null, atau "-".
  /// Mengembalikan string aslinya jika sudah diawali "Diperbarui".
  static String formatRawGreeting(String? raw, {DateTime? now}) {
    if (_isPlaceholder(raw)) return '-';
    final trimmed = raw!.trim();
    if (trimmed.startsWith('Diperbarui')) {
      return trimmed;
    }
    final parsed = tryParse(trimmed);
    if (parsed != null) {
      return formatGreeting(parsed.toLocal(), now: now);
    }
    return trimmed;
  }
}
