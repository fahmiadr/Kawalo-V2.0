import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/information_id_params_model.dart';

void main() {
  group('InformationIdParamsModel Tests', () {
    const tId = '101';
    const tModel = InformationIdParamsModel(id: tId);

    test('stores id property correctly as pure path parameter DTO', () {
      expect(tModel.id, '101');
    });

    test('props equality compares models correctly', () {
      const model1 = InformationIdParamsModel(id: '101');
      const model2 = InformationIdParamsModel(id: '101');
      const model3 = InformationIdParamsModel(id: '102');

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });
  });
}
