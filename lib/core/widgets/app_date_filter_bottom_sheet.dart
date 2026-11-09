import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_date_picker.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_radio.dart';
import 'package:kawalo_mobile/core/widgets/app_selection_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

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

/// Hasil seleksi dan sanitasi dari [AppDateFilterBottomSheet].
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

/// Tampilan dalam [AppDateFilterBottomSheet] untuk transisi tanpa
/// tumpukan sheet.
enum _DateFilterSheetView {
  /// Tampilan opsi filter utama (Hari ini, Pekan ini, dsb).
  options,

  /// Tampilan atur rentang waktu kustom (Dari, Ke, Pasang).
  customRange,
}

/// Bottom sheet penyaringan data berdasarkan rentang waktu/tanggal.
class AppDateFilterBottomSheet extends StatefulWidget {
  /// Membuat instance [AppDateFilterBottomSheet].
  const AppDateFilterBottomSheet({
    super.key,
    this.title = 'Filter data',
    this.subtitle,
    this.initialPeriod = AppDateFilterPeriod.today,
    this.initialStartDate,
    this.initialEndDate,
    this.startInCustomRange = false,
    this.scope = AppDateFilterScope.generic,
    this.firstDate,
    this.lastDate,
    this.enableDateRange = true,
    this.dateRangeTitle = 'Rentang waktu',
    this.additionalSections = const [],
    this.initialCustomFilters = const {},
    this.onReset,
  });

  /// Judul header pada baris teks link (misal: 'Tanggal').
  final String title;

  /// Subtitle atau judul seksi rentang waktu (opsional).
  ///
  /// Mengambil prioritas lebih tinggi dibanding [dateRangeTitle] jika
  /// disediakan.
  final String? subtitle;

  /// Periode awal saat bottom sheet dibuka.
  final AppDateFilterPeriod initialPeriod;

  /// Tanggal awal rentang kustom awal.
  final DateTime? initialStartDate;

  /// Tanggal akhir rentang kustom awal.
  final DateTime? initialEndDate;

  /// Menentukan apakah sheet langsung terbuka di tampilan rentang kustom.
  final bool startInCustomRange;

  /// Cakupan rentang tanggal (generic, pastOnly, futureOnly).
  final AppDateFilterScope scope;

  /// Batas tanggal minimum eksplisit (menimpa default [scope] jika disetel).
  final DateTime? firstDate;

  /// Batas tanggal maksimum eksplisit (menimpa default [scope] jika disetel).
  final DateTime? lastDate;

  /// Menentukan apakah seksi penyaringan rentang waktu diaktifkan.
  final bool enableDateRange;

  /// Judul seksi rentang waktu (default: 'Rentang waktu').
  final String dateRangeTitle;

  /// Daftar widget seksi filter tambahan (misal: filter status, kategori).
  final List<Widget> additionalSections;

  /// Kriteria filter tambahan awal.
  final Map<String, dynamic> initialCustomFilters;

  /// Callback ketika pengguna menekan tombol Reset.
  final VoidCallback? onReset;

  @override
  State<AppDateFilterBottomSheet> createState() =>
      _AppDateFilterBottomSheetState();
}

class _AppDateFilterBottomSheetState extends State<AppDateFilterBottomSheet> {
  late AppDateFilterPeriod _selectedPeriod;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _draftStartDate;
  DateTime? _draftEndDate;
  late _DateFilterSheetView _currentView;
  String? _errorMessage;
  late Map<String, dynamic> _customFilters;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPeriod = widget.initialPeriod;
    _startDate = widget.initialStartDate ?? now;
    _endDate =
        widget.initialEndDate ??
        (widget.scope == AppDateFilterScope.pastOnly
            ? now
            : now.add(const Duration(days: 2)));
    _currentView = widget.startInCustomRange
        ? _DateFilterSheetView.customRange
        : _DateFilterSheetView.options;
    _customFilters = Map<String, dynamic>.from(widget.initialCustomFilters);
    if (_currentView == _DateFilterSheetView.customRange) {
      _draftStartDate = _startDate;
      _draftEndDate = _endDate;
    }
  }

  void _reset() {
    setState(() {
      _selectedPeriod = AppDateFilterPeriod.today;
      final now = DateTime.now();
      _startDate = widget.initialStartDate ?? now;
      _endDate =
          widget.initialEndDate ??
          (widget.scope == AppDateFilterScope.pastOnly
              ? now
              : now.add(const Duration(days: 2)));
      if (_currentView == _DateFilterSheetView.customRange) {
        // Tetap di tampilan custom tapi kembalikan draf ke nilai awal.
        _draftStartDate = _startDate;
        _draftEndDate = _endDate;
      } else {
        _draftStartDate = null;
        _draftEndDate = null;
      }
      _errorMessage = null;
      _customFilters = Map<String, dynamic>.from(widget.initialCustomFilters);
    });
    widget.onReset?.call();
  }

  void _switchToCustomRange() {
    setState(() {
      final now = DateTime.now();
      // Inisialisasi draf dari nilai terpasang, bukan menimpa nilai terpasang.
      // Periode baru terpasang setelah tombol Pasang ditekan.
      _draftStartDate = _startDate ?? widget.initialStartDate ?? now;
      _draftEndDate =
          _endDate ??
          widget.initialEndDate ??
          (widget.scope == AppDateFilterScope.pastOnly
              ? now
              : now.add(const Duration(days: 2)));
      _errorMessage = null;
      _validateDraftRange();
      _currentView = _DateFilterSheetView.customRange;
    });
  }

  void _switchToOptions() {
    setState(() {
      // Buang draf jika pengguna kembali tanpa menekan Pasang.
      _draftStartDate = null;
      _draftEndDate = null;
      _errorMessage = null;
      _currentView = _DateFilterSheetView.options;
    });
  }

  DateTime get _effectiveFirstDate => widget.scope.resolveFirstDate(
    DateTime.now(),
    customFirstDate: widget.firstDate,
  );

  DateTime get _effectiveLastDate => widget.scope.resolveLastDate(
    DateTime.now(),
    customLastDate: widget.lastDate,
  );

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final minDate = _effectiveFirstDate;
    final maxDate = _effectiveLastDate;
    final DateTime initialDate;
    if (_draftStartDate != null &&
        !_draftStartDate!.isBefore(minDate) &&
        !_draftStartDate!.isAfter(maxDate)) {
      initialDate = _draftStartDate!;
    } else if (now.isAfter(maxDate)) {
      initialDate = maxDate;
    } else if (now.isBefore(minDate)) {
      initialDate = minDate;
    } else {
      initialDate = now;
    }

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        _draftStartDate = picked;
        _validateDraftRange();
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final minDate = _effectiveFirstDate;
    final maxDate = _effectiveLastDate;
    final DateTime initialDate;
    if (_draftEndDate != null &&
        !_draftEndDate!.isBefore(minDate) &&
        !_draftEndDate!.isAfter(maxDate)) {
      initialDate = _draftEndDate!;
    } else if (now.isAfter(maxDate)) {
      initialDate = maxDate;
    } else if (now.isBefore(minDate)) {
      initialDate = minDate;
    } else {
      initialDate = now;
    }

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        _draftEndDate = picked;
        _validateDraftRange();
      });
    }
  }

  void _validateDraftRange() {
    if (_draftStartDate != null && _draftEndDate != null) {
      if (_draftStartDate!.isAfter(_draftEndDate!)) {
        _errorMessage = 'Tanggal awal tidak boleh melebihi tanggal akhir';
      } else {
        _errorMessage = null;
      }
    } else {
      _errorMessage = null;
    }
  }

  bool get _canConfirmRange =>
      _draftStartDate != null &&
      _draftEndDate != null &&
      !_draftStartDate!.isAfter(_draftEndDate!);

  void _applyCustomRange() {
    if (!_canConfirmRange) return;
    if (widget.startInCustomRange) {
      final result = AppDateFilterResult.sanitize(
        period: AppDateFilterPeriod.custom,
        startDate: _draftStartDate,
        endDate: _draftEndDate,
        customFilters: _customFilters,
        scope: widget.scope,
      );
      Navigator.of(context).pop(result);
    } else {
      // Pasang: baru pasang nilai rentang khusus ke state terpilih.
      setState(() {
        _selectedPeriod = AppDateFilterPeriod.custom;
        _startDate = _draftStartDate;
        _endDate = _draftEndDate;
        _draftStartDate = null;
        _draftEndDate = null;
        _errorMessage = null;
        _currentView = _DateFilterSheetView.options;
      });
    }
  }

  void _applyFilter() {
    final result = AppDateFilterResult.sanitize(
      period: _selectedPeriod,
      startDate: _startDate,
      endDate: _endDate,
      customFilters: _customFilters,
      scope: widget.scope,
    );
    Navigator.of(context).pop(result);
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return AppDateFormat.formatDateRange(start, end, useLeadingZero: true);
  }

  String? _resolvePeriodDateRange(AppDateFilterPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case AppDateFilterPeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        return _formatDateRange(start, start);
      case AppDateFilterPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        return _formatDateRange(start, end);
      case AppDateFilterPeriod.thisMonth:
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1, 0);
        return _formatDateRange(start, end);
      case AppDateFilterPeriod.custom:
        if (_startDate != null && _endDate != null) {
          return _formatDateRange(_startDate!, _endDate!);
        }
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReducedMotion = AppMotion.isReducedMotion(context);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.space100,
            bottom: AppSpacing.space300,
          ),
          child: ClipRect(
            child: AnimatedSize(
              duration: isReducedMotion ? Duration.zero : AppMotion.long2,
              curve: AppMotion.emphasized,
              alignment: Alignment.topCenter,
              child: _currentView == _DateFilterSheetView.options
                  ? _buildOptionsView(context)
                  : _buildCustomRangeView(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsView(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final isDefault =
        _selectedPeriod == AppDateFilterPeriod.today && _customFilters.isEmpty;

    return AppFilterBottomSheet(
      key: const ValueKey('filter_options_view'),
      isRoot: false,
      title: widget.title,
      subtitle: widget.enableDateRange
          ? (widget.subtitle ?? widget.dateRangeTitle)
          : null,
      isResetEnabled: !isDefault,
      onReset: _reset,
      resetSemanticLabel: isDefault
          ? 'Filter dalam kondisi default'
          : 'Kembalikan filter ke Hari ini',
      applySemanticLabel: 'Terapkan filter tanggal',
      onApply: _applyFilter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.enableDateRange) ...[
            ...AppDateFilterPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              final isCustom = period == AppDateFilterPeriod.custom;
              final dateRangeText = isSelected
                  ? _resolvePeriodDateRange(period)
                  : null;
              final periodSemanticLabel = dateRangeText != null
                  ? 'Pilih ${period.label}, $dateRangeText'
                  : 'Pilih ${period.label}';

              return AppSelectionTile(
                title: period.label,
                subtitleWidget: dateRangeText != null
                    ? Text(
                        dateRangeText,
                        style: typeScale.bodyMedium.copyWith(
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
                selected: isSelected,
                semanticLabel: periodSemanticLabel,
                trailing: AppRadio<AppDateFilterPeriod>(
                  value: period,
                  groupValue: _selectedPeriod,
                  onChanged: (val) {
                    if (val == AppDateFilterPeriod.custom) {
                      _switchToCustomRange();
                    } else {
                      setState(() {
                        _selectedPeriod = val;
                        _startDate = null;
                        _endDate = null;
                      });
                    }
                  },
                ),
                onTap: () {
                  if (isCustom) {
                    _switchToCustomRange();
                  } else {
                    setState(() {
                      _selectedPeriod = period;
                      _startDate = null;
                      _endDate = null;
                    });
                  }
                },
              );
            }),
          ],
          if (widget.additionalSections.isNotEmpty) ...[
            if (widget.enableDateRange)
              const Padding(
                padding: AppSpacing.paddingVertical150,
                child: AppDivider(),
              ),
            for (var i = 0; i < widget.additionalSections.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: AppSpacing.paddingVertical150,
                  child: AppDivider(),
                ),
              widget.additionalSections[i],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCustomRangeView(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasized = theme.typography.emphasized;

    return SingleChildScrollView(
      key: const ValueKey('filter_custom_range_view'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Tombol Kembali + Judul ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space150,
            ),
            child: Row(
              children: [
                AppIconButton(
                  icon: const AppSvgIcon(KawaloVectors.arrowLeft02, size: 28),
                  onPressed: _switchToOptions,
                  semanticLabel: 'Kembali ke opsi rentang waktu',
                ),
                Expanded(
                  child: Text(
                    'Atur rentang waktu',
                    style: emphasized.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.vGapSm,

          // ── Content: 24dp horizontal padding ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dua Kartu Input Tanggal ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildDateCard(
                        label: 'Dari',
                        date: _draftStartDate,
                        onTap: _pickStartDate,
                        colorScheme: colorScheme,
                        typeScale: typeScale,
                        emphasized: emphasized,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: _buildDateCard(
                        label: 'Ke',
                        date: _draftEndDate,
                        onTap: _pickEndDate,
                        colorScheme: colorScheme,
                        typeScale: typeScale,
                        emphasized: emphasized,
                      ),
                    ),
                  ],
                ),

                if (_errorMessage != null) ...[
                  AppSpacing.vGap50,
                  Text(
                    _errorMessage!,
                    style: typeScale.labelSmall.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],

                AppSpacing.vGap300,

                // ── Tombol Pasang ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    shape: AppButtonShape.square,
                    size: AppButtonSize.md,
                    enabled: _canConfirmRange,
                    onPressed: _canConfirmRange ? _applyCustomRange : null,
                    semanticLabel: 'Pasang rentang waktu',
                    child: Text('Pasang', style: typeScale.titleMedium),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required M3EColorScheme colorScheme,
    required M3ETypeScale typeScale,
    required M3ETypeScale emphasized,
  }) {
    final hasValue = date != null;
    final displayText = hasValue
        ? AppDateFormat.formatDateOnly(date)
        : 'Pilih tanggal';

    return AppCard(
      variant: AppCardVariant.filled,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      semanticLabel: '$label: $displayText',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: typeScale.bodyLarge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  displayText,
                  style: typeScale.bodyLarge.copyWith(
                    color: hasValue
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSvgIcon(
            KawaloVectors.calendar05,
            size: 24,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Menampilkan bottom sheet filter tanggal rentang waktu dan kriteria kustom.
Future<AppDateFilterResult?> showAppDateFilterBottomSheet({
  required BuildContext context,
  String title = 'Filter data',
  String? subtitle,
  AppDateFilterPeriod currentPeriod = AppDateFilterPeriod.today,
  DateTime? currentStartDate,
  DateTime? currentEndDate,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  bool startInCustomRange = false,
  AppDateFilterScope scope = AppDateFilterScope.generic,
  DateTime? firstDate,
  DateTime? lastDate,
  bool enableDateRange = true,
  String dateRangeTitle = 'Rentang waktu',
  List<Widget> additionalSections = const [],
  Map<String, dynamic> initialCustomFilters = const {},
  VoidCallback? onReset,
}) {
  final resolvedStartDate = initialStartDate ?? currentStartDate;
  final resolvedEndDate = initialEndDate ?? currentEndDate;
  return showAppBottomSheet<AppDateFilterResult>(
    context: context,
    child: AppDateFilterBottomSheet(
      title: title,
      subtitle: subtitle,
      initialPeriod: currentPeriod,
      initialStartDate: resolvedStartDate,
      initialEndDate: resolvedEndDate,
      startInCustomRange: startInCustomRange,
      scope: scope,
      firstDate: firstDate,
      lastDate: lastDate,
      enableDateRange: enableDateRange,
      dateRangeTitle: dateRangeTitle,
      additionalSections: additionalSections,
      initialCustomFilters: initialCustomFilters,
      onReset: onReset,
    ),
  );
}

/// Menampilkan bottom sheet pemilihan rentang tanggal kustom yang langsung
/// membuka tampilan "Atur Rentang Waktu".
Future<AppDateFilterResult?> showAppCustomDateRangeBottomSheet({
  required BuildContext context,
  String title = 'Filter data',
  String? subtitle,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  AppDateFilterScope scope = AppDateFilterScope.generic,
  DateTime? firstDate,
  DateTime? lastDate,
  bool enableDateRange = true,
  String dateRangeTitle = 'Rentang waktu',
  List<Widget> additionalSections = const [],
  Map<String, dynamic> initialCustomFilters = const {},
  VoidCallback? onReset,
}) {
  return showAppDateFilterBottomSheet(
    context: context,
    title: title,
    subtitle: subtitle,
    currentPeriod: AppDateFilterPeriod.custom,
    currentStartDate: initialStartDate,
    currentEndDate: initialEndDate,
    startInCustomRange: true,
    scope: scope,
    firstDate: firstDate,
    lastDate: lastDate,
    enableDateRange: enableDateRange,
    dateRangeTitle: dateRangeTitle,
    additionalSections: additionalSections,
    initialCustomFilters: initialCustomFilters,
    onReset: onReset,
  );
}
