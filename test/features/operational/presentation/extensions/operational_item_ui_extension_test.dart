import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

void main() {
  group('DutyTimelineUiExtension Tests', () {
    test('displayDuty and displayState format valid values', () {
      const timeline = DutyTimelineEntity(
        id: '1',
        duty: '  ON DUTY  ',
        state: '  Patroli Aktif  ',
        dutyDt: '2026-09-10T07:00:00.000Z',
      );

      expect(timeline.displayDuty, 'ON DUTY');
      expect(timeline.displayState, 'Patroli Aktif');
      expect(timeline.isOnDuty, isTrue);
    });

    test('dutyTagVariant returns correct variants', () {
      const onDutyTimeline = DutyTimelineEntity(
        id: '1',
        duty: 'ON DUTY',
      );
      expect(
        onDutyTimeline.displayDutyTagVariant(isFirst: true),
        AppTagVariant.primary,
      );
      expect(
        onDutyTimeline.displayDutyTagVariant(),
        AppTagVariant.secondary,
      );

      const offDutyTimeline = DutyTimelineEntity(
        id: '2',
        duty: 'OFF DUTY',
      );
      expect(
        offDutyTimeline.displayDutyTagVariant(isFirst: true),
        AppTagVariant.tertiary,
      );
    });

    test('fallbacks to em-dash when values are null', () {
      const emptyTimeline = DutyTimelineEntity(id: '99');

      expect(emptyTimeline.displayDuty, '—');
      expect(emptyTimeline.displayState, '—');
      expect(emptyTimeline.displayTime, '—');
      expect(emptyTimeline.isOnDuty, isFalse);
    });
  });

  group('OperationalItemUiExtension Tests', () {
    test('displayName returns userName if present, or em-dash without fallback',
        () {
      const withName = OperationalItemEntity(
        id: 'agus@kawalo.id_2026-07-08',
        userEmail: 'agus@kawalo.id',
        userName: 'Agus Pratama',
        totalActivities: 1,
        timeline: [],
      );
      expect(withName.displayUserName, 'Agus Pratama');

      const withoutName = OperationalItemEntity(
        id: 'agus@kawalo.id_2026-07-08',
        userEmail: 'agus@kawalo.id',
        totalActivities: 1,
        timeline: [],
      );
      expect(withoutName.displayUserName, '—');
    });

    test('duty and state tag variants resolve correctly', () {
      const onDutyWorker = OperationalItemEntity(
        id: 'agus@kawalo.id_2026-07-08',
        userEmail: 'agus@kawalo.id',
        latestDuty: 'ON DUTY',
        latestState: 'Patroli Aktif',
        totalActivities: 1,
        timeline: [],
      );
      expect(onDutyWorker.isOnDuty, isTrue);
      expect(onDutyWorker.displayDutyTagVariant, AppTagVariant.primary);
      expect(onDutyWorker.displayStateTagVariant, AppTagVariant.primary);

      const offDutyWorker = OperationalItemEntity(
        id: 'agus@kawalo.id_2026-07-08',
        userEmail: 'agus@kawalo.id',
        latestDuty: 'OFF DUTY',
        latestState: 'Selesai Tugas',
        totalActivities: 1,
        timeline: [],
      );
      expect(offDutyWorker.isOnDuty, isFalse);
      expect(offDutyWorker.displayDutyTagVariant, AppTagVariant.tertiary);
      expect(offDutyWorker.displayStateTagVariant, AppTagVariant.tertiary);
    });

    test('resolveStateTagVariant handles all defined status categories', () {
      expect(
        OperationalItemUiExtension.resolveStateTagVariant('Patroli Berjalan'),
        AppTagVariant.primary,
      );
      expect(
        OperationalItemUiExtension.resolveStateTagVariant('Selesai'),
        AppTagVariant.tertiary,
      );
      expect(
        OperationalItemUiExtension.resolveStateTagVariant('Siaga Pos 1'),
        AppTagVariant.secondary,
      );
      expect(
        OperationalItemUiExtension.resolveStateTagVariant('Keadaan Darurat'),
        AppTagVariant.error,
      );
      expect(
        OperationalItemUiExtension.resolveStateTagVariant(null),
        AppTagVariant.secondary,
      );
    });

    test('display getters provide em-dash fallback when values are null', () {
      const emptyWorker = OperationalItemEntity(
        id: 'empty@kawalo.id_2026-07-08',
        userEmail: 'empty@kawalo.id',
        totalActivities: 0,
        timeline: [],
      );

      expect(emptyWorker.displayGroupName, '—');
      expect(emptyWorker.displayLatestDuty, '—');
      expect(emptyWorker.displayLatestState, '—');
      expect(emptyWorker.displayLatestTime, '—');
      expect(emptyWorker.displayLatestStateTime, '—');
      expect(emptyWorker.displayFirstActivityTime, '—');
      expect(emptyWorker.displayTotalActivities, '0');
    });
  });
}
