import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/widgets/date_filter/app_date_filter_models.dart';

/// Hasil seleksi dan sanitasi dari `AppDateFilterBottomSheet`.
class AppDateFilterResult extends Equatable {
  /// Membuat instance [AppDateFilterResult].
  const AppDateFilterResult({
    required this.period,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.customFilters = const {},
  });

  /// Sanitasi rentang waktu, clamping scope, dan konversi ke format
  /// ISO 8601 string pada level form/modal filter.
  factory AppDateFilterResult.sanitize({
    required AppDateFilterPeriod period,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    Map<String, dynamic> customFilters = const {},
    AppDateFilterScope scope = AppDateFilterScope.generic,
    DateTime? referenceNow,
  }) {
    if (startDateIso != null && endDateIso != null) {
      return AppDateFilterResult(
        period: period,
        startDate: startDate,
        endDate: endDate,
        startDateIso: startDateIso,
        endDateIso: endDateIso,
        customFilters: customFilters,
      );
    }

    final now = referenceNow ?? DateTime.now();

    switch (period) {
      case AppDateFilterPeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return AppDateFilterResult(
          period: period,
          startDateIso: start.toIso8601String(),
          endDateIso: end.toIso8601String(),
          customFilters: customFilters,
        );

      case AppDateFilterPeriod.thisWeek:
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
        return AppDateFilterResult(
          period: period,
          startDateIso: start.toIso8601String(),
          endDateIso: end.toIso8601String(),
          customFilters: customFilters,
        );

      case AppDateFilterPeriod.thisMonth:
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return AppDateFilterResult(
          period: period,
          startDateIso: start.toIso8601String(),
          endDateIso: end.toIso8601String(),
          customFilters: customFilters,
        );

      case AppDateFilterPeriod.custom:
        var s = startDate ?? now;
        var e = endDate ?? now;

        if (s.isAfter(e)) {
          final temp = s;
          s = e;
          e = temp;
        }

        var normalizedStart = DateTime(s.year, s.month, s.day);
        var normalizedEnd = DateTime(e.year, e.month, e.day, 23, 59, 59);

        if (scope == AppDateFilterScope.pastOnly) {
          final maxEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          if (normalizedEnd.isAfter(maxEnd)) {
            normalizedEnd = maxEnd;
          }
          if (normalizedStart.isAfter(normalizedEnd)) {
            normalizedStart = DateTime(now.year, now.month, now.day);
          }
        } else if (scope == AppDateFilterScope.futureOnly) {
          final minStart = DateTime(now.year, now.month, now.day);
          if (normalizedStart.isBefore(minStart)) {
            normalizedStart = minStart;
          }
          if (normalizedEnd.isBefore(normalizedStart)) {
            normalizedEnd = DateTime(
              normalizedStart.year,
              normalizedStart.month,
              normalizedStart.day,
              23,
              59,
              59,
            );
          }
        }

        return AppDateFilterResult(
          period: period,
          startDate: normalizedStart,
          endDate: normalizedEnd,
          startDateIso: normalizedStart.toIso8601String(),
          endDateIso: normalizedEnd.toIso8601String(),
          customFilters: customFilters,
        );
    }
  }

  /// Hasil default (Hari ini) yang telah disanitasi dan dikonversi.
  factory AppDateFilterResult.defaultFilter({
    DateTime? referenceNow,
    Map<String, dynamic> customFilters = const {},
  }) {
    return AppDateFilterResult.sanitize(
      period: AppDateFilterPeriod.today,
      customFilters: customFilters,
      referenceNow: referenceNow,
    );
  }

  /// Mengonversi hasil umum [AppDateFilterResult] dengan menyaring ulang
  /// tanggal.
  factory AppDateFilterResult.fromAppDateFilterResult(
    AppDateFilterResult raw, {
    AppDateFilterScope scope = AppDateFilterScope.generic,
    DateTime? referenceNow,
  }) {
    return AppDateFilterResult.sanitize(
      period: raw.period,
      startDate: raw.startDate,
      endDate: raw.endDate,
      startDateIso: raw.startDateIso,
      endDateIso: raw.endDateIso,
      customFilters: raw.customFilters,
      scope: scope,
      referenceNow: referenceNow,
    );
  }

  /// Periode yang dipilih pengguna.
  final AppDateFilterPeriod period;

  /// Tanggal awal rentang kustom (jika [period] adalah
  /// [AppDateFilterPeriod.custom]).
  final DateTime? startDate;

  /// Tanggal akhir rentang kustom (jika [period] adalah
  /// [AppDateFilterPeriod.custom]).
  final DateTime? endDate;

  /// Representasi ISO 8601 string dari tanggal awal yang telah disanitasi.
  final String? startDateIso;

  /// Representasi ISO 8601 string dari tanggal akhir yang telah disanitasi.
  final String? endDateIso;

  /// Kriteria filter tambahan (general atau spesifik fitur).
  final Map<String, dynamic> customFilters;

  /// Menandakan apakah filter berada pada kondisi default ('Hari ini').
  bool get isDefault =>
      period == AppDateFilterPeriod.today &&
      startDate == null &&
      endDate == null &&
      customFilters.isEmpty;

  /// Apakah filter rentang tanggal aktif selain default hari ini.
  bool get hasActiveDateFilter =>
      period != AppDateFilterPeriod.today ||
      startDate != null ||
      endDate != null;

  /// Apakah terdapat kriteria filter kustom tambahan yang aktif.
  bool get hasActiveCustomFilters => customFilters.isNotEmpty;

  /// Apakah terdapat filter tanggal atau filter kustom yang sedang aktif.
  bool get hasActiveFilter => hasActiveDateFilter || hasActiveCustomFilters;

  /// Membuat salinan [AppDateFilterResult] dengan nilai baru.
  AppDateFilterResult copyWith({
    AppDateFilterPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    Map<String, dynamic>? customFilters,
  }) {
    return AppDateFilterResult(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startDateIso: startDateIso ?? this.startDateIso,
      endDateIso: endDateIso ?? this.endDateIso,
      customFilters: customFilters ?? this.customFilters,
    );
  }

  @override
  List<Object?> get props => [
    period,
    startDate,
    endDate,
    startDateIso,
    endDateIso,
    customFilters,
  ];
}
