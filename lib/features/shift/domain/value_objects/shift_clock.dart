import 'package:equatable/equatable.dart';

/// Wall-clock time of a shift boundary, `HH:MM` on the wire.
class ShiftClock extends Equatable implements Comparable<ShiftClock> {
  const ShiftClock(this.hour, this.minute);

  /// `null` unless [raw] is strictly `HH:MM` within 00:00..23:59.
  static ShiftClock? tryParse(String? raw) {
    if (raw == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(raw)) return null;
    final hour = int.parse(raw.substring(0, 2));
    final minute = int.parse(raw.substring(3, 5));
    if (hour > 23 || minute > 59) return null;
    return ShiftClock(hour, minute);
  }

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;

  /// Minutes from this clock to [end], wrapping past midnight. Equal clocks
  /// read as a full day, like the API.
  int minutesUntil(ShiftClock end) {
    final minutes = (end.totalMinutes - totalMinutes) % 1440;
    return minutes == 0 ? 1440 : minutes;
  }

  /// A shift ending at or before its start ends the next day.
  bool endsNextDay(ShiftClock end) => end.totalMinutes <= totalMinutes;

  @override
  int compareTo(ShiftClock other) => totalMinutes.compareTo(other.totalMinutes);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [hour, minute];
}
