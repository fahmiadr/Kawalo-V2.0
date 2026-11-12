import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/forecast/data/mappers/forecast_mapper.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_option_models.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_preview_model.dart';

void main() {
  test('members: avatar_url wins over profilePic, both optional', () {
    final options = ForecastMapper.toOptions(const [], [
      ForecastMemberModel.fromJson(const {
        'email': 'a@x.id',
        'role': 'GUARD',
        'avatar_url': 'https://x.id/a.webp',
        'profilePic': 'https://x.id/old.webp',
      }),
      ForecastMemberModel.fromJson(const {
        'email': 'b@x.id',
        'role': 'GUARD',
        'profilePic': 'https://x.id/b.webp',
      }),
      ForecastMemberModel.fromJson(const {'email': 'c@x.id', 'role': 'GUARD'}),
    ]);

    expect(options.people.map((p) => p.avatarUrl), [
      'https://x.id/a.webp',
      'https://x.id/b.webp',
      null,
    ]);
  });

  test('stats.per_personnel carries avatar_url', () {
    final preview = ForecastMapper.toPreview(
      ForecastPreviewModel.fromJson(const {
        'stats': {
          'per_personnel': [
            {
              'email': 'a@x.id',
              'name': 'Ani',
              'total': 2,
              'avatar_url': 'https://x.id/a.webp',
            },
            {'email': 'b@x.id', 'name': 'Budi', 'total': 1},
          ],
        },
      }),
    );

    expect(preview.stats.perPersonnel.first.avatarUrl, 'https://x.id/a.webp');
    expect(preview.stats.perPersonnel.last.avatarUrl, isNull);
  });
}
