import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/network/sse_stream_transformer.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_local_data_source.dart';
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

class MockIncidentLocalDataSource extends Mock
    implements IncidentLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  setUpAll(() {
    registerFallbackValue(const IncidentQueryModel(groupId: ''));
    registerFallbackValue(const CreateIncidentModel(title: '', groupId: ''));
    registerFallbackValue(const PostIncidentReplyModel(message: ''));
    registerFallbackValue(DateTime(2026));
  });

  late MockIncidentRemoteDataSource mockRemoteDataSource;
  late IncidentRepository repository;

  setUp(() {
    mockRemoteDataSource = MockIncidentRemoteDataSource();
    repository = IncidentRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      syncStorageService: SyncStorageService(),
    );
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
    test(
      'getIncidents returns Right(List<IncidentEntity>) on success',
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
        result.fold((_) => fail('Should be right'), (items) {
          expect(items.length, equals(1));
          expect(items[0].id, equals('inc_1'));
          expect(items[0].status, equals(IncidentStatus.open));
        });
      },
    );

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

    group('getIncidents offline cache', () {
      late MockIncidentLocalDataSource mockLocal;
      late MockNetworkInfo mockNetInfo;
      late IncidentRepositoryImpl cachedRepo;
      var isOnline = true;

      When<Future<List<IncidentModel>>> stubRemote() => when(
        () => mockRemoteDataSource.getIncidents(
          query: any(named: 'query'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );

      setUp(() {
        isOnline = true;
        mockLocal = MockIncidentLocalDataSource();
        mockNetInfo = MockNetworkInfo();
        when(() => mockNetInfo.isConnected).thenAnswer((_) async => isOnline);
        when(() => mockLocal.cacheIncidents(any())).thenAnswer((_) async {});
        when(() => mockLocal.deleteOlderThan(any())).thenAnswer((_) async {});
        when(
          () => mockLocal.getCachedIncidents(
            groupId: any(named: 'groupId'),
            status: any(named: 'status'),
            search: any(named: 'search'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => [tIncidentModel]);
        cachedRepo = IncidentRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          localDataSource: mockLocal,
          syncStorageService: SyncStorageService(),
          networkInfo: mockNetInfo,
        );
      });

      test(
        'writes the fetched list to the cache and evicts old rows',
        () async {
          stubRemote().thenAnswer((_) async => [tIncidentModel]);

          final result = await cachedRepo.getIncidents(
            const IncidentQueryParams(groupId: 'grp_1'),
          );

          expect(result.isRight(), isTrue);
          verify(() => mockLocal.cacheIncidents([tIncidentModel])).called(1);
          verify(() => mockLocal.deleteOlderThan(any())).called(1);
        },
      );

      test('falls back to the cache when the remote call fails', () async {
        stubRemote().thenThrow(const NoInternetException());

        final result = await cachedRepo.getIncidents(
          const IncidentQueryParams(groupId: 'grp_1'),
        );

        result.fold(
          (_) => fail('Should serve the cache'),
          (items) => expect(items.single.id, 'inc_1'),
        );
      });

      test(
        'serves the filtered cache without a remote call when offline',
        () async {
          isOnline = false;

          final result = await cachedRepo.getIncidents(
            const IncidentQueryParams(
              groupId: 'grp_1',
              status: IncidentStatus.resolved,
              search: 'pintu',
              startDate: '2026-11-01T00:00:00.000Z',
              endDate: '2026-11-30T23:59:59.000Z',
              offset: 0,
            ),
          );

          expect(result.getOrElse((_) => []).single.id, 'inc_1');
          verify(
            () => mockLocal.getCachedIncidents(
              groupId: 'grp_1',
              status: 'RESOLVED',
              search: 'pintu',
              startDate: '2026-11-01T00:00:00.000Z',
              endDate: '2026-11-30T23:59:59.000Z',
            ),
          ).called(1);
          verifyNever(
            () => mockRemoteDataSource.getIncidents(
              query: any(named: 'query'),
              cancelToken: any(named: 'cancelToken'),
            ),
          );
        },
      );

      test('returns no rows for later pages served from the cache', () async {
        isOnline = false;

        final result = await cachedRepo.getIncidents(
          const IncidentQueryParams(groupId: 'grp_1', offset: 20),
        );

        result.fold(
          (_) => fail('Should serve the cache'),
          (items) => expect(items, isEmpty),
        );
      });

      test('pull-to-refresh still tries the remote while offline', () async {
        isOnline = false;
        stubRemote().thenAnswer((_) async => [tIncidentModel]);

        await cachedRepo.getIncidents(
          const IncidentQueryParams(groupId: 'grp_1', isRefresh: true),
        );

        verify(
          () => mockRemoteDataSource.getIncidents(
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      });

      test(
        'fails with offlineNoStorage when offline without a cache',
        () async {
          isOnline = false;
          final noCacheRepo = IncidentRepositoryImpl(
            remoteDataSource: mockRemoteDataSource,
            syncStorageService: SyncStorageService(),
            networkInfo: mockNetInfo,
          );

          final result = await noCacheRepo.getIncidents(
            const IncidentQueryParams(groupId: 'grp_1'),
          );

          result.fold(
            (failure) => expect(
              failure.message,
              NoInternetFailure.offlineNoStorageMessage,
            ),
            (_) => fail('Should be left'),
          );
        },
      );

      test('mutations stay online-only even when a cache exists', () async {
        isOnline = false;

        final results = [
          await cachedRepo.resolveIncident(incidentId: 'inc_1'),
          await cachedRepo.deleteIncident(incidentId: 'inc_1'),
        ];

        for (final result in results) {
          result.fold(
            (failure) => expect(failure, isA<NoInternetFailure>()),
            (_) => fail('Should be left'),
          );
        }
        verifyNever(
          () => mockRemoteDataSource.resolveIncident(
            incidentId: any(named: 'incidentId'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      });
    });

    test(
      'createIncident returns Left(NoInternetFailure) when network is offline',
      () async {
        final mockNetInfo = MockNetworkInfo();
        when(() => mockNetInfo.isConnected).thenAnswer((_) async => false);

        final repoWithNet = IncidentRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          syncStorageService: SyncStorageService(),
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
          () => mockRemoteDataSource.createIncident(data: any(named: 'data')),
        );
      },
    );

    test(
      'resolveIncident maps 409 Conflict ServerException to ServerFailure',
      () async {
        when(
          () => mockRemoteDataSource.resolveIncident(
            incidentId: 'inc_1',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(
          const ServerException('Sudah diselesaikan', 409, 'ALREADY_RESOLVED'),
        );

        final result = await repository.resolveIncident(incidentId: 'inc_1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          final serverFailure = failure as ServerFailure;
          expect(serverFailure.statusCode, equals(409));
        }, (_) => fail('Should be left'));
      },
    );

    test(
      'watchIncidentReplies parses SseMessage into IncidentReplyStreamEvent',
      () async {
        const message = SseMessage(
          id: 'rep_1',
          event: 'new_reply',
          data:
              '{"id": "rep_1", "incident_id": "inc_1", "sender_id": "u1", '
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
        events[0].fold((_) => fail('Should be right'), (event) {
          expect(event, isA<IncidentReplyStreamEvent>());
          final replyEvent = event as IncidentReplyStreamEvent;
          expect(replyEvent.reply.message, equals('Siap'));
        });
      },
    );

    test('watchIncidentReplies emits IncidentResyncedStreamEvent on '
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
      events[0].fold((_) => fail('Should be right'), (event) {
        expect(event, isA<IncidentResyncedStreamEvent>());
        final resync = event as IncidentResyncedStreamEvent;
        expect(resync.incident.id, equals('inc_1'));
        expect(resync.replies.length, equals(1));
        expect(resync.replies[0].message, equals('Resynced reply'));
      });
    });
  });
}
