import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/operational/data/mappers/operational_mapper.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';

void main() {
  group('OperationalMapper Tests', () {
    const tTimelineModel = DutyTimelineModel(
      id: '1',
      journeyUid: 'JRN-01',
      duty: 'Patroli',
      state: 'Selesai',
      dutyDt: '2026-09-10 08:00',
    );

    const tOperationalModel = OperationalModel(
      id: 'worker@kawalo.id_2026-09-10',
      userEmail: 'worker@kawalo.id',
      userName: 'Worker Name',
      groupName: 'Pos 1',
      latestDuty: 'Patroli',
      latestState: 'Selesai',
      latestDutyDt: '2026-09-10 08:00',
      totalActivities: 1,
      dutyDate: '2026-09-10',
      timeline: [tTimelineModel],
    );

    test(
      'toEntity maps OperationalModel to OperationalItemEntity correctly',
      () {
        final entity = OperationalMapper.toEntity(tOperationalModel);
        expect(entity, isA<OperationalItemEntity>());
        expect(entity.userEmail, tOperationalModel.userEmail);
        expect(entity.userName, tOperationalModel.userName);
        expect(entity.latestDuty, tOperationalModel.latestDuty);
        expect(entity.latestState, tOperationalModel.latestState);
        expect(entity.dutyDate, tOperationalModel.dutyDate);
        expect(entity.timeline.length, 1);
      },
    );

    test('toEntityList maps list of operational models correctly', () {
      final list = OperationalMapper.toEntityList([tOperationalModel]);
      expect(list.length, 1);
      expect(list.first.userEmail, tOperationalModel.userEmail);
    });

    test('toEntity properly sanitizes dirty data without data poisoning', () {
      const dirtyModel = OperationalModel(
        id: '  dirty.worker@kawalo.id_2026-09-10  ',
        userEmail: '  DIRTY.WORKER@KAWALO.ID  ',
        userName: '  ',
        userProfilePic: 'N/A',
        groupName: ' - ',
        latestDuty: '  ',
        latestState: 'N/A',
        latestDutyDt: '0000-00-00 00:00:00',
        latestStateDt: '1970-01-01T00:00:00.000Z',
        totalActivities: 0,
        dutyDate: '   ',
        timeline: [
          DutyTimelineModel(
            id: '  202  ',
            journeyUid: ' - ',
            duty: '  Patroli  ',
            state: 'null',
            dutyDt: '1970-01-01',
            stateDt: 'N/A',
          ),
        ],
      );

      final entity = OperationalMapper.toEntity(dirtyModel);

      // ID disanitasi
      expect(entity.id, 'dirty.worker@kawalo.id_2026-09-10');
      // Email disanitasi & di-lowercase
      expect(entity.userEmail, 'dirty.worker@kawalo.id');
      // Tidak ada poisoning dari email ke userName
      expect(entity.userName, isNull);
      expect(entity.userProfilePic, isNull);
      expect(entity.groupName, isNull);
      expect(entity.latestDuty, isNull);
      expect(entity.latestState, isNull);
      expect(entity.latestDutyDt, isNull);
      expect(entity.latestStateDt, isNull);
      expect(entity.dutyDate, isNull);
      expect(entity.totalActivities, 0);

      // Timeline disanitasi
      expect(entity.timeline.length, 1);
      expect(entity.timeline.first.id, '202');
      expect(entity.timeline.first.journeyUid, isNull);
      expect(entity.timeline.first.duty, 'Patroli');
      expect(entity.timeline.first.state, isNull);
      expect(entity.timeline.first.dutyDt, isNull);
      expect(entity.timeline.first.stateDt, isNull);
    });

    test(
      'toEntity falls back to trimmed userEmail when email format is invalid',
      () {
        const invalidEmailModel = OperationalModel(
          id: 'invalid-id',
          userEmail: 'not-an-email',
          totalActivities: 0,
          timeline: [],
        );

        final entity = OperationalMapper.toEntity(invalidEmailModel);
        expect(entity.userEmail, 'not-an-email');

        const timelineModel = DutyTimelineModel(id: '  N/A  ', duty: 'Patroli');
        final timelineEntity = OperationalMapper.toDutyTimelineEntity(
          timelineModel,
        );
        expect(timelineEntity.id, 'N/A');
      },
    );
  });
}
