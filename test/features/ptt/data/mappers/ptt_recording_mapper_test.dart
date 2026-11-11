import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/ptt/data/mappers/ptt_recording_mapper.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_recording_model.dart';

void main() {
  test('parses the API page and maps it to entities', () {
    final model = PttRecordingPageModel.fromJson({
      'items': [
        {
          'id': 'rec_1',
          'speaker': {
            'id': 'usr_1',
            'name': 'Budi',
            'role': 'GUARD',
            'email': 'Budi@Kawalo.id',
          },
          'started_at': '2026-11-11T02:30:00.000Z',
          'duration_ms': 7400,
          'size_bytes': 15000,
          'audio_path': '/api/v1/ptt/recordings/rec_1/audio',
        },
      ],
      'next_before': 'abc',
    });

    final page = PttRecordingMapper.toPage(model);

    expect(page.nextBefore, 'abc');
    final item = page.items.single;
    expect(item.id, 'rec_1');
    expect(item.speakerName, 'Budi');
    expect(item.duration, const Duration(milliseconds: 7400));
    expect(item.startedAt.toUtc(), DateTime.utc(2026, 11, 11, 2, 30));
    expect(item.isSpokenBy(' budi@kawalo.id '), isTrue);
    expect(item.isSpokenBy('lain@kawalo.id'), isFalse);
    expect(item.isSpokenBy(null), isFalse);
  });

  test('a last page has no cursor and a missing email is never "me"', () {
    final page = PttRecordingMapper.toPage(
      PttRecordingPageModel.fromJson({
        'items': [
          {
            'id': 'rec_2',
            'speaker': {'id': 'usr_2', 'name': 'Tamu', 'role': 'USER'},
            'started_at': '2026-11-11T02:30:00Z',
            'duration_ms': 1000,
            'size_bytes': 10,
          },
        ],
        'next_before': null,
      }),
    );

    expect(page.nextBefore, isNull);
    expect(page.items.single.isSpokenBy('x@kawalo.id'), isFalse);
    expect(page.items.single.isSpokenBy(''), isFalse);
  });
}
