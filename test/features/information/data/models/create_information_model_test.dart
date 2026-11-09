import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/create_information_model.dart';

void main() {
  group('CreateInformationModel Tests', () {
    const tModel = CreateInformationModel(
      title: 'Pemberitahuan Kerja Bakti',
      text: 'Kerja bakti bersama warga RT 01.',
      feedFile: 'https://example.com/file.pdf',
      photos: [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ],
      feedType: 'EVENT',
      eventLocation: 'Lapangan RW 02',
      glat: '-6.2088',
      glong: '106.8456',
    );

    test('toJson produces correct map matching CreateInformationDto', () {
      final json = tModel.toJson();

      expect(json['title'], 'Pemberitahuan Kerja Bakti');
      expect(json['text'], 'Kerja bakti bersama warga RT 01.');
      expect(json['feed_file'], 'https://example.com/file.pdf');
      expect(json['photos'], [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ]);
      expect(json['feed_type'], 'EVENT');
      expect(json['event_location'], 'Lapangan RW 02');
      expect(json['glat'], '-6.2088');
      expect(json['glong'], '106.8456');
    });

    test('toJson omits null optional fields', () {
      const minimalModel = CreateInformationModel(title: 'Info Singkat');

      final json = minimalModel.toJson();

      expect(json['title'], 'Info Singkat');
      expect(json.containsKey('text'), isFalse);
      expect(json.containsKey('feed_file'), isFalse);
      expect(json.containsKey('photos'), isFalse);
      expect(json.containsKey('feed_type'), isFalse);
      expect(json.containsKey('event_location'), isFalse);
      expect(json.containsKey('glat'), isFalse);
      expect(json.containsKey('glong'), isFalse);
    });

    test('props supports value equality', () {
      const model1 = CreateInformationModel(
        title: 'Info A',
        feedType: 'GENERAL',
      );
      const model2 = CreateInformationModel(
        title: 'Info A',
        feedType: 'GENERAL',
      );

      expect(model1, equals(model2));
    });
  });
}
