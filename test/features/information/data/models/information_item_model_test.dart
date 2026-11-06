import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';

void main() {
  group('InformationModel Tests', () {
    final tJson = <String, dynamic>{
      'id': '42',
      'title': 'Uji Coba Laporan Posko',
      'text': 'Laporan detail kegiatan personil.',
      'user_email': 'budi@kawalo.id',
      'user_name': 'Budi Santoso',
      'user_profile_pic': 'https://example.com/avatar.png',
      'feed_dt': '2026-09-12 10:30:00',
      'feed_file': 'lampiran.pdf',
      'photos': [
        'https://example.com/pic1.jpg',
        'https://example.com/pic2.jpg',
        'https://example.com/pic3.jpg',
        'https://example.com/pic4.jpg',
      ],
      'feed_type': 'INCIDENT',
      'group_name': 'Kompleks Sakura',
      'event_location': 'Pos Timur',
      'event_start_dt': '2026-09-12 10:00',
      'event_end_dt': '2026-09-12 12:00',
      'event_duration': 2,
      'glat': '-6.200000',
      'glong': '106.816666',
    };

    test('fromJson deserializes all fields correctly', () {
      final model = InformationModel.fromJson(tJson);

      expect(model.id, '42');
      expect(model.title, 'Uji Coba Laporan Posko');
      expect(model.text, 'Laporan detail kegiatan personil.');
      expect(model.userEmail, 'budi@kawalo.id');
      expect(model.userName, 'Budi Santoso');
      expect(model.feedType, 'INCIDENT');
      expect(model.groupName, 'Kompleks Sakura');
      expect(model.photos.length, 4);
      expect(model.glat, '-6.200000');
      expect(model.glong, '106.816666');
    });

    test('fromJson deserializes user_* fields with priority', () {
      final userJson = <String, dynamic>{
        'id': '43',
        'title': 'Uji Coba User JSON',
        'user_email': 'user@kawalo.id',
        'user_name': 'User Name',
        'user_profile_pic': 'https://example.com/pic.png',
        'photos': <String>[],
      };

      final model = InformationModel.fromJson(userJson);

      expect(model.userEmail, 'user@kawalo.id');
      expect(model.userName, 'User Name');
      expect(model.userProfilePic, 'https://example.com/pic.png');
    });

    test('handles fallback when photos and optional fields are empty', () {
      final emptyJson = <String, dynamic>{
        'id': '1',
        'title': 'Laporan Singkat',
        'photos': <String>[],
      };

      final model = InformationModel.fromJson(emptyJson);

      expect(model.id, '1');
      expect(model.title, 'Laporan Singkat');
      expect(model.photos, isEmpty);
      expect(model.glat, isNull);
      expect(model.glong, isNull);
    });
  });
}
