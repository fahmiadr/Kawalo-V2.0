import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_native_platform_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/mappers/ptt_mapper.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_event_dto.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_transcript.dart';
import 'package:mocktail/mocktail.dart';

class MockNativeDataSource extends Mock
    implements PttNativePlatformDataSource {}

void main() {
  group('PttMapper.toTranscript', () {
    test('parses an ok payload, trimming the text', () {
      expect(
        PttMapper.toTranscript({
          'requestId': 'req_1',
          'status': 'ok',
          'text': ' Pos dua aman ',
          'locale': 'id-ID',
          'reason': 'on_device_segmented_end',
        }),
        const PttTranscript(
          requestId: 'req_1',
          status: PttTranscriptStatus.ok,
          text: 'Pos dua aman',
          locale: 'id-ID',
          reason: 'on_device_segmented_end',
        ),
      );
    });

    test('failed and unsupported drop any text and locale', () {
      final t = PttMapper.toTranscript({
        'requestId': 'req_1',
        'status': 'unsupported',
        'text': 'x',
        'locale': 'id-ID',
        'reason': 'sdk_30_below_33',
      })!;
      expect(t.status, PttTranscriptStatus.unsupported);
      expect(t.text, isNull);
      expect(t.locale, isNull);
      expect(t.reason, 'sdk_30_below_33');
    });

    test('ok without text becomes failed', () {
      final t = PttMapper.toTranscript({
        'requestId': 'req_1',
        'status': 'ok',
        'text': '  ',
      })!;
      expect(t.status, PttTranscriptStatus.failed);
      expect(t.text, isNull);
    });

    test('rejects payloads without a turn id or with an unknown status', () {
      expect(PttMapper.toTranscript({'status': 'ok', 'text': 'a'}), isNull);
      expect(
        PttMapper.toTranscript({'requestId': 'req_1', 'status': 'done'}),
        isNull,
      );
    });
  });

  test('watchTranscripts emits only valid transcriptReady events', () async {
    final events = StreamController<PttEventDto>.broadcast();
    final source = MockNativeDataSource();
    when(() => source.eventStream).thenAnswer((_) => events.stream);
    final repository = PttRepositoryImpl(dataSource: source);

    final received = <PttTranscript>[];
    final sub = repository.watchTranscripts().listen(received.add);
    events
      ..add(
        PttEventDto.fromMap(const {
          'event': 'transcriptReady',
          'data': {'requestId': 'req_1', 'status': 'failed', 'reason': 'x'},
        }),
      )
      ..add(
        PttEventDto.fromMap(const {
          'event': 'floorStateChanged',
          'data': {'state': 'IDLE'},
        }),
      )
      ..add(
        PttEventDto.fromMap(const {
          'event': 'transcriptReady',
          'data': {'status': 'ok'},
        }),
      );
    await Future<void>.delayed(Duration.zero);

    expect(received, const [
      PttTranscript(
        requestId: 'req_1',
        status: PttTranscriptStatus.failed,
        reason: 'x',
      ),
    ]);
    await sub.cancel();
    await events.close();
  });
}
