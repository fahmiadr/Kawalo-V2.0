import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/mappers/information_mapper.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_response_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';

void main() {
  group('InformationMapper Tests', () {
    const testModel = InformationModel(
      id: 'INFO-101',
      photos: ['https://example.com/pic1.jpg', 'https://example.com/pic2.jpg'],
      title: 'Patroli Lingkungan Barat',
      text: 'Pemeriksaan pos keamanan berjalan lancar.',
      userEmail: 'budi@kawalo.id',
      userName: 'Budi Santoso',
      userProfilePic: 'https://example.com/avatar.jpg',
      feedDt: '2026-09-10T07:10:00.000Z',
      feedFile: 'lampiran.pdf',
      feedType: 'PATROL',
      groupName: 'Cluster Edelweiss',
      eventLocation: 'Pos 1 Barat',
      eventStartDt: '2026-09-10T08:00:00.000Z',
      eventEndDt: '2026-09-10T10:00:00.000Z',
      eventDuration: 2,
      glat: '-6.2088',
      glong: '106.8456',
    );

    test('toEntity accurately maps all fields from Model to Entity', () {
      final entity = InformationMapper.toEntity(testModel);

      expect(entity, isA<InformationItemEntity>());
      expect(entity.id, testModel.id);
      expect(entity.photos, testModel.photos);
      expect(entity.title, testModel.title);
      expect(entity.text, testModel.text);
      expect(entity.userEmail, testModel.userEmail);
      expect(entity.userName, testModel.userName);
      expect(entity.userProfilePic, testModel.userProfilePic);
      expect(entity.feedDt, testModel.feedDt);
      expect(entity.feedFile, testModel.feedFile);
      expect(entity.feedType, testModel.feedType);
      expect(entity.groupName, testModel.groupName);
      expect(entity.eventLocation, testModel.eventLocation);
      expect(entity.eventStartDt, testModel.eventStartDt);
      expect(entity.eventEndDt, testModel.eventEndDt);
      expect(entity.eventDuration, testModel.eventDuration);
      expect(entity.glat, -6.2088);
      expect(entity.glong, 106.8456);
    });

    test('toEntityList maps a list of models to entities', () {
      final entities = InformationMapper.toEntityList([testModel]);

      expect(entities.length, 1);
      expect(entities.first.id, testModel.id);
    });

    test('toEntity properly sanitizes dirty data without fallback', () {
      const dirtyModel = InformationModel(
        id: '  INFO-DIRTY-99  ',
        photos: ['  valid.jpg  ', 'N/A', ''],
        title: '  ',
        text: 'N/A',
        userEmail: '  TESTER@KAWALO.ID  ',
        feedDt: '1970-01-01 00:00:00',
        glat: '0.000000',
        glong: '0',
      );

      final entity = InformationMapper.toEntity(dirtyModel);

      expect(entity.id, 'INFO-DIRTY-99');
      expect(entity.photos, ['valid.jpg']);
      expect(entity.title, isNull);
      expect(entity.text, isNull);
      expect(entity.userEmail, 'tester@kawalo.id');
      expect(entity.feedDt, isNull);
      expect(entity.glat, isNull);
      expect(entity.glong, isNull);
    });

    test(
      'toDeleteBatchResult accurately maps deletedCount from DTO '
      'to Value Object',
      () {
        const dto = DeleteBatchInformationResponseModel(deletedCount: 5);
        final entity = InformationMapper.toDeleteBatchResult(dto);

        expect(entity, isA<DeleteBatchResult>());
        expect(entity.deletedCount, 5);
      },
    );
  });
}
