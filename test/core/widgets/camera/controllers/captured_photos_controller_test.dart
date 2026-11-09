import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/widgets/camera/controllers/captured_photos_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const a = AppMediaFile(name: 'a.jpg', path: '/a.jpg');
  const b = AppMediaFile(name: 'b.jpg', path: '/b.jpg');
  const c = AppMediaFile(name: 'c.jpg', path: '/c.jpg');

  late CapturedPhotosController controller;

  setUp(() => controller = CapturedPhotosController());

  test('addCaptured inserts at the front and selects while quota remains', () {
    controller
      ..addCaptured(a, maxSelectable: 2)
      ..addCaptured(b, maxSelectable: 2)
      ..addCaptured(c, maxSelectable: 2);

    expect(controller.captured, [c, b, a]);
    expect(controller.selected, [a, b]);
  });

  test('toggleSelection rejects selection when quota is full', () {
    controller
      ..captured.addAll([a, b])
      ..selected.add(a);

    expect(controller.toggleSelection(b, maxSelectable: 1), isFalse);
    expect(controller.selected, [a]);
    expect(controller.toggleSelection(a, maxSelectable: 1), isTrue);
    expect(controller.selected, isEmpty);
    expect(controller.toggleSelection(b, maxSelectable: 1), isTrue);
    expect(controller.selected, [b]);
  });

  test('removeNow drops the photo from both lists', () {
    controller
      ..captured.addAll([a, b])
      ..selected.addAll([a, b])
      ..removeNow(0);

    expect(controller.captured, [b]);
    expect(controller.selected, [b]);
  });

  test('beginRemoval deselects first, finishRemoval removes the item', () {
    controller
      ..captured.addAll([a, b])
      ..selected.addAll([a, b])
      ..beginRemoval(a);

    expect(controller.removingPath, a.path);
    expect(controller.selected, [b]);
    expect(controller.captured, [a, b]);

    controller.finishRemoval(a);

    expect(controller.removingPath, isNull);
    expect(controller.captured, [b]);
  });

  test('finishRemoval keeps removingPath when another photo is leaving', () {
    controller
      ..captured.addAll([a, b])
      ..beginRemoval(b)
      ..finishRemoval(a);

    expect(controller.removingPath, b.path);
  });

  test('cleanupUnsubmitted deletes files and clears both lists', () {
    final dir = Directory.systemTemp.createTempSync('captured_photos_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/x.jpg')..writeAsStringSync('x');
    final photo = AppMediaFile(name: 'x.jpg', path: file.path);
    const noPath = AppMediaFile(name: 'nopath.jpg');

    controller
      ..captured.addAll([photo, noPath])
      ..selected.add(photo)
      ..cleanupUnsubmitted();

    expect(file.existsSync(), isFalse);
    expect(controller.captured, isEmpty);
    expect(controller.selected, isEmpty);
  });
}
