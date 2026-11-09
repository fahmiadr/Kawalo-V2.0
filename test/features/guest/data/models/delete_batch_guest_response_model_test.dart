import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/delete_batch_guest_response_model.dart';

void main() {
  group('DeleteBatchGuestResponseModel Tests', () {
    test('fromJson deserializes standard backend response correctly', () {
      final model = DeleteBatchGuestResponseModel.fromJson(const {
        'deleted_count': 3,
      });

      expect(model.deletedCount, 3);
    });

    test('fromJson accepts a decimal deleted_count', () {
      final model = DeleteBatchGuestResponseModel.fromJson(const {
        'deleted_count': 3.0,
      });

      expect(model.deletedCount, 3);
    });

    test('fromJson defaults a missing or null deleted_count to 0', () {
      expect(DeleteBatchGuestResponseModel.fromJson(const {}).deletedCount, 0);
      expect(
        DeleteBatchGuestResponseModel.fromJson(const {
          'deleted_count': null,
        }).deletedCount,
        0,
      );
    });

    test('props equality compares models correctly', () {
      const model1 = DeleteBatchGuestResponseModel(deletedCount: 2);
      const model2 = DeleteBatchGuestResponseModel(deletedCount: 2);
      const model3 = DeleteBatchGuestResponseModel(deletedCount: 5);

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });
  });
}
