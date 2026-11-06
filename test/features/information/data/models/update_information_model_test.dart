import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/update_information_model.dart';

void main() {
  group('UpdateInformationModel Tests', () {
    const tModel = UpdateInformationModel(
      title: 'Judul Baru',
      text: 'Isi teks baru.',
      feedFile: 'https://example.com/updated.pdf',
      photos: [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ],
      feedType: 'EVENT',
      eventLocation: 'Gedung Serbaguna',
      glat: '-6.2088',
      glong: '106.8456',
    );

    test('toJson produces correct map matching UpdateInformationDto', () {
      final json = tModel.toJson();

      expect(json['title'], 'Judul Baru');
      expect(json['text'], 'Isi teks baru.');
      expect(json['feed_file'], 'https://example.com/updated.pdf');
      expect(json['photos'], [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ]);
      expect(json['feed_type'], 'EVENT');
      expect(json['event_location'], 'Gedung Serbaguna');
      expect(json['glat'], '-6.2088');
      expect(json['glong'], '106.8456');
    });

    test('toJson omits null optional fields for partial update', () {
      const partialModel = UpdateInformationModel(
        title: 'Hanya Judul',
      );

      final json = partialModel.toJson();

      expect(json['title'], 'Hanya Judul');
      expect(json.containsKey('text'), isFalse);
      expect(json.containsKey('feed_file'), isFalse);
      expect(json.containsKey('photos'), isFalse);
      expect(json.containsKey('feed_type'), isFalse);
      expect(json.containsKey('event_location'), isFalse);
      expect(json.containsKey('glat'), isFalse);
      expect(json.containsKey('glong'), isFalse);
    });

    test(
      'toJson includes null optional fields when includeNulls is true',
      () {
        const clearModel = UpdateInformationModel(
          title: 'Judul Baru',
          feedType: 'EVENT',
          includeNulls: true,
        );

        final json = clearModel.toJson();

        expect(json['title'], 'Judul Baru');
        expect(json['feed_type'], 'EVENT');
        expect(json.containsKey('text'), isTrue);
        expect(json['text'], isNull);
        expect(json.containsKey('feed_file'), isTrue);
        expect(json['feed_file'], isNull);
        expect(json.containsKey('event_location'), isTrue);
        expect(json['event_location'], isNull);
        expect(json.containsKey('glat'), isTrue);
        expect(json['glat'], isNull);
        expect(json.containsKey('glong'), isTrue);
        expect(json['glong'], isNull);
      },
    );


    test('props supports value equality', () {
      const model1 = UpdateInformationModel(
        title: 'Info Update',
        feedType: 'GENERAL',
      );
      const model2 = UpdateInformationModel(
        title: 'Info Update',
        feedType: 'GENERAL',
      );

      expect(model1, equals(model2));
    });
  });
}
