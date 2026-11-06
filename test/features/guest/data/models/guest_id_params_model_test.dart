import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_id_params_model.dart';

void main() {
  group('GuestIdParamsModel', () {
    test('supports value equality', () {
      const model1 = GuestIdParamsModel(id: '123');
      const model2 = GuestIdParamsModel(id: '123');
      const model3 = GuestIdParamsModel(id: '456');

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });

    test('props contains id', () {
      const model = GuestIdParamsModel(id: '999');
      expect(model.props, equals(['999']));
    });
  });
}
