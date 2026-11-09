import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kawalo_mobile/core/utils/image_crop_utils.dart';

void main() {
  group('ImageCropUtils Unit Tests', () {
    test('returns false when file does not exist', () async {
      final result = await ImageCropUtils.cropFileTo9x16(
        '/non/existent/file.jpg',
      );
      expect(result, isFalse);
    });

    test(
      'returns false gracefully when file contains non-image bytes',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/dummy.jpg')
          ..writeAsBytesSync([1, 2, 3, 4]);

        final result = await ImageCropUtils.cropFileTo9x16(tempFile.path);
        expect(result, isFalse);

        tempDir.deleteSync(recursive: true);
      },
    );

    test('crops a square 1:1 image to 9:16 aspect ratio', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/square.jpg');

      // Buat citra 900x900
      final squareImg = img.Image(width: 900, height: 900);
      img.fill(squareImg, color: img.ColorRgb8(255, 0, 0));
      tempFile.writeAsBytesSync(img.encodeJpg(squareImg));

      final result = await ImageCropUtils.cropFileTo9x16(tempFile.path);
      expect(result, isTrue);

      final croppedBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(croppedBytes);
      expect(decoded, isNotNull);

      // Tinggi harus tetap 900, lebar harus menjadi (900 * 9 / 16) = 506
      expect(decoded!.height, equals(900));
      expect(decoded.width, equals(506));
      final aspect = decoded.width / decoded.height;
      expect((aspect - (9 / 16)).abs() < 0.01, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test('crops a 3:4 portrait image to 9:16 aspect ratio', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/portrait_4_3.jpg');

      // Buat citra 1200 lebar x 1600 tinggi (rasio 3:4 = 0.75)
      final portraitImg = img.Image(width: 1200, height: 1600);
      img.fill(portraitImg, color: img.ColorRgb8(0, 255, 0));
      tempFile.writeAsBytesSync(img.encodeJpg(portraitImg));

      final result = await ImageCropUtils.cropFileTo9x16(tempFile.path);
      expect(result, isTrue);

      final croppedBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(croppedBytes);
      expect(decoded, isNotNull);

      // Tinggi harus tetap 1600, lebar harus menjadi (1600 * 9 / 16) = 900
      expect(decoded!.height, equals(1600));
      expect(decoded.width, equals(900));
      final aspect = decoded.width / decoded.height;
      expect((aspect - (9 / 16)).abs() < 0.001, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test('preserves image if already 9:16 aspect ratio', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/already_9_16.jpg');

      // Buat citra 900 x 1600 (persis 9:16)
      final image9x16 = img.Image(width: 900, height: 1600);
      img.fill(image9x16, color: img.ColorRgb8(0, 0, 255));
      final originalJpgBytes = img.encodeJpg(image9x16);
      tempFile.writeAsBytesSync(originalJpgBytes);

      final result = await ImageCropUtils.cropFileTo9x16(tempFile.path);
      expect(result, isTrue);

      final resultBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(resultBytes);
      expect(decoded!.width, equals(900));
      expect(decoded.height, equals(1600));

      tempDir.deleteSync(recursive: true);
    });

    test(
      'crops 4:3 and downscales when dimensions exceed maxHeight boundary',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/large_4_3.jpg');

        // Citra 1500 x 2000 (tinggi 2000 melebihi boundary 1920)
        final largeImg = img.Image(width: 1500, height: 2000);
        img.fill(largeImg, color: img.ColorRgb8(100, 100, 100));
        tempFile.writeAsBytesSync(img.encodeJpg(largeImg));

        final result = await ImageCropUtils.cropFileTo9x16(tempFile.path);
        expect(result, isTrue);

        final croppedBytes = tempFile.readAsBytesSync();
        final decoded = img.decodeImage(croppedBytes);
        expect(decoded, isNotNull);
        expect(decoded!.height, equals(1920));
        expect(decoded.width, equals(1080));
        final aspect = decoded.width / decoded.height;
        expect((aspect - (9 / 16)).abs() < 0.001, isTrue);

        tempDir.deleteSync(recursive: true);
      },
    );

    test('preserves 16:9 landscape aspect ratio when orientation is '
        'landscapeLeft', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/landscape_16_9.jpg');

      // Citra 1600 lebar x 900 tinggi (16:9)
      final landscapeImg = img.Image(width: 1600, height: 900);
      img.fill(landscapeImg, color: img.ColorRgb8(120, 120, 0));
      tempFile.writeAsBytesSync(img.encodeJpg(landscapeImg));

      final result = await ImageCropUtils.cropFileTo9x16(
        tempFile.path,
        orientation: DeviceOrientation.landscapeLeft,
      );
      expect(result, isTrue);

      final croppedBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(croppedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1600));
      expect(decoded.height, equals(900));
      final aspect = decoded.width / decoded.height;
      expect((aspect - (16 / 9)).abs() < 0.001, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test(
      'crops 4:3 landscape image to 16:9 when orientation is landscapeRight',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/landscape_4_3.jpg');

        // Citra 1600 lebar x 1200 tinggi (4:3)
        final landscapeImg = img.Image(width: 1600, height: 1200);
        img.fill(landscapeImg, color: img.ColorRgb8(0, 120, 120));
        tempFile.writeAsBytesSync(img.encodeJpg(landscapeImg));

        final result = await ImageCropUtils.cropFileTo9x16(
          tempFile.path,
          orientation: DeviceOrientation.landscapeRight,
        );
        expect(result, isTrue);

        final croppedBytes = tempFile.readAsBytesSync();
        final decoded = img.decodeImage(croppedBytes);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(1600));
        expect(decoded.height, equals(900));
        final aspect = decoded.width / decoded.height;
        expect((aspect - (16 / 9)).abs() < 0.001, isTrue);

        tempDir.deleteSync(recursive: true);
      },
    );

    test('rotates and crops portrait sensor image to 16:9 when orientation is '
        'landscapeLeft', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/sensor_landscape_left.jpg');

      // Citra portrait dari sensor (1200 lebar x 1600 tinggi)
      final portraitImg = img.Image(width: 1200, height: 1600);
      img.fill(portraitImg, color: img.ColorRgb8(10, 20, 30));
      tempFile.writeAsBytesSync(img.encodeJpg(portraitImg));

      final result = await ImageCropUtils.cropFileTo9x16(
        tempFile.path,
        orientation: DeviceOrientation.landscapeLeft,
      );
      expect(result, isTrue);

      final croppedBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(croppedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1600));
      expect(decoded.height, equals(900));
      final aspect = decoded.width / decoded.height;
      expect((aspect - (16 / 9)).abs() < 0.001, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test('rotates and crops portrait sensor image to 16:9 when orientation is '
        'landscapeRight', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/sensor_landscape_right.jpg');

      // Citra portrait dari sensor (1200 lebar x 1600 tinggi)
      final portraitImg = img.Image(width: 1200, height: 1600);
      img.fill(portraitImg, color: img.ColorRgb8(40, 50, 60));
      tempFile.writeAsBytesSync(img.encodeJpg(portraitImg));

      final result = await ImageCropUtils.cropFileTo9x16(
        tempFile.path,
        orientation: DeviceOrientation.landscapeRight,
      );
      expect(result, isTrue);

      final croppedBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(croppedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1600));
      expect(decoded.height, equals(900));
      final aspect = decoded.width / decoded.height;
      expect((aspect - (16 / 9)).abs() < 0.001, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test('rotates and crops portrait sensor image to 9:16 when orientation is '
        'portraitDown', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/sensor_portrait_down.jpg');

      // Citra portrait dari sensor (1200 lebar x 1600 tinggi)
      final portraitImg = img.Image(width: 1200, height: 1600);
      img.fill(portraitImg, color: img.ColorRgb8(70, 80, 90));
      tempFile.writeAsBytesSync(img.encodeJpg(portraitImg));

      final result = await ImageCropUtils.cropFileTo9x16(
        tempFile.path,
        orientation: DeviceOrientation.portraitDown,
      );
      expect(result, isTrue);

      final croppedBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(croppedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(900));
      expect(decoded.height, equals(1600));
      final aspect = decoded.width / decoded.height;
      expect((aspect - (9 / 16)).abs() < 0.001, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test('rotationAngleFor returns calibrated angle for front and rear', () {
      // Portrait Up (0 deg)
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.portraitUp,
          isHeightGreaterThanWidth: true,
        ),
        isNull,
      );
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.portraitUp,
          isHeightGreaterThanWidth: true,
          isFrontCamera: true,
        ),
        isNull,
      );

      // Portrait Down (180 deg)
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.portraitDown,
          isHeightGreaterThanWidth: true,
        ),
        equals(180),
      );
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.portraitDown,
          isHeightGreaterThanWidth: true,
          isFrontCamera: true,
        ),
        equals(180),
      );

      // Landscape Left (Rear = 270, Front = 90)
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.landscapeLeft,
          isHeightGreaterThanWidth: true,
        ),
        equals(270),
      );
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.landscapeLeft,
          isHeightGreaterThanWidth: true,
          isFrontCamera: true,
        ),
        equals(90),
      );

      // Landscape Right (Rear = 90, Front = 270)
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.landscapeRight,
          isHeightGreaterThanWidth: true,
        ),
        equals(90),
      );
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.landscapeRight,
          isHeightGreaterThanWidth: true,
          isFrontCamera: true,
        ),
        equals(270),
      );

      // Not height greater than width
      expect(
        ImageCropUtils.rotationAngleFor(
          orientation: DeviceOrientation.landscapeLeft,
          isHeightGreaterThanWidth: false,
        ),
        isNull,
      );
    });

    test(
      'rotates and crops front camera portrait sensor to 16:9 in landscapeLeft',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/front_landscape_left.jpg');

        final portraitImg = img.Image(width: 1200, height: 1600);
        img.fill(portraitImg, color: img.ColorRgb8(10, 20, 30));
        tempFile.writeAsBytesSync(img.encodeJpg(portraitImg));

        final result = await ImageCropUtils.cropFileTo9x16(
          tempFile.path,
          orientation: DeviceOrientation.landscapeLeft,
          isFrontCamera: true,
        );
        expect(result, isTrue);

        final croppedBytes = tempFile.readAsBytesSync();
        final decoded = img.decodeImage(croppedBytes);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(1600));
        expect(decoded.height, equals(900));
        final aspect = decoded.width / decoded.height;
        expect((aspect - (16 / 9)).abs() < 0.001, isTrue);

        tempDir.deleteSync(recursive: true);
      },
    );

    test('rotates and crops front camera portrait sensor to 16:9 in '
        'landscapeRight', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/front_landscape_right.jpg');

      final portraitImg = img.Image(width: 1200, height: 1600);
      img.fill(portraitImg, color: img.ColorRgb8(15, 25, 35));
      tempFile.writeAsBytesSync(img.encodeJpg(portraitImg));

      final result = await ImageCropUtils.cropFileTo9x16(
        tempFile.path,
        orientation: DeviceOrientation.landscapeRight,
        isFrontCamera: true,
      );
      expect(result, isTrue);

      final croppedBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(croppedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1600));
      expect(decoded.height, equals(900));
      final aspect = decoded.width / decoded.height;
      expect((aspect - (16 / 9)).abs() < 0.001, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test(
      'DefaultImageCropper implements ImageCropper and delegates crop',
      () async {
        const cropper = DefaultImageCropper();
        expect(cropper, equals(const DefaultImageCropper()));
        expect(cropper.props, isEmpty);

        final result = await cropper.cropFileTo9x16('/non/existent/file.jpg');
        expect(result, isFalse);
      },
    );

    test('CropRect equality and props', () {
      const rect1 = CropRect(x: 10, y: 20, width: 300, height: 400);
      const rect2 = CropRect(x: 10, y: 20, width: 300, height: 400);
      const rect3 = CropRect(x: 15, y: 20, width: 300, height: 400);

      expect(rect1, equals(rect2));
      expect(rect1 == rect3, isFalse);
      expect(rect1.props, equals([10, 20, 300, 400]));
    });

    test('CropImagePayload equality and props', () {
      final payload1 = CropImagePayload(bytes: Uint8List.fromList([1, 2, 3]));
      final payload2 = CropImagePayload(bytes: Uint8List.fromList([1, 2, 3]));
      final payloadFront = CropImagePayload(
        bytes: Uint8List.fromList([1, 2, 3]),
        isFrontCamera: true,
      );

      expect(payload1, equals(payload2));
      expect(payload1 == payloadFront, isFalse);
      expect(
        payload1.props,
        equals([
          payload1.bytes,
          DeviceOrientation.portraitUp,
          CropImagePayload.defaultQuality,
          CropImagePayload.defaultMaxWidth,
          CropImagePayload.defaultMaxHeight,
          false,
        ]),
      );
      expect(payloadFront.isFrontCamera, isTrue);
    });

    test('flips image horizontally when isFrontCamera is true', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/front_camera_selfie.jpg');

      // Citra 900x1600 (9:16): sisi kiri Merah, sisi kanan Biru
      final image = img.Image(width: 900, height: 1600);
      for (var y = 0; y < 1600; y++) {
        for (var x = 0; x < 900; x++) {
          if (x < 450) {
            image.setPixelRgba(x, y, 255, 0, 0, 255);
          } else {
            image.setPixelRgba(x, y, 0, 0, 255, 255);
          }
        }
      }
      tempFile.writeAsBytesSync(img.encodeJpg(image));

      const cropper = DefaultImageCropper();
      final result = await cropper.cropFileTo9x16(
        tempFile.path,
        isFrontCamera: true,
      );
      expect(result, isTrue);

      final resultBytes = tempFile.readAsBytesSync();
      final decoded = img.decodeImage(resultBytes);
      expect(decoded, isNotNull);

      // Setelah horizontal flip, sisi kiri menjadi Biru dan kanan Merah
      final leftPixel = decoded!.getPixel(100, 800);
      final rightPixel = decoded.getPixel(800, 800);

      expect(leftPixel.b > 200, isTrue);
      expect(leftPixel.r < 50, isTrue);
      expect(rightPixel.r > 200, isTrue);
      expect(rightPixel.b < 50, isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test(
      'does not flip image horizontally when isFrontCamera is false',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/rear_camera_photo.jpg');

        // Citra 900x1600 (9:16): sisi kiri Merah, sisi kanan Biru
        final image = img.Image(width: 900, height: 1600);
        for (var y = 0; y < 1600; y++) {
          for (var x = 0; x < 900; x++) {
            if (x < 450) {
              image.setPixelRgba(x, y, 255, 0, 0, 255);
            } else {
              image.setPixelRgba(x, y, 0, 0, 255, 255);
            }
          }
        }
        tempFile.writeAsBytesSync(img.encodeJpg(image));

        const cropper = DefaultImageCropper();
        final result = await cropper.cropFileTo9x16(tempFile.path);
        expect(result, isTrue);

        final resultBytes = tempFile.readAsBytesSync();
        final decoded = img.decodeImage(resultBytes);
        expect(decoded, isNotNull);

        // Tanpa flip, sisi kiri tetap Merah dan kanan tetap Biru
        final leftPixel = decoded!.getPixel(100, 800);
        final rightPixel = decoded.getPixel(800, 800);

        expect(leftPixel.r > 200, isTrue);
        expect(leftPixel.b < 50, isTrue);
        expect(rightPixel.b > 200, isTrue);
        expect(rightPixel.r < 50, isTrue);

        tempDir.deleteSync(recursive: true);
      },
    );

    test('calculateDownscaleDimensions returns null when within bounds', () {
      final result = ImageCropUtils.calculateDownscaleDimensions(
        currentWidth: 1080,
        currentHeight: 1920,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      expect(result, isNull);
    });

    test(
      'calculateDownscaleDimensions scales down proportionally when exceeding '
      'bounds',
      () {
        final result = ImageCropUtils.calculateDownscaleDimensions(
          currentWidth: 2000,
          currentHeight: 3000,
          maxWidth: 1000,
          maxHeight: 1500,
        );
        expect(result, isNotNull);
        expect(result!.width, equals(1000));
        expect(result.height, equals(1500));
      },
    );
  });
}
