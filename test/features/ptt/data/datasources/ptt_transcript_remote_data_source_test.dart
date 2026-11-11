import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  test('PUTs the body to the by-request path', () async {
    final api = MockApiClient();
    when(
      () => api.put(any(), body: any<dynamic>(named: 'body')),
    ).thenAnswer((_) async => {'success': true});

    await PttTranscriptRemoteDataSourceImpl(apiClient: api).putTranscript(
      requestId: 'req_1731300000000',
      status: 'ok',
      text: ' Pos dua aman ',
      locale: 'id-ID',
    );

    verify(
      () => api.put(
        '/v1/ptt/recordings/by-request/req_1731300000000/transcript',
        body: {'status': 'ok', 'text': 'Pos dua aman', 'locale': 'id-ID'},
      ),
    ).called(1);
  });

  group('transcriptBody', () {
    const body = PttTranscriptRemoteDataSourceImpl.transcriptBody;

    test('failed and unsupported carry no text or locale', () {
      expect(body(status: 'failed', text: 'x', locale: 'id-ID'), {
        'status': 'failed',
      });
      expect(body(status: 'unsupported'), {'status': 'unsupported'});
    });

    test('ok without text becomes failed', () {
      expect(body(status: 'ok', text: '  '), {'status': 'failed'});
    });

    test('ok without locale omits it', () {
      expect(body(status: 'ok', text: 'a'), {'status': 'ok', 'text': 'a'});
    });

    test('cuts text at 2000 code points without splitting emoji', () {
      final long = '${'a' * 1999}😀😀';
      final text = body(status: 'ok', text: long)['text'] as String;

      expect(text.runes.length, 2000);
      expect(text.endsWith('a😀'), isTrue);
    });
  });
}
