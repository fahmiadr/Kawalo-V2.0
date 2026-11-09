import 'package:kawalo_mobile/core/utils/app_date_format.dart';

/// Pilihan periode waktu penyaringan tanggal pada aplikasi.
enum AppDateFilterPeriod {
  /// Hanya data hari ini (opsi default).
  today('Hari ini'),

  /// Data dalam 7 hari terakhir / pekan ini.
  thisWeek('Pekan ini'),

  /// Data dalam bulan berjalan ini.
  thisMonth('Bulan ini'),

  /// Rentang tanggal kustom yang dipilih melalui kalender.
  custom('Rentang khusus');

  const AppDateFilterPeriod(this.label);

  /// Label teks opsi periode.
  final String label;
}

/// Ekstensi penyajian label teks tampilan untuk periode filter tanggal.
extension AppDateFilterPeriodDisplayX on AppDateFilterPeriod {
  /// Menghasilkan label teks untuk tampilan chip filter berdasarkan periode
  /// dan rentang tanggal kustom (jika ada).
  String resolveDisplayLabel({DateTime? startDate, DateTime? endDate}) {
    if (this == AppDateFilterPeriod.custom &&
        startDate != null &&
        endDate != null) {
      return AppDateFormat.formatDateRange(
        startDate,
        endDate,
        useLeadingZero: true,
      );
    }
    return label;
  }
}

/// Menentukan cakupan batas rentang tanggal pada pemilih kalender.
enum AppDateFilterScope {
  /// Penyaring umum: rentang dinamis 100 tahun ke belakang hingga 100 tahun
  /// mendatang dari tahun berjalan (`now.year - 100` s/d `now.year + 100`).
  generic,

  /// Khusus data masa lalu: dari 100 tahun ke belakang hingga hari ini
  /// (`now.year - 100` s/d `now`). Cocok untuk log absensi, tamu, dan kejadian.
  pastOnly,

  /// Khusus data masa depan: dari hari ini hingga 100 tahun mendatang
  /// (`now` s/d `now.year + 100`). Cocok untuk jadwal shift, reservasi, dan event.
  futureOnly;

  /// Menghitung tanggal awal efektif berdasarkan cakupan dan waktu acuan.
  DateTime resolveFirstDate(DateTime now, {DateTime? customFirstDate}) {
    if (customFirstDate != null) return customFirstDate;
    switch (this) {
      case AppDateFilterScope.generic:
      case AppDateFilterScope.pastOnly:
        return DateTime(now.year - 100);
      case AppDateFilterScope.futureOnly:
        return DateTime(now.year, now.month, now.day);
    }
  }

  /// Menghitung tanggal akhir efektif berdasarkan cakupan dan waktu acuan.
  DateTime resolveLastDate(DateTime now, {DateTime? customLastDate}) {
    if (customLastDate != null) return customLastDate;
    switch (this) {
      case AppDateFilterScope.generic:
      case AppDateFilterScope.futureOnly:
        return DateTime(now.year + 100, 12, 31);
      case AppDateFilterScope.pastOnly:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }
}
