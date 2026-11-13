import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_input.dart';

/// Per-field validation messages; a null field is valid.
class ShiftFormErrors extends Equatable {
  const ShiftFormErrors({
    this.name,
    this.startTime,
    this.endTime,
    this.description,
  });

  static const none = ShiftFormErrors();

  final String? name;
  final String? startTime;
  final String? endTime;
  final String? description;

  bool get isValid =>
      name == null &&
      startTime == null &&
      endTime == null &&
      description == null;

  ShiftFormErrors withName(String message) => ShiftFormErrors(
    name: message,
    startTime: startTime,
    endTime: endTime,
    description: description,
  );

  @override
  List<Object?> get props => [name, startTime, endTime, description];
}

/// Raw form values, validated with the same rules as `POST /shifts`.
class ShiftFormValues extends Equatable {
  const ShiftFormValues({
    this.name = '',
    this.startTime,
    this.endTime,
    this.color = defaultColor,
    this.description = '',
  });

  static const defaultColor = '#F2A900';
  static const textMax = 128;

  final String name;
  final ShiftClock? startTime;
  final ShiftClock? endTime;
  final String color;
  final String description;

  ShiftFormValues copyWith({
    String? name,
    ShiftClock? startTime,
    ShiftClock? endTime,
    String? color,
    String? description,
  }) => ShiftFormValues(
    name: name ?? this.name,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    color: color ?? this.color,
    description: description ?? this.description,
  );

  ShiftFormErrors validate() {
    final trimmedName = name.trim();
    final start = startTime;
    final end = endTime;

    return ShiftFormErrors(
      name: trimmedName.isEmpty
          ? 'Nama shift wajib diisi.'
          : trimmedName.length > textMax
          ? 'Nama shift maksimal $textMax karakter.'
          : null,
      startTime: start == null ? 'Pilih jam mulai.' : null,
      endTime: end == null
          ? 'Pilih jam selesai.'
          : start == end
          ? 'Jam mulai dan jam selesai tidak boleh sama.'
          : null,
      description: description.trim().length > textMax
          ? 'Deskripsi maksimal $textMax karakter.'
          : null,
    );
  }

  /// Call only when [validate] reports no errors.
  ShiftInput toInput() {
    final desc = description.trim();
    return ShiftInput(
      name: name.trim(),
      startTime: startTime!,
      endTime: endTime!,
      color: color.toUpperCase(),
      description: desc.isEmpty ? null : desc,
    );
  }

  @override
  List<Object?> get props => [name, startTime, endTime, color, description];
}
