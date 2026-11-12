import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/mappers/schedule_admin_mapper.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/models/schedule_admin_models.dart';

void main() {
  Map<String, dynamic> row(Map<String, dynamic> extra) => {
    'id': 1,
    'date': '2026-11-10',
    'email': 'a@x.id',
    'name': 'Ani',
    ...extra,
  };

  test('avatar_url is parsed into the entity', () {
    final entity = ScheduleAdminMapper.toEntity(
      ManagedScheduleModel.fromJson(row({'avatar_url': 'https://x.id/a.webp'})),
    );

    expect(entity.avatarUrl, 'https://x.id/a.webp');
  });

  test('a missing or non-string avatar_url is null', () {
    expect(
      ScheduleAdminMapper.toEntity(
        ManagedScheduleModel.fromJson(row({})),
      ).avatarUrl,
      isNull,
    );
    expect(
      ScheduleAdminMapper.toEntity(
        ManagedScheduleModel.fromJson(row({'avatar_url': 5})),
      ).avatarUrl,
      isNull,
    );
  });
}
