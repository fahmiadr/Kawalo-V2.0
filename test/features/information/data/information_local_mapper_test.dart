import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/mappers/information_local_mapper.dart';
import 'package:kawalo_mobile/features/information/data/models/information_local_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';

void main() {
  group('InformationLocalMapper Tests', () {
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

    test('toLocal maps InformationModel to InformationLocalModel', () {
      final collection = InformationLocalMapper.toLocal(testModel);

      expect(collection, isA<InformationLocalModel>());
      expect(collection.id, testModel.id);
      expect(collection.photos, testModel.photos);
      expect(collection.title, testModel.title);
      expect(collection.text, testModel.text);
      expect(collection.userEmail, testModel.userEmail);
      expect(collection.userName, testModel.userName);
      expect(collection.userProfilePic, testModel.userProfilePic);
      expect(collection.feedDt, testModel.feedDt);
      expect(collection.feedFile, testModel.feedFile);
      expect(collection.feedType, testModel.feedType);
      expect(collection.groupName, testModel.groupName);
      expect(collection.eventLocation, testModel.eventLocation);
      expect(collection.eventStartDt, testModel.eventStartDt);
      expect(collection.eventEndDt, testModel.eventEndDt);
      expect(collection.eventDuration, testModel.eventDuration);
      expect(collection.glat, testModel.glat);
      expect(collection.glong, testModel.glong);
    });

    test('fromLocal maps InformationLocalModel to InformationModel', () {
      final collection = InformationLocalMapper.toLocal(testModel);
      final model = InformationLocalMapper.fromLocal(collection);

      expect(model.id, testModel.id);
      expect(model.photos, testModel.photos);
      expect(model.title, testModel.title);
      expect(model.text, testModel.text);
      expect(model.userEmail, testModel.userEmail);
      expect(model.userName, testModel.userName);
      expect(model.groupName, testModel.groupName);
    });

    test('toLocalList and fromLocalList map lists correctly', () {
      final collections = InformationLocalMapper.toLocalList([testModel]);
      expect(collections, hasLength(1));

      final models = InformationLocalMapper.fromLocalList(collections);
      expect(models, hasLength(1));
      expect(models.first.id, testModel.id);
    });

    test('sanitizes dirty inputs when mapping without fallback', () {
      const dirtyModel = InformationModel(
        id: '  INFO-102  ',
        photos: ['  valid.jpg  ', 'N/A', ''],
        title: '  ',
        text: 'N/A',
        userEmail: '  USER@TEST.COM  ',
        feedDt: '0000-00-00 00:00:00',
        glat: '0.000000',
        glong: '0',
      );

      final collection = InformationLocalMapper.toLocal(dirtyModel);
      expect(collection.id, 'INFO-102');
      expect(collection.photos, ['valid.jpg']);
      expect(collection.title, isNull);
      expect(collection.text, isNull);
      expect(collection.userEmail, 'user@test.com');
      expect(collection.feedDt, isNull);
      expect(collection.glat, isNull);
      expect(collection.glong, isNull);
    });
  });
}
