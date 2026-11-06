import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';

void main() {
  group('DutyTimelineModel Tests', () {
    final tTimelineJson = {
      'id': '101',
      'journey_uid': 'JRN-01',
      'duty': 'Patroli Sektor 1',
      'state': 'Selesai',
      'duty_dt': '2026-09-10 08:00',
      'state_dt': '2026-09-10 09:00',
    };

    test('fromJson creates a valid DutyTimelineModel instance', () {
      final model = DutyTimelineModel.fromJson(tTimelineJson);

      expect(model.id, '101');
      expect(model.journeyUid, 'JRN-01');
      expect(model.duty, 'Patroli Sektor 1');
      expect(model.state, 'Selesai');
      expect(model.dutyDt, '2026-09-10 08:00');
      expect(model.stateDt, '2026-09-10 09:00');
    });

    test('props equality compares models correctly', () {
      final m1 = DutyTimelineModel.fromJson(tTimelineJson);
      final m2 = DutyTimelineModel.fromJson(tTimelineJson);

      expect(m1, equals(m2));
    });
  });

  group('OperationalModel Tests', () {
    final tWorkerJson = {
      'id': 'asep@kawalo.id_2026-09-10',
      'user_email': 'asep@kawalo.id',
      'user_name': 'Asep Sunandar',
      'user_profile_pic': 'https://example.com/pic.jpg',
      'group_name': 'Cluster Anggrek',
      'latest_duty': 'Patroli Utama',
      'latest_state': 'Aktif',
      'latest_duty_dt': '2026-09-10 08:00',
      'latest_state_dt': '2026-09-10 08:15',
      'total_activities': 1,
      'duty_date': '2026-09-10',
      'timeline': [
        {
          'id': '101',
          'journey_uid': 'JRN-01',
          'duty': 'Patroli Utama',
          'state': 'Aktif',
          'duty_dt': '2026-09-10 08:00',
          'state_dt': '2026-09-10 08:15',
        },
      ],
    };

    test('fromJson creates a valid OperationalModel instance', () {
      final model = OperationalModel.fromJson(tWorkerJson);

      expect(model.id, 'asep@kawalo.id_2026-09-10');
      expect(model.userEmail, 'asep@kawalo.id');
      expect(model.userName, 'Asep Sunandar');
      expect(model.latestDuty, 'Patroli Utama');
      expect(model.totalActivities, 1);
      expect(model.timeline.length, 1);
      expect(model.timeline.first.duty, 'Patroli Utama');
    });

    test('props equality compares models correctly', () {
      final m1 = OperationalModel.fromJson(tWorkerJson);
      final m2 = OperationalModel.fromJson(tWorkerJson);

      expect(m1, equals(m2));
    });
  });
}
