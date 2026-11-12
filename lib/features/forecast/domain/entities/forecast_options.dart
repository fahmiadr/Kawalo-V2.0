import 'package:equatable/equatable.dart';

/// A shift of the active group that can be given a quota in the forecast.
class ForecastShift extends Equatable {
  const ForecastShift({
    required this.uid,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.color,
  });

  final String uid;
  final String name;

  /// Zero-padded `HH:MM`.
  final String startTime;

  /// Zero-padded `HH:MM`.
  final String endTime;

  final String? color;

  @override
  List<Object?> get props => [uid, name, startTime, endTime, color];
}

/// An active member of the group that can be scheduled.
class ForecastPerson extends Equatable {
  const ForecastPerson({
    required this.email,
    required this.role,
    this.name,
    this.avatarUrl,
  });

  final String email;
  final String? name;

  /// Upper-cased category of the member in the active group.
  final String role;

  final String? avatarUrl;

  bool get isGuard => role == 'GUARD';

  /// The name falls back to the email, so the label is never empty.
  String get displayName {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? email : trimmed;
  }

  @override
  List<Object?> get props => [email, name, role, avatarUrl];
}

/// Everything the configuration step needs from the server.
class ForecastOptions extends Equatable {
  const ForecastOptions({required this.shifts, required this.people});

  final List<ForecastShift> shifts;
  final List<ForecastPerson> people;

  @override
  List<Object?> get props => [shifts, people];
}
