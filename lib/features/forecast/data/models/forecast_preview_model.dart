import 'package:equatable/equatable.dart';

int _int(Object? value) => value is num ? value.toInt() : 0;

String _str(Object? value) => value?.toString() ?? '';

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    value is List
    ? value.whereType<Map<String, dynamic>>().map(parse).toList()
    : <T>[];

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

class ForecastPlanItemModel extends Equatable {
  const ForecastPlanItemModel({
    required this.date,
    required this.shiftUid,
    required this.email,
    required this.name,
  });

  factory ForecastPlanItemModel.fromJson(Map<String, dynamic> json) =>
      ForecastPlanItemModel(
        date: _str(json['date']),
        shiftUid: _str(json['shift_uid']),
        email: _str(json['email']),
        name: _str(json['name']),
      );

  /// `YYYY-MM-DD`.
  final String date;
  final String shiftUid;
  final String email;
  final String name;

  @override
  List<Object?> get props => [date, shiftUid, email, name];
}

class ForecastShiftStatModel extends Equatable {
  const ForecastShiftStatModel({
    required this.shiftUid,
    required this.shiftName,
    required this.created,
    required this.capacity,
  });

  factory ForecastShiftStatModel.fromJson(Map<String, dynamic> json) =>
      ForecastShiftStatModel(
        shiftUid: _str(json['shift_uid']),
        shiftName: _str(json['shift_name']),
        created: _int(json['created']),
        capacity: _int(json['capacity']),
      );

  final String shiftUid;
  final String shiftName;
  final int created;
  final int capacity;

  @override
  List<Object?> get props => [shiftUid, shiftName, created, capacity];
}

class ForecastPersonStatModel extends Equatable {
  const ForecastPersonStatModel({
    required this.email,
    required this.name,
    required this.total,
    this.avatarUrl,
  });

  factory ForecastPersonStatModel.fromJson(Map<String, dynamic> json) =>
      ForecastPersonStatModel(
        email: _str(json['email']),
        name: _str(json['name']),
        total: _int(json['total']),
        avatarUrl: json['avatar_url']?.toString(),
      );

  final String email;
  final String name;
  final int total;
  final String? avatarUrl;

  @override
  List<Object?> get props => [email, name, total, avatarUrl];
}

class ForecastUnderStaffedModel extends Equatable {
  const ForecastUnderStaffedModel({
    required this.date,
    required this.shiftUid,
    required this.shiftName,
    required this.short,
  });

  factory ForecastUnderStaffedModel.fromJson(Map<String, dynamic> json) =>
      ForecastUnderStaffedModel(
        date: _str(json['date']),
        shiftUid: _str(json['shift_uid']),
        shiftName: _str(json['shift_name']),
        short: _int(json['short']),
      );

  final String date;
  final String shiftUid;
  final String shiftName;
  final int short;

  @override
  List<Object?> get props => [date, shiftUid, shiftName, short];
}

class ForecastStatsModel extends Equatable {
  const ForecastStatsModel({
    required this.totalCreated,
    required this.totalDays,
    required this.totalPersonnel,
    required this.totalShifts,
    required this.totalCapacity,
    required this.perShift,
    required this.perPersonnel,
    required this.loadMin,
    required this.loadMax,
    required this.underStaffed,
    required this.underStaffedTotal,
  });

  factory ForecastStatsModel.fromJson(Map<String, dynamic> json) =>
      ForecastStatsModel(
        totalCreated: _int(json['total_created']),
        totalDays: _int(json['total_days']),
        totalPersonnel: _int(json['total_personnel']),
        totalShifts: _int(json['total_shifts']),
        totalCapacity: _int(json['total_capacity']),
        perShift: _list(json['per_shift'], ForecastShiftStatModel.fromJson),
        perPersonnel: _list(
          json['per_personnel'],
          ForecastPersonStatModel.fromJson,
        ),
        loadMin: _int(json['load_min']),
        loadMax: _int(json['load_max']),
        underStaffed: _list(
          json['under_staffed'],
          ForecastUnderStaffedModel.fromJson,
        ),
        underStaffedTotal: _int(json['under_staffed_total']),
      );

  final int totalCreated;
  final int totalDays;
  final int totalPersonnel;
  final int totalShifts;
  final int totalCapacity;
  final List<ForecastShiftStatModel> perShift;
  final List<ForecastPersonStatModel> perPersonnel;
  final int loadMin;
  final int loadMax;
  final List<ForecastUnderStaffedModel> underStaffed;
  final int underStaffedTotal;

  @override
  List<Object?> get props => [
    totalCreated,
    totalDays,
    totalPersonnel,
    totalShifts,
    totalCapacity,
    perShift,
    perPersonnel,
    loadMin,
    loadMax,
    underStaffed,
    underStaffedTotal,
  ];
}

/// `data` of `POST /v1/schedules/generate/preview`.
class ForecastPreviewModel extends Equatable {
  const ForecastPreviewModel({
    required this.seed,
    required this.token,
    required this.existingCount,
    required this.deleteCount,
    required this.lockedCount,
    required this.plan,
    required this.stats,
  });

  factory ForecastPreviewModel.fromJson(Map<String, dynamic> json) =>
      ForecastPreviewModel(
        seed: _int(json['seed']),
        token: _str(json['preview_token']),
        existingCount: _int(json['existing_count']),
        deleteCount: _int(json['delete_count']),
        lockedCount: _int(json['locked_count']),
        plan: _list(json['plan'], ForecastPlanItemModel.fromJson),
        stats: ForecastStatsModel.fromJson(_map(json['stats'])),
      );

  final int seed;
  final String token;
  final int existingCount;
  final int deleteCount;
  final int lockedCount;
  final List<ForecastPlanItemModel> plan;
  final ForecastStatsModel stats;

  @override
  List<Object?> get props => [
    seed,
    token,
    existingCount,
    deleteCount,
    lockedCount,
    plan,
    stats,
  ];
}

/// `data` of `POST /v1/schedules/generate`.
class ForecastResultModel extends Equatable {
  const ForecastResultModel({required this.created, required this.deleted});

  factory ForecastResultModel.fromJson(Map<String, dynamic> json) =>
      ForecastResultModel(
        created: _int(json['created']),
        deleted: _int(json['deleted']),
      );

  final int created;
  final int deleted;

  @override
  List<Object?> get props => [created, deleted];
}
