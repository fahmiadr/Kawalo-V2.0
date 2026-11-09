import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/mappers/master_guest_type_mapper.dart';
import 'package:kawalo_mobile/features/guest/data/models/master_guest_type_model.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';

void main() {
  group('MasterGuestTypeMapper Tests', () {
    const tModel = MasterGuestTypeModel(id: '1', uid: 'GT-001', name: 'TAMU');

    const tEntity = MasterGuestTypeEntity(id: '1', uid: 'GT-001', name: 'TAMU');

    test('toEntity maps correctly', () {
      final entity = MasterGuestTypeMapper.toEntity(tModel);
      expect(entity, tEntity);
    });

    test('toEntityList maps list correctly', () {
      final list = MasterGuestTypeMapper.toEntityList([tModel]);
      expect(list.length, 1);
      expect(list.first, tEntity);
    });

    test('toEntity cleans dirty strings', () {
      const dirtyModel = MasterGuestTypeModel(
        id: '  1  ',
        uid: '  GT-001  ',
        name: '  TAMU  ',
      );
      final entity = MasterGuestTypeMapper.toEntity(dirtyModel);
      expect(entity.id, '1');
      expect(entity.uid, 'GT-001');
      expect(entity.name, 'TAMU');
    });
  });
}
