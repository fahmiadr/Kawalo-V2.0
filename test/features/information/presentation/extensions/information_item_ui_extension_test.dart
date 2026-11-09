import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';

void main() {
  group('InformationItemUiExtension Tests', () {
    test(
      'displayUserName and displayUserEmail format correctly with fallback',
      () {
        const withBoth = InformationItemEntity(
          id: '1',
          photos: [],
          userName: 'Budi Santoso',
          userEmail: 'budi@kawalo.id',
        );
        expect(withBoth.displayUserName, 'Budi Santoso');
        expect(withBoth.displayUserEmail, 'budi@kawalo.id');

        const withNeither = InformationItemEntity(id: '2', photos: []);
        expect(withNeither.displayUserName, '—');
        expect(withNeither.displayUserEmail, '—');
      },
    );

    test('typeLabel and typeVariant map all categories correctly', () {
      const incident = InformationItemEntity(
        id: '1',
        photos: [],
        feedType: 'INCIDENT',
      );
      expect(incident.typeLabel, 'Insiden');
      expect(incident.typeVariant, AppTagVariant.error);

      const event = InformationItemEntity(
        id: '2',
        photos: [],
        feedType: 'EVENT',
      );
      expect(event.typeLabel, 'Acara');
      expect(event.typeVariant, AppTagVariant.primary);

      const join = InformationItemEntity(id: '3', photos: [], feedType: 'JOIN');
      expect(join.typeLabel, 'Personil Baru');
      expect(join.typeVariant, AppTagVariant.tertiary);

      const general = InformationItemEntity(
        id: '4',
        photos: [],
        feedType: 'GENERAL',
      );
      expect(general.typeLabel, 'Informasi Umum');
      expect(general.typeVariant, AppTagVariant.secondary);

      const nullType = InformationItemEntity(id: '5', photos: []);
      expect(nullType.typeLabel, 'Informasi Umum');
      expect(nullType.typeVariant, AppTagVariant.secondary);
    });

    test('photos getters calculate correctly', () {
      const noPhotos = InformationItemEntity(id: '1', photos: []);
      expect(noPhotos.primaryPhoto, isNull);
      expect(noPhotos.hasPhotos, isFalse);
      expect(noPhotos.extraPhotosCount, 0);

      const singlePhoto = InformationItemEntity(
        id: '2',
        photos: ['photo1.jpg'],
      );
      expect(singlePhoto.primaryPhoto, 'photo1.jpg');
      expect(singlePhoto.hasPhotos, isTrue);
      expect(singlePhoto.extraPhotosCount, 0);

      const multiPhotos = InformationItemEntity(
        id: '3',
        photos: ['p1.jpg', 'p2.jpg', 'p3.jpg'],
      );
      expect(multiPhotos.primaryPhoto, 'p1.jpg');
      expect(multiPhotos.hasPhotos, isTrue);
      expect(multiPhotos.extraPhotosCount, 2);
    });

    test(
      'displayEventSchedule formats same day and different day schedules',
      () {
        const sameDay = InformationItemEntity(
          id: '1',
          photos: [],
          eventStartDt: '2026-09-12 10:00',
          eventEndDt: '2026-09-12 12:00',
        );
        expect(sameDay.displayEventSchedule, contains('10:00 – 12:00'));

        const nullSchedule = InformationItemEntity(id: '2', photos: []);
        expect(nullSchedule.displayEventSchedule, isNull);
      },
    );

    test('hasFileAttachment identifies valid and invalid file attachments', () {
      const withValidFile = InformationItemEntity(
        id: '1',
        photos: [],
        feedFile: 'laporan_harian.pdf',
      );
      expect(withValidFile.hasFileAttachment, isTrue);

      const withNullFile = InformationItemEntity(id: '2', photos: []);
      expect(withNullFile.hasFileAttachment, isFalse);

      const withNaFile = InformationItemEntity(
        id: '3',
        photos: [],
        feedFile: 'N/A',
      );
      expect(withNaFile.hasFileAttachment, isFalse);

      const withEmptyFile = InformationItemEntity(
        id: '4',
        photos: [],
        feedFile: '   ',
      );
      expect(withEmptyFile.hasFileAttachment, isFalse);

      const withDashFile = InformationItemEntity(
        id: '5',
        photos: [],
        feedFile: '-',
      );
      expect(withDashFile.hasFileAttachment, isFalse);
    });

    test('display getters return em-dash for null values', () {
      const emptyItem = InformationItemEntity(id: '1', photos: []);
      expect(emptyItem.displayTitle, '—');
      expect(emptyItem.displayText, '—');
      expect(emptyItem.displayUserEmail, '—');
      expect(emptyItem.displayUserName, '—');
      expect(emptyItem.displayEventLocation, '—');
      expect(emptyItem.displayGroupName, '—');
      expect(emptyItem.displayFeedFile, '—');
      expect(emptyItem.displayFeedDt, '—');
    });
  });
}
