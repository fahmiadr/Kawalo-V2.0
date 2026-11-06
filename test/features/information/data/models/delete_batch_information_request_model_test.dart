import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_request_model.dart';

void main() {
  group('DeleteBatchInformationRequestModel Tests', () {
    const tModel = DeleteBatchInformationRequestModel(ids: ['1', '2']);

    test('toJson serializes correctly to API payload format', () {
      final json = tModel.toJson();
      expect(json, {
        'ids': ['1', '2'],
      });
    });

    test('props equality compares models correctly', () {
      const model1 = DeleteBatchInformationRequestModel(ids: ['1', '2']);
      const model2 = DeleteBatchInformationRequestModel(ids: ['1', '2']);
      const model3 = DeleteBatchInformationRequestModel(ids: ['3']);

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });
  });
}
