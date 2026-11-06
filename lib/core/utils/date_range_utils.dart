/// Utilitas untuk menghitung dan menyelesaikan rentang tanggal (date range)
/// berdasarkan periode penyaringan (filter period) aplikasi Kawalo.
class DateRangeUtils {
  const DateRangeUtils._();

  /// Menghitung batas rentang waktu [DateTime] (mulai dan akhir)
  /// dari sebuah enum periode waktu (seperti GuestFilterPeriod atau
  /// AppFilterPeriod).
  ///
  /// Menerima [Enum] umum yang memiliki opsi:
  /// - `today`: Tanggal hari ini mulai pukul 00:00:00 hingga 23:59:59
  /// - `thisWeek`: Awal pekan (Senin) pukul 00:00:00 hingga 23:59:59
  /// - `thisMonth`: Awal bulan pukul 00:00:00 hingga akhir bulan pukul 23:59:59
  /// - `custom`: Mengembalikan [customStart] dan [customEnd] yang dipilih user
  ///
  /// Parameter opsional [referenceNow] dapat diberikan untuk keperluan
  /// pengujian.
  static (DateTime?, DateTime?) resolve(
    Enum period, {
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();

    switch (period.name) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);

      case 'thisWeek':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final end = DateTime(
          endOfWeek.year,
          endOfWeek.month,
          endOfWeek.day,
          23,
          59,
          59,
        );
        return (start, end);

      case 'thisMonth':
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start, end);

      case 'custom':
      default:
        return (customStart, customEnd);
    }
  }
}
