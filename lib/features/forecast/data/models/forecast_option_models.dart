import 'package:equatable/equatable.dart';

/// Item of `GET /v1/shifts`; fields the forecast does not use are ignored.
class ForecastShiftModel extends Equatable {
  const ForecastShiftModel({
    required this.uid,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.color,
  });

  factory ForecastShiftModel.fromJson(Map<String, dynamic> json) =>
      ForecastShiftModel(
        uid: json['uid']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        startTime: json['start_time']?.toString() ?? '',
        endTime: json['end_time']?.toString() ?? '',
        color: json['color']?.toString(),
      );

  final String uid;
  final String name;
  final String startTime;
  final String endTime;
  final String? color;

  @override
  List<Object?> get props => [uid, name, startTime, endTime, color];
}

/// Item of `GET /v1/groups/members`. Read here instead of reusing the group
/// feature so the two features stay independent.
class ForecastMemberModel extends Equatable {
  const ForecastMemberModel({
    required this.email,
    required this.role,
    this.name,
    this.avatarUrl,
  });

  factory ForecastMemberModel.fromJson(Map<String, dynamic> json) =>
      ForecastMemberModel(
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString(),
        role: json['role']?.toString() ?? '',
        // `profilePic` is the older key of the same photo.
        avatarUrl:
            json['avatar_url']?.toString() ?? json['profilePic']?.toString(),
      );

  final String email;
  final String? name;
  final String role;
  final String? avatarUrl;

  @override
  List<Object?> get props => [email, name, role, avatarUrl];
}
