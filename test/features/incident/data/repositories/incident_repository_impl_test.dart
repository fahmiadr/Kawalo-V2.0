import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/network/sse_stream_transformer.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_remote_data_source.dart';
import 'package:kawalo_mobile/features/incident/data/models/create_incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_detail_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_query_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_reply_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/post_incident_reply_model.dart';
import 'package:kawalo_mobile/features/incident/data/repositories/incident_repository_impl.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/create_incident_data.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_query_params.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentRemoteDataSource extends Mock
    implements IncidentRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  setUpAll(() {
    registerFallbackValue(const IncidentQueryModel(groupId: ''));
    registerFallbackValue(const CreateIncidentModel(title: '', groupId: ''));
    registerFallbackValue(const PostIncidentReplyModel(message: ''));
  });

  late MockIncidentRemoteDataSource mockRemoteDataSource;
  late IncidentRepository repository;

  setUp(() {
    mockRemoteDataSource = MockIncidentRemoteDataSource();
    repository = IncidentRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tIncidentModel = IncidentModel(
    id: 'inc_1',
    groupId: 'grp_1',
    title: 'Pintu Rusak',
    status: 'OPEN',
    createdBy: 'usr_1',
    createdAt: '2026-11-04T10:00:00.000Z',
  );

  group('IncidentRepositoryImpl Tests', () {
    test('getIncidents returns Right(List<IncidentEntity>) on success',
        () async {
      when(
        () => mockRemoteDataSource.getIncidents(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => [tIncidentModel]);

      const params = IncidentQueryParams(groupId: 'grp_1');
      final result = await repository.getIncidents(params);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (items) {
          expect(items.length, equals(1));
          expect(items[0].id, equals('inc_1'));
          expect(items[0].status, equals(IncidentStatus.open));
        },
      );
    });

    test('getIncidents returns Left(Failure) on AppException', () async {
      when(
        () => mockRemoteDataSource.getIncidents(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const NoInternetException());

      const params = IncidentQueryParams(groupId: 'grp_1');
      final result = await repository.getIncidents(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NoInternetFailure>()),
        (_) => fail('Should be left'),
      );
    });

    test(
      'createIncident returns Left(NoInternetFailure) when network is offline',
      () async {
        final mockNetInfo = MockNetworkInfo();
        when(() => mockNetInfo.isConnected).thenAnswer((_) async => false);

        final repoWithNet = IncidentRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          networkInfo: mockNetInfo,
        );

        final result = await repoWithNet.createIncident(
          const CreateIncidentData(title: 'Banjir', groupId: 'grp_1'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NoInternetFailure>()),
          (_) => fail('Should be left'),
        );
        verifyNever(
          () => mockRemoteDataSource.createIncident(
            data: any(named: 'data'),
          ),
        );
      },
    );

    test('resolveIncident maps 409 Conflict ServerException to ServerFailure',
        () async {
      when(
        () => mockRemoteDataSource.resolveIncident(
          incidentId: 'inc_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const ServerException(
          'Sudah diselesaikan',
          409,
          'ALREADY_RESOLVED',
        ),
      );

      final result = await repository.resolveIncident(incidentId: 'inc_1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          final serverFailure = failure as ServerFailure;
          expect(serverFailure.statusCode, equals(409));
        },
        (_) => fail('Should be left'),
      );
    });

    test('watchIncidentReplies parses SseMessage into IncidentReplyStreamEvent',
        () async {
      const message = SseMessage(
        id: 'rep_1',
        event: 'new_reply',
        data: '{"id": "rep_1", "incident_id": "inc_1", "sender_id": "u1", '
            '"sender_name": "Budi", "sender_role": "guard", "message": "Siap", '
            '"created_at": "2026-11-04T10:00:00.000Z"}',
      );

      when(
        () => mockRemoteDataSource.watchIncidentStream(
          incidentId: 'inc_1',
          lastEventId: any(named: 'lastEventId'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => Stream.value(message));

      final stream = repository.watchIncidentReplies(incidentId: 'inc_1');
      final events = await stream.toList();

      expect(events.length, equals(1));
      expect(events[0].isRight(), isTrue);
      events[0].fold(
        (_) => fail('Should be right'),
        (event) {
          expect(event, isA<IncidentReplyStreamEvent>());
          final replyEvent = event as IncidentReplyStreamEvent;
          expect(replyEvent.reply.message, equals('Siap'));
        },
      );
    });

    test(
        'watchIncidentReplies emits IncidentResyncedStreamEvent on '
            'sync_required', () async {
      const syncMessage = SseMessage(
        event: 'sync_required',
        data: '{"reason": "buffer_overflow"}',
      );

      const tDetailModel = IncidentDetailModel(
        incident: tIncidentModel,
        replies: [
          IncidentReplyModel(
            id: 'rep_sync_1',
            incidentId: 'inc_1',
            senderId: 'u2',
            senderName: 'Dewi',
            senderRole: 'admin',
            message: 'Resynced reply',
            createdAt: '2026-11-04T10:00:00.000Z',
          ),
        ],
      );

      when(
        () => mockRemoteDataSource.watchIncidentStream(
          incidentId: 'inc_1',
          lastEventId: any(named: 'lastEventId'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => Stream.value(syncMessage));

      when(
        () => mockRemoteDataSource.getIncidentDetail(
          incidentId: 'inc_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => tDetailModel);

      final stream = repository.watchIncidentReplies(incidentId: 'inc_1');
      final events = await stream.toList();

      expect(events.length, equals(1));
      events[0].fold(
        (_) => fail('Should be right'),
        (event) {
          expect(event, isA<IncidentResyncedStreamEvent>());
          final resync = event as IncidentResyncedStreamEvent;
          expect(resync.incident.id, equals('inc_1'));
          expect(resync.replies.length, equals(1));
          expect(resync.replies[0].message, equals('Resynced reply'));
        },
      );
    });
  });
}
