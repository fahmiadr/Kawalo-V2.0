import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_response_model.dart';

void main() {
  group('DeleteBatchInformationResponseModel Tests', () {
    test('fromJson deserializes standard backend response correctly', () {
      final json = {'deleted_count': 3};
      final model = DeleteBatchInformationResponseModel.fromJson(json);

      expect(model.deletedCount, 3);
    });

    test('props equality compares models correctly', () {
      const model1 = DeleteBatchInformationResponseModel(deletedCount: 2);
      const model2 = DeleteBatchInformationResponseModel(deletedCount: 2);
      const model3 = DeleteBatchInformationResponseModel(deletedCount: 5);

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });

    test('fromJson accepts a decimal deleted_count', () {
      const json = {'deleted_count': 3.0};
      final model = DeleteBatchInformationResponseModel.fromJson(json);

      expect(model.deletedCount, 3);
    });

    test('fromJson defaults a missing or null deleted_count to 0', () {
      const missing = <String, dynamic>{};
      const nulled = {'deleted_count': null};

      expect(
        DeleteBatchInformationResponseModel.fromJson(missing).deletedCount,
        0,
      );
      expect(
        DeleteBatchInformationResponseModel.fromJson(nulled).deletedCount,
        0,
      );
    });
  });
}
