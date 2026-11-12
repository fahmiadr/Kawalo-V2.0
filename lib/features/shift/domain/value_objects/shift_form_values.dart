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
    this.location,
    this.locationName,
    this.radius,
  });

  static const none = ShiftFormErrors();

  final String? name;
  final String? startTime;
  final String? endTime;
  final String? description;
  final String? location;
  final String? locationName;
  final String? radius;

  bool get isValid =>
      name == null &&
      startTime == null &&
      endTime == null &&
      description == null &&
      location == null &&
      locationName == null &&
      radius == null;

  ShiftFormErrors withName(String message) => ShiftFormErrors(
    name: message,
    startTime: startTime,
    endTime: endTime,
    description: description,
    location: location,
    locationName: locationName,
    radius: radius,
  );

  @override
  List<Object?> get props => [
    name,
    startTime,
    endTime,
    description,
    location,
    locationName,
    radius,
  ];
}

/// Raw form values, validated with the same rules as `POST /shifts`.
class ShiftFormValues extends Equatable {
  const ShiftFormValues({
    this.name = '',
    this.startTime,
    this.endTime,
    this.color = defaultColor,
    this.description = '',
    this.limitLocation = false,
    this.latitude,
    this.longitude,
    this.locationName = '',
    this.radiusText = '$defaultRadius',
  });

  static const defaultColor = '#F2A900';
  static const defaultRadius = 100;
  static const radiusMin = 10;
  static const radiusMax = 1000;
  static const textMax = 128;

  final String name;
  final ShiftClock? startTime;
  final ShiftClock? endTime;
  final String color;
  final String description;
  final bool limitLocation;
  final double? latitude;
  final double? longitude;
  final String locationName;

  /// Kept as text so a half-typed custom radius survives rebuilds.
  final String radiusText;

  int? get radius => int.tryParse(radiusText.trim());

  ShiftFormValues copyWith({
    String? name,
    ShiftClock? startTime,
    ShiftClock? endTime,
    String? color,
    String? description,
    bool? limitLocation,
    double? latitude,
    double? longitude,
    String? locationName,
    String? radiusText,
  }) => ShiftFormValues(
    name: name ?? this.name,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    color: color ?? this.color,
    description: description ?? this.description,
    limitLocation: limitLocation ?? this.limitLocation,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    locationName: locationName ?? this.locationName,
    radiusText: radiusText ?? this.radiusText,
  );

  ShiftFormErrors validate() {
    final trimmedName = name.trim();
    final start = startTime;
    final end = endTime;
    final lat = latitude;
    final long = longitude;
    final r = radius;

    String? location;
    String? radiusError;
    if (limitLocation) {
      if (lat == null || long == null) {
        location = 'Pilih titik lokasi absen di peta.';
      } else if (lat == 0 && long == 0) {
        location = 'Koordinat lokasi tidak valid.';
      }
      if (r == null || r < radiusMin || r > radiusMax) {
        radiusError = 'Radius absen harus 10 sampai 1000 meter.';
      }
    }

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
      location: location,
      locationName: limitLocation && locationName.trim().length > textMax
          ? 'Nama lokasi maksimal $textMax karakter.'
          : null,
      radius: radiusError,
    );
  }

  /// Call only when [validate] reports no errors.
  ShiftInput toInput() {
    final desc = description.trim();
    final place = locationName.trim();
    return ShiftInput(
      name: name.trim(),
      startTime: startTime!,
      endTime: endTime!,
      color: color.toUpperCase(),
      description: desc.isEmpty ? null : desc,
      locationName: limitLocation && place.isNotEmpty ? place : null,
      latitude: limitLocation ? latitude : null,
      longitude: limitLocation ? longitude : null,
      radius: limitLocation ? radius : null,
    );
  }

  @override
  List<Object?> get props => [
    name,
    startTime,
    endTime,
    color,
    description,
    limitLocation,
    latitude,
    longitude,
    locationName,
    radiusText,
  ];
}
