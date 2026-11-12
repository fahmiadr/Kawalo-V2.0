import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';

enum ForecastFillMode {
  /// Existing schedules stay; only free slots are filled.
  empty,

  /// Unlocked schedules in the range are deleted and planned again.
  overwrite,
}

/// First failing rule per section of the form, `null` when the section is ok.
class ForecastConfigErrors extends Equatable {
  const ForecastConfigErrors({this.range, this.shifts, this.personnel});

  final String? range;
  final String? shifts;
  final String? personnel;

  bool get isValid => range == null && shifts == null && personnel == null;

  @override
  List<Object?> get props => [range, shifts, personnel];
}

/// Form values of a forecast. Limits mirror the API (`generate_dto.rs`,
/// `generator.rs::check_range`) so the preview call is not wasted on input the
/// server would refuse.
class ForecastConfig extends Equatable {
  const ForecastConfig({
    required this.startDate,
    required this.endDate,
    required this.quotas,
    required this.personnel,
    this.fillMode = ForecastFillMode.empty,
    this.restEnabled = true,
    this.maxConsecutive = defaultMaxConsecutive,
  });

  static const maxRangeDays = 92;
  static const maxDaysAhead = 366;
  static const maxShifts = 50;
  static const maxQuota = 50;
  static const maxPersonnel = 500;
  static const maxConsecutiveLimit = 31;
  static const defaultMaxConsecutive = 6;

  /// Calendar days at local midnight.
  final DateTime startDate;
  final DateTime endDate;

  /// Selected shift uid to people per day. Insertion order is the request
  /// order, which the server uses to break ties between identical shifts.
  final Map<String, int> quotas;

  /// Selected emails in request order.
  final List<String> personnel;

  final ForecastFillMode fillMode;
  final bool restEnabled;
  final int maxConsecutive;

  /// Days in the range, inclusive; at least 1 for a valid range.
  int get rangeDays => dayDiff(startDate, endDate) + 1;

  ForecastConfig copyWith({
    DateTime? startDate,
    DateTime? endDate,
    Map<String, int>? quotas,
    List<String>? personnel,
    ForecastFillMode? fillMode,
    bool? restEnabled,
    int? maxConsecutive,
  }) => ForecastConfig(
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    quotas: quotas ?? this.quotas,
    personnel: personnel ?? this.personnel,
    fillMode: fillMode ?? this.fillMode,
    restEnabled: restEnabled ?? this.restEnabled,
    maxConsecutive: maxConsecutive ?? this.maxConsecutive,
  );

  ForecastConfigErrors validate(DateTime today) {
    final now = dateOnly(today);
    final lastAllowed = addDays(now, maxDaysAhead);
    String? range;
    if (endDate.isBefore(startDate)) {
      range = 'Tanggal selesai tidak boleh sebelum tanggal mulai.';
    } else if (startDate.isBefore(now)) {
      range = 'Tanggal mulai tidak boleh sebelum hari ini.';
    } else if (rangeDays > maxRangeDays) {
      final limit = AppDateFormat.formatDateOnly(
        addDays(startDate, maxRangeDays - 1),
      );
      range =
          'Rentang $rangeDays hari. Maksimal $maxRangeDays hari '
          '(sampai $limit).';
    } else if (endDate.isAfter(lastAllowed)) {
      range = 'Jadwal hanya bisa dibuat sampai $maxDaysAhead hari ke depan.';
    }
    return ForecastConfigErrors(
      range: range,
      shifts: quotas.isEmpty ? 'Pilih minimal satu shift.' : null,
      personnel: personnel.isEmpty
          ? 'Pilih minimal satu personil.'
          : personnel.length > maxPersonnel
          ? 'Maksimal $maxPersonnel personil.'
          : null,
    );
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar arithmetic that stays on midnight across DST changes.
  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static int dayDiff(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    quotas,
    personnel,
    fillMode,
    restEnabled,
    maxConsecutive,
  ];
}
