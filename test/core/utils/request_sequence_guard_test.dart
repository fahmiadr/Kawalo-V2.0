import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/request_sequence_guard.dart';

class TestController with RequestSequenceGuard {}

void main() {
  group('RequestSequenceGuard Unit Tests', () {
    late TestController controller;

    setUp(() {
      controller = TestController();
    });

    test('nextRequestId menghasilkan ID berurutan secara incremental', () {
      expect(controller.nextRequestId(), 1);
      expect(controller.nextRequestId(), 2);
      expect(controller.nextRequestId(), 3);
    });

    test(
      'isLatest hanya bernilai true untuk request ID yang paling mutakhir',
      () {
        final req1 = controller.nextRequestId();
        expect(controller.isLatest(req1), isTrue);

        final req2 = controller.nextRequestId();
        expect(controller.isLatest(req1), isFalse);
        expect(controller.isLatest(req2), isTrue);
      },
    );

    test('invalidateRequests menggugurkan seluruh request sebelumnya', () {
      final req = controller.nextRequestId();
      expect(controller.isLatest(req), isTrue);

      controller.invalidateRequests();
      expect(controller.isLatest(req), isFalse);
    });

    test('dua instance controller memiliki counter request terisolasi secara '
        'mandiri', () {
      final controller2 = TestController();

      final reqA = controller.nextRequestId();
      final reqB = controller2.nextRequestId();

      expect(reqA, 1);
      expect(reqB, 1);
      expect(controller.isLatest(reqA), isTrue);
      expect(controller2.isLatest(reqB), isTrue);
    });
  });
}
