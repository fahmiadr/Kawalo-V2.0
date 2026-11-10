import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

base class _TestPlatformFile extends PlatformFile {
  _TestPlatformFile({
    required this.name,
    this.path,
    this.size,
    this.overrideExtension,
    this.useAsyncLengthOnly = false,
  });

  @override
  final String name;

  @override
  final String? path;

  final int? size;
  final String? overrideExtension;
  final bool useAsyncLengthOnly;

  @override
  String? get extension => overrideExtension ?? super.extension;

  @override
  Uri get uri => path != null ? Uri.file(path!) : Uri.parse('file://$name');

  @override
  XFile get xFile => XFile(path ?? name);

  @override
  int? lengthSync() => useAsyncLengthOnly ? null : size;

  @override
  Future<int?> length() async => size;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(Uint8List(0));
}

void main() {
  group('DefaultMediaPickerService Configuration & Compression Tests', () {
    late _MockImagePicker mockImagePicker;

    setUp(() {
      mockImagePicker = _MockImagePicker();
    });

    test('exposes standard industry compression constants', () {
      expect(DefaultMediaPickerService.defaultMaxWidth, 1920);
      expect(DefaultMediaPickerService.defaultMaxHeight, 1920);
      expect(DefaultMediaPickerService.defaultImageQuality, 100);
      expect(DefaultMediaPickerService.defaultMaxPhotos, 4);
      expect(
        DefaultMediaPickerService.defaultAllowedDocumentExtensions,
        containsAll(['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt']),
      );
    });

    test('uses default constants when constructor parameters are omitted', () {
      final service = DefaultMediaPickerService(imagePicker: mockImagePicker);

      expect(service.maxWidth, DefaultMediaPickerService.defaultMaxWidth);
      expect(service.maxHeight, DefaultMediaPickerService.defaultMaxHeight);
      expect(
        service.imageQuality,
        DefaultMediaPickerService.defaultImageQuality,
      );
      expect(
        service.allowedDocumentExtensions,
        DefaultMediaPickerService.defaultAllowedDocumentExtensions,
      );
    });

    test(
      'instantiates with all default dependencies when no parameters passed',
      () {
        final service = DefaultMediaPickerService();

        expect(service, isA<MediaPickerService>());
        expect(service.maxWidth, DefaultMediaPickerService.defaultMaxWidth);
        expect(service.maxHeight, DefaultMediaPickerService.defaultMaxHeight);
        expect(
          service.imageQuality,
          DefaultMediaPickerService.defaultImageQuality,
        );
        expect(
          service.allowedDocumentExtensions,
          DefaultMediaPickerService.defaultAllowedDocumentExtensions,
        );
      },
    );

    test('accepts custom compression configuration parameters', () {
      final service = DefaultMediaPickerService(
        imagePicker: mockImagePicker,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
        allowedDocumentExtensions: const ['pdf'],
      );

      expect(service.maxWidth, 1280);
      expect(service.maxHeight, 1280);
      expect(service.imageQuality, 80);
      expect(service.allowedDocumentExtensions, const ['pdf']);
    });

    test('pickMultiImagesFromGallery maps files and respects limit', () async {
      final service = DefaultMediaPickerService(
        imagePicker: mockImagePicker,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 80,
      );

      when(
        () => mockImagePicker.pickMultiImage(
          maxWidth: 1280,
          maxHeight: 720,
          imageQuality: 80,
          limit: 2,
        ),
      ).thenAnswer(
        (_) async => [
          XFile.fromData(
            Uint8List.fromList([1, 2]),
            name: 'img1.png',
            path: '/path/img1.png',
          ),
          XFile.fromData(
            Uint8List.fromList([3, 4]),
            name: 'img2.jpg',
            path: '/path/img2.jpg',
          ),
          XFile.fromData(
            Uint8List.fromList([5, 6]),
            name: 'img3.webp',
            path: '/path/img3.webp',
          ),
        ],
      );

      final results = await service.pickMultiImagesFromGallery(limit: 2);

      expect(results.length, 2);
      expect(results[0].name, 'img1.png');
      expect(results[0].extension, 'png');
      expect(results[1].name, 'img2.jpg');
      expect(results[1].extension, 'jpg');

      verify(
        () => mockImagePicker.pickMultiImage(
          maxWidth: 1280,
          maxHeight: 720,
          imageQuality: 80,
          limit: 2,
        ),
      ).called(1);
    });

    test(
      'pickMultiImagesFromGallery returns all files when limit is null or 0',
      () async {
        final service = DefaultMediaPickerService(imagePicker: mockImagePicker);

        when(
          () => mockImagePicker.pickMultiImage(
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => [
            XFile.fromData(
              Uint8List.fromList([1]),
              name: 'a.jpg',
              path: '/a.jpg',
            ),
            XFile.fromData(
              Uint8List.fromList([2]),
              name: 'b.jpg',
              path: '/b.jpg',
            ),
          ],
        );

        final results = await service.pickMultiImagesFromGallery(limit: 0);

        expect(results.length, 2);
        expect(results[0].name, 'a.jpg');
        expect(results[1].name, 'b.jpg');
      },
    );

    test(
      'pickMultiImagesFromGallery returns empty list when user cancels',
      () async {
        final service = DefaultMediaPickerService(imagePicker: mockImagePicker);

        when(
          () => mockImagePicker.pickMultiImage(
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        final results = await service.pickMultiImagesFromGallery();
        expect(results, isEmpty);
      },
    );

    testWidgets(
      'captureMultiImagesFromCamera delegates parameters to cameraLauncher',
      (tester) async {
        late BuildContext capturedContext;
        int? passedMaxPhotos;
        int? passedAttachedCount;
        double? passedMaxWidth;
        double? passedMaxHeight;
        int? passedQuality;

        final service = DefaultMediaPickerService(
          imagePicker: mockImagePicker,
          maxWidth: 1280,
          maxHeight: 720,
          imageQuality: 90,
          cameraLauncher:
              (
                context, {
                int maxPhotos = 4,
                int alreadyAttachedCount = 0,
                double maxWidth = 1920,
                double maxHeight = 1920,
                int imageQuality = 85,
              }) async {
                capturedContext = context;
                passedMaxPhotos = maxPhotos;
                passedAttachedCount = alreadyAttachedCount;
                passedMaxWidth = maxWidth;
                passedMaxHeight = maxHeight;
                passedQuality = imageQuality;
                return const [
                  AppMediaFile(
                    name: 'captured.jpg',
                    path: '/path/captured.jpg',
                  ),
                ];
              },
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await service.captureMultiImagesFromCamera(
          capturedContext,
          maxPhotos: 3,
          alreadyAttachedCount: 1,
        );

        expect(result.length, 1);
        expect(result.first.name, 'captured.jpg');
        expect(passedMaxPhotos, 3);
        expect(passedAttachedCount, 1);
        expect(passedMaxWidth, 1280);
        expect(passedMaxHeight, 720);
        expect(passedQuality, 90);
      },
    );

    test(
      'pickDocumentFile maps selected document correctly using lengthSync',
      () async {
        FileType? passedType;
        List<String>? passedExtensions;

        final service = DefaultMediaPickerService(
          imagePicker: mockImagePicker,
          allowedDocumentExtensions: const ['pdf', 'docx'],
          documentPicker: ({type = FileType.any, allowedExtensions}) async {
            passedType = type;
            passedExtensions = allowedExtensions;
            return _TestPlatformFile(
              name: 'dokumen_rahasia.pdf',
              path: '/storage/dokumen_rahasia.pdf',
              size: 2048,
            );
          },
        );

        final result = await service.pickDocumentFile();

        expect(result, isNotNull);
        expect(result!.name, 'dokumen_rahasia.pdf');
        expect(result.path, '/storage/dokumen_rahasia.pdf');
        expect(result.sizeInBytes, 2048);
        expect(result.extension, 'pdf');
        expect(passedType, FileType.custom);
        expect(passedExtensions, const ['pdf', 'docx']);
      },
    );

    test(
      'pickDocumentFile falls back to async length when lengthSync is null',
      () async {
        final service = DefaultMediaPickerService(
          imagePicker: mockImagePicker,
          documentPicker: ({type = FileType.any, allowedExtensions}) async {
            return _TestPlatformFile(
              name: 'laporan.docx',
              path: '/storage/laporan.docx',
              size: 4096,
              useAsyncLengthOnly: true,
            );
          },
        );

        final result = await service.pickDocumentFile();

        expect(result, isNotNull);
        expect(result!.name, 'laporan.docx');
        expect(result.sizeInBytes, 4096);
        expect(result.extension, 'docx');
      },
    );

    test(
      'pickDocumentFile returns null when user cancels picker dialog',
      () async {
        final service = DefaultMediaPickerService(
          imagePicker: mockImagePicker,
          documentPicker: ({type = FileType.any, allowedExtensions}) async =>
              null,
        );

        final result = await service.pickDocumentFile();
        expect(result, isNull);
      },
    );
  });

  group('AppMediaFile Model Tests', () {
    test('fromXFile parses name, extension, and size correctly', () async {
      final xFile = XFile.fromData(
        Uint8List.fromList([1, 2, 3, 4, 5]),
        name: 'sample_photo.JPG',
        path: '/storage/sample_photo.JPG',
      );

      final mediaFile = await AppMediaFile.fromXFile(xFile);

      expect(mediaFile.name, 'sample_photo.JPG');
      expect(mediaFile.path, '/storage/sample_photo.JPG');
      expect(mediaFile.sizeInBytes, 5);
      expect(mediaFile.extension, 'jpg');
    });

    test(
      'fromXFile handles file without extension by returning null extension',
      () async {
        final xFile = XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'README',
          path: '/storage/README',
        );

        final mediaFile = await AppMediaFile.fromXFile(xFile);

        expect(mediaFile.name, 'README');
        expect(mediaFile.extension, isNull);
      },
    );

    test('fromXFile handles Windows backslash path formatting', () async {
      final xFile = XFile(r'C:\Users\Admin\Documents\laporan_patroli.PDF');

      final mediaFile = await AppMediaFile.fromXFile(xFile);

      expect(mediaFile.name, 'laporan_patroli.PDF');
      expect(mediaFile.extension, 'pdf');
    });

    test('fromXFile uses fallbackName when name and path are empty', () async {
      final xFile = XFile('');

      final mediaFile = await AppMediaFile.fromXFile(
        xFile,
        fallbackName: 'custom_fallback.png',
      );

      expect(mediaFile.name, 'custom_fallback.png');
      expect(mediaFile.extension, 'png');
    });

    test(
      'fromPlatformFile maps name, path, extension, and size correctly',
      () async {
        final platformFile = _TestPlatformFile(
          name: 'kontrak.PDF',
          path: '/docs/kontrak.PDF',
          size: 1024,
          overrideExtension: 'pdf',
        );

        final mediaFile = await AppMediaFile.fromPlatformFile(platformFile);

        expect(mediaFile.name, 'kontrak.PDF');
        expect(mediaFile.path, '/docs/kontrak.PDF');
        expect(mediaFile.sizeInBytes, 1024);
        expect(mediaFile.extension, 'pdf');
      },
    );

    test('Equatable equality verifies identical props', () {
      const fileA = AppMediaFile(
        name: 'test.jpg',
        path: '/test.jpg',
        sizeInBytes: 100,
        extension: 'jpg',
      );
      const fileB = AppMediaFile(
        name: 'test.jpg',
        path: '/test.jpg',
        sizeInBytes: 100,
        extension: 'jpg',
      );
      const fileC = AppMediaFile(
        name: 'other.jpg',
        path: '/other.jpg',
        sizeInBytes: 200,
        extension: 'jpg',
      );

      expect(fileA, equals(fileB));
      expect(fileA == fileC, isFalse);
      expect(fileA.props, ['test.jpg', '/test.jpg', null, 100, 'jpg']);
    });

    test('stringify prints descriptive representation of AppMediaFile', () {
      const file = AppMediaFile(
        name: 'test.jpg',
        path: '/test.jpg',
        sizeInBytes: 100,
        extension: 'jpg',
      );

      expect(file.stringify, isTrue);
      expect(file.toString(), contains('AppMediaFile'));
      expect(file.toString(), contains('test.jpg'));
      expect(file.toString(), contains('/test.jpg'));
    });
  });
}
