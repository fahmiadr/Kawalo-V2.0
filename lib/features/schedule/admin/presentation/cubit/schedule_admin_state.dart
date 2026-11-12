import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';

enum ScheduleAdminStatus { loading, loaded, error }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday on or before the first of [month].
DateTime gridStart(DateTime month) {
  final first = DateTime(month.year, month.month);
  return DateTime(first.year, first.month, 1 - (first.weekday - 1));
}

/// Sunday on or after the last day of [month]; at most 42 days after
/// [gridStart], inside the 62-day window of the API.
DateTime gridEnd(DateTime month) {
  final last = DateTime(month.year, month.month + 1, 0);
  return DateTime(last.year, last.month, last.day + (7 - last.weekday));
}

class ScheduleAdminState extends Equatable {
  const ScheduleAdminState({
    required this.month,
    required this.selectedDay,
    this.status = ScheduleAdminStatus.loading,
    this.items = const [],
    this.message,
    this.filterEmail,
    this.filterName,
  });

  /// First day of the month on screen.
  final DateTime month;
  final DateTime selectedDay;
  final ScheduleAdminStatus status;

  /// Schedules of the visible grid (month plus the neighbouring days shown).
  final List<ManagedScheduleEntity> items;
  final String? message;

  /// Person filter; `null` shows everybody.
  final String? filterEmail;
  final String? filterName;

  List<ManagedScheduleEntity> itemsOn(DateTime day) =>
      items.where((e) => e.date == day).toList(growable: false);

  /// One colour per distinct shift scheduled on [day], for the calendar dots.
  List<String?> shiftColorsOn(DateTime day) {
    final byShift = <String?, String?>{};
    for (final e in items) {
      if (e.date == day) byShift.putIfAbsent(e.shiftUid, () => e.shiftColor);
    }
    return byShift.values.toList(growable: false);
  }

  ScheduleAdminState copyWith({
    DateTime? month,
    DateTime? selectedDay,
    ScheduleAdminStatus? status,
    List<ManagedScheduleEntity>? items,
    String? message,
    String? filterEmail,
    String? filterName,
    bool clearFilter = false,
  }) => ScheduleAdminState(
    month: month ?? this.month,
    selectedDay: selectedDay ?? this.selectedDay,
    status: status ?? this.status,
    items: items ?? this.items,
    message: message,
    filterEmail: clearFilter ? null : filterEmail ?? this.filterEmail,
    filterName: clearFilter ? null : filterName ?? this.filterName,
  );

  @override
  List<Object?> get props => [
    month,
    selectedDay,
    status,
    items,
    message,
    filterEmail,
    filterName,
  ];
}
