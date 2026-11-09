import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_date_picker.dart';
import 'package:kawalo_mobile/core/widgets/date_filter/app_date_filter_models.dart';
import 'package:kawalo_mobile/core/widgets/date_filter/app_date_filter_result.dart';
import 'package:kawalo_mobile/core/widgets/date_filter/date_filter_custom_range_view.dart';
import 'package:kawalo_mobile/core/widgets/date_filter/date_filter_options_view.dart';

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

  void _selectPeriod(AppDateFilterPeriod period) {
    if (period == AppDateFilterPeriod.custom) {
      _switchToCustomRange();
    } else {
      setState(() {
        _selectedPeriod = period;
        _startDate = null;
        _endDate = null;
      });
    }
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
                  ? DateFilterOptionsView(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      dateRangeTitle: widget.dateRangeTitle,
                      enableDateRange: widget.enableDateRange,
                      selectedPeriod: _selectedPeriod,
                      hasCustomFilters: _customFilters.isNotEmpty,
                      additionalSections: widget.additionalSections,
                      resolvePeriodDateRange: _resolvePeriodDateRange,
                      onPeriodSelected: _selectPeriod,
                      onReset: _reset,
                      onApply: _applyFilter,
                    )
                  : DateFilterCustomRangeView(
                      draftStartDate: _draftStartDate,
                      draftEndDate: _draftEndDate,
                      errorMessage: _errorMessage,
                      canConfirm: _canConfirmRange,
                      onBack: _switchToOptions,
                      onPickStartDate: _pickStartDate,
                      onPickEndDate: _pickEndDate,
                      onConfirm: _applyCustomRange,
                    ),
            ),
          ),
        ),
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
