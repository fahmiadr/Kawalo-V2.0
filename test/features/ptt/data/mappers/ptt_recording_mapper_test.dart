import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/ptt/data/mappers/ptt_recording_mapper.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_recording_model.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';

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

  Map<String, dynamic> item([Map<String, dynamic> extra = const {}]) => {
    'id': 'rec_3',
    'speaker': {'id': 'usr_3', 'name': 'Sari', 'role': 'GUARD'},
    'started_at': '2026-11-11T02:30:00Z',
    'duration_ms': 1000,
    'size_bytes': 10,
    ...extra,
  };

  PttRecordingEntity map(Map<String, dynamic> json) =>
      PttRecordingMapper.toEntity(PttRecordingModel.fromJson(json));

  test('maps the transcript fields', () {
    final e = map(
      item({
        'transcript': 'Pos satu aman',
        'transcript_locale': 'id-ID',
        'transcript_source': 'device',
        'transcript_status': 'done',
      }),
    );

    expect(e.transcript, 'Pos satu aman');
    expect(e.displayTranscript, 'Pos satu aman');
    expect(e.transcriptLocale, 'id-ID');
    expect(e.transcriptSource, PttTranscriptSource.device);
    expect(e.transcriptStatus, 'done');
  });

  test('an old server without transcript fields yields nulls', () {
    final e = map(item());

    expect(e.transcript, isNull);
    expect(e.displayTranscript, isNull);
    expect(e.transcriptLocale, isNull);
    expect(e.transcriptSource, isNull);
    expect(e.transcriptStatus, isNull);
  });

  test('unknown source maps to null, unknown status is kept, blank hides', () {
    final e = map(
      item({
        'transcript': '   ',
        'transcript_source': 'cloud9',
        'transcript_status': 'brand_new',
      }),
    );

    expect(e.transcriptSource, isNull);
    expect(e.transcriptStatus, 'brand_new');
    expect(e.displayTranscript, isNull);
    expect(
      map(item({'transcript_source': 'server'})).transcriptSource,
      PttTranscriptSource.server,
    );
  });
}
