import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_remote_data_source.dart';
import 'package:kawalo_mobile/features/incident/data/models/create_incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_query_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/post_incident_reply_model.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late IncidentRemoteDataSource remoteDataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    remoteDataSource = IncidentRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  group('IncidentRemoteDataSource Tests', () {
    test(
      'getIncidents calls apiClient.get with correct path and query',
      () async {
        when(
          () => mockApiClient.get(
            '/v1/incidents',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => {
            'data': [
              {
                'id': 'inc_1',
                'group_id': 'grp_1',
                'title': 'Pintu Rusak',
                'status': 'OPEN',
                'created_by': 'usr_1',
                'created_at': '2026-11-04T10:00:00.000Z',
              },
            ],
          },
        );

        const query = IncidentQueryModel(groupId: 'grp_1', status: 'OPEN');
        final result = await remoteDataSource.getIncidents(query: query);

        expect(result.length, equals(1));
        expect(result[0].id, equals('inc_1'));
        expect(result[0].title, equals('Pintu Rusak'));
      },
    );

    test('IncidentQueryModel omits group_id and includes start_date, '
        'end_date, limit, and offset', () {
      const query = IncidentQueryModel(
        groupId: 'grp_1',
        status: 'OPEN',
        search: 'kebocoran',
        startDate: '2026-11-01T00:00:00.000',
        endDate: '2026-11-06T23:59:59.000',
        limit: 20,
        offset: 40,
      );

      final params = query.toQueryParams();

      expect(params.containsKey('group_id'), isFalse);
      expect(params['status'], equals('OPEN'));
      expect(params['search'], equals('kebocoran'));
      expect(params['start_date'], equals('2026-11-01T00:00:00.000'));
      expect(params['end_date'], equals('2026-11-06T23:59:59.000'));
      expect(params['limit'], equals(20));
      expect(params['offset'], equals(40));
    });

    test('getIncidentDetail calls apiClient.get with id', () async {
      when(
        () => mockApiClient.get(
          '/v1/incidents/inc_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'incident': {
              'id': 'inc_1',
              'group_id': 'grp_1',
              'title': 'Pintu Rusak',
              'status': 'OPEN',
              'created_by': 'usr_1',
              'created_at': '2026-11-04T10:00:00.000Z',
            },
            'replies': [
              {
                'id': 'rep_1',
                'incident_id': 'inc_1',
                'sender_id': 'usr_2',
                'sender_name': 'Dewi',
                'sender_role': 'admin',
                'message': 'Sedang dicek',
                'created_at': '2026-11-04T10:05:00.000Z',
              },
            ],
          },
        },
      );

      final result = await remoteDataSource.getIncidentDetail(
        incidentId: 'inc_1',
      );

      expect(result.incident.id, equals('inc_1'));
      expect(result.replies.length, equals(1));
      expect(result.replies[0].senderName, equals('Dewi'));
    });

    test('createIncident calls apiClient.post with payload', () async {
      when(
        () => mockApiClient.post(
          '/v1/incidents',
          body: any<dynamic>(named: 'body'),
          cancelToken: any<CancelToken?>(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'id': 'inc_new',
            'group_id': 'grp_1',
            'title': 'Lampu Mati',
            'status': 'OPEN',
            'created_by': 'usr_1',
            'created_at': '2026-11-04T10:00:00.000Z',
          },
        },
      );

      const model = CreateIncidentModel(title: 'Lampu Mati', groupId: 'grp_1');

      final result = await remoteDataSource.createIncident(data: model);

      expect(result.id, equals('inc_new'));
      expect(result.title, equals('Lampu Mati'));
    });

    test('postIncidentReply calls apiClient.post on reply endpoint', () async {
      when(
        () => mockApiClient.post(
          '/v1/incidents/inc_1/replies',
          body: any<dynamic>(named: 'body'),
          cancelToken: any<CancelToken?>(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'id': 'rep_new',
            'incident_id': 'inc_1',
            'sender_id': 'usr_1',
            'sender_name': 'Budi',
            'sender_role': 'guard',
            'message': 'Siap komandan',
            'created_at': '2026-11-04T10:10:00.000Z',
          },
        },
      );

      const model = PostIncidentReplyModel(message: 'Siap komandan');
      final result = await remoteDataSource.postIncidentReply(
        incidentId: 'inc_1',
        data: model,
      );

      expect(result.id, equals('rep_new'));
      expect(result.message, equals('Siap komandan'));
    });

    test('resolveIncident calls apiClient.patch on resolve endpoint', () async {
      when(
        () => mockApiClient.patch(
          '/v1/incidents/inc_1/resolve',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'id': 'inc_1',
            'group_id': 'grp_1',
            'title': 'Pintu Rusak',
            'status': 'RESOLVED',
            'created_by': 'usr_1',
            'resolved_by': 'usr_2',
            'resolved_by_name': 'Dewi',
            'resolved_at': '2026-11-04T10:20:00.000Z',
            'created_at': '2026-11-04T10:00:00.000Z',
          },
        },
      );

      final result = await remoteDataSource.resolveIncident(
        incidentId: 'inc_1',
      );

      expect(result.status, equals('RESOLVED'));
      expect(result.resolvedByName, equals('Dewi'));
    });

    test('deleteIncident calls apiClient.delete with id', () async {
      when(
        () => mockApiClient.delete(
          '/v1/incidents/inc_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => {'success': true});

      await expectLater(
        remoteDataSource.deleteIncident(incidentId: 'inc_1'),
        completes,
      );

      verify(() => mockApiClient.delete('/v1/incidents/inc_1')).called(1);
    });

    test('watchIncidentStream sets Accept and Last-Event-ID headers and '
        'transforms SSE', () async {
      const sseText =
          'event: new_reply\n'
          'data: {"id": "rep_10", "incident_id": "inc_1", "sender_id": "u1", '
          '"sender_name": "Budi", "sender_role": "guard", "message": "tes", '
          '"created_at": "2026-11-04T10:00:00.000Z"}\n\n';
      final byteStream = Stream.value(Uint8List.fromList(utf8.encode(sseText)));
      final responseBody = ResponseBody(byteStream, 200);

      when(
        () => mockApiClient.getStream(
          '/v1/incidents/inc_1/stream',
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<ResponseBody>(
          data: responseBody,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/v1/incidents/inc_1/stream'),
        ),
      );

      final stream = remoteDataSource.watchIncidentStream(
        incidentId: 'inc_1',
        lastEventId: 'rep_9',
      );

      final messages = await stream.toList();

      expect(messages.length, equals(1));
      expect(messages[0].event, equals('new_reply'));
    });
  });
}
