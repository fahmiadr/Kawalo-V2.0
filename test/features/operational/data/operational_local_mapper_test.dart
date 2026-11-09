import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/operational/data/mappers/operational_local_mapper.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_local_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';

void main() {
  group('OperationalLocalMapper Tests', () {
    const testTimeline = DutyTimelineModel(
      id: '101',
      journeyUid: 'JRN-01',
      duty: 'Patroli Sektor 1',
      state: 'Aktif',
      dutyDt: '2026-09-10 08:00',
      stateDt: '2026-09-10 08:15',
    );

    const testWorker = OperationalModel(
      id: 'asep@kawalo.id_2026-09-10',
      userEmail: 'asep@kawalo.id',
      userName: 'Asep Sunandar',
      userProfilePic: 'https://example.com/pic.jpg',
      groupName: 'Cluster Anggrek',
      latestDuty: 'Patroli Sektor 1',
      latestState: 'Aktif',
      latestDutyDt: '2026-09-10 08:00',
      latestStateDt: '2026-09-10 08:15',
      totalActivities: 1,
      dutyDate: '2026-09-10',
      timeline: [testTimeline],
    );

    test('toDutyTimelineLocal and fromDutyTimelineLocal map correctly', () {
      final local = OperationalLocalMapper.toDutyTimelineLocal(testTimeline);
      expect(local, isNotNull);

      expect(local!.id, testTimeline.id);
      expect(local.journeyUid, testTimeline.journeyUid);
      expect(local.duty, testTimeline.duty);
      expect(local.state, testTimeline.state);
      expect(local.dutyDt, testTimeline.dutyDt);
      expect(local.stateDt, testTimeline.stateDt);

      final model = OperationalLocalMapper.fromDutyTimelineLocal(local);
      expect(model, isNotNull);
      expect(model!.id, testTimeline.id);
      expect(model.duty, testTimeline.duty);
      expect(model.state, testTimeline.state);
    });

    test('toLocal maps OperationalModel to OperationalLocalModel', () {
      final collection = OperationalLocalMapper.toLocal(testWorker);
      expect(collection, isNotNull);

      expect(collection, isA<OperationalLocalModel>());
      expect(collection!.userEmail, testWorker.userEmail);
      expect(collection.userName, testWorker.userName);
      expect(collection.userProfilePic, testWorker.userProfilePic);
      expect(collection.groupName, testWorker.groupName);
      expect(collection.latestDuty, testWorker.latestDuty);
      expect(collection.latestState, testWorker.latestState);
      expect(collection.latestDutyDt, testWorker.latestDutyDt);
      expect(collection.latestStateDt, testWorker.latestStateDt);
      expect(collection.totalActivities, testWorker.totalActivities);
      expect(collection.dutyDate, testWorker.dutyDate);
      expect(collection.timeline.length, 1);
      expect(collection.timeline.first.duty, 'Patroli Sektor 1');
    });

    test('fromLocal maps OperationalLocalModel to OperationalModel', () {
      final collection = OperationalLocalMapper.toLocal(testWorker);
      expect(collection, isNotNull);
      final model = OperationalLocalMapper.fromLocal(collection!);
      expect(model, isNotNull);

      expect(model!.userEmail, testWorker.userEmail);
      expect(model.userName, testWorker.userName);
      expect(model.totalActivities, testWorker.totalActivities);
      expect(model.dutyDate, testWorker.dutyDate);
      expect(model.timeline.length, 1);
      expect(model.timeline.first.duty, 'Patroli Sektor 1');
    });

    test('toLocalList and fromLocalList map collections round-trip', () {
      final collections = OperationalLocalMapper.toLocalList([testWorker]);
      expect(collections.length, 1);

      final models = OperationalLocalMapper.fromLocalList(collections);
      expect(models.length, 1);
      expect(models.first.userEmail, testWorker.userEmail);
    });

    test('toLocal and fromLocal sanitize dirty data correctly', () {
      const dirtyWorker = OperationalModel(
        id: '  asep.sunandar@kawalo.id_2026-09-10  ',
        userEmail: '  ASEP.SUNANDAR@KAWALO.ID  ',
        userName: '  Asep Sunandar  ',
        userProfilePic: 'N/A',
        groupName: 'null',
        latestDuty: '  Patroli  ',
        latestState: 'N/A',
        latestDutyDt: '0000-00-00 00:00:00',
        latestStateDt: '1970-01-01T00:00:00.000Z',
        totalActivities: 0,
        dutyDate: '   ',
        timeline: [
          DutyTimelineModel(
            id: '  101  ',
            journeyUid: 'null',
            duty: '  Standby  ',
            state: ' - ',
            dutyDt: '0000-00-00',
            stateDt: '   ',
          ),
        ],
      );

      final local = OperationalLocalMapper.toLocal(dirtyWorker);
      expect(local, isNotNull);
      expect(local!.userEmail, 'asep.sunandar@kawalo.id');
      expect(local.userName, 'Asep Sunandar');
      expect(local.userProfilePic, isNull);
      expect(local.groupName, isNull);
      expect(local.latestDuty, 'Patroli');
      expect(local.latestState, isNull);
      expect(local.latestDutyDt, isNull);
      expect(local.latestStateDt, isNull);
      expect(local.dutyDate, isNull);
      expect(local.timeline.length, 1);
      expect(local.timeline.first.id, '101');
      expect(local.timeline.first.journeyUid, isNull);
      expect(local.timeline.first.duty, 'Standby');
      expect(local.timeline.first.state, isNull);

      final roundTrip = OperationalLocalMapper.fromLocal(local);
      expect(roundTrip, isNotNull);
      expect(roundTrip!.userEmail, 'asep.sunandar@kawalo.id');
      expect(roundTrip.userName, 'Asep Sunandar');
      expect(roundTrip.userProfilePic, isNull);
      expect(roundTrip.latestDuty, 'Patroli');
      expect(roundTrip.latestState, isNull);
      expect(roundTrip.timeline.first.duty, 'Standby');
    });

    test('toLocal and fromLocal fallback to trimmed values when uncleaned', () {
      const invalidEmailWorker = OperationalModel(
        id: 'invalid-id',
        userEmail: '   ',
        totalActivities: 0,
        timeline: [],
      );

      final local = OperationalLocalMapper.toLocal(invalidEmailWorker);
      expect(local, isNotNull);
      expect(local!.userEmail, '');

      final invalidEmailLocal = OperationalLocalModel()
        ..id = 'invalid-id'
        ..userEmail = 'N/A'
        ..totalActivities = 0;

      final model = OperationalLocalMapper.fromLocal(invalidEmailLocal);
      expect(model, isNotNull);
      expect(model!.userEmail, 'N/A');

      const invalidTimelineModel = DutyTimelineModel(
        id: '  -  ',
        duty: 'Standby',
      );
      final timelineLocal = OperationalLocalMapper.toDutyTimelineLocal(
        invalidTimelineModel,
      );
      expect(timelineLocal, isNotNull);
      expect(timelineLocal!.id, '-');

      final invalidTimelineLocal = DutyTimelineLocalModel()
        ..id = 'null'
        ..duty = 'Standby';
      final timelineModel = OperationalLocalMapper.fromDutyTimelineLocal(
        invalidTimelineLocal,
      );
      expect(timelineModel, isNotNull);
      expect(timelineModel!.id, 'null');
    });
  });
}
