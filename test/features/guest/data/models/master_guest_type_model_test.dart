import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/master_guest_type_model.dart';

void main() {
  group('MasterGuestTypeModel Tests', () {
    test('fromJson deserializes correctly', () {
      final json = {'id': '2', 'uid': 'GT-002', 'name': 'KURIR'};

      final model = MasterGuestTypeModel.fromJson(json);

      expect(model.id, '2');
      expect(model.uid, 'GT-002');
      expect(model.name, 'KURIR');
    });
  });
}
