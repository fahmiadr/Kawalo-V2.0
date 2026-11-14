/// @docImport 'package:kawalo_mobile/features/information/presentation/widgets/information_form_dialog.dart';
library;

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kawalo_mobile/core/widgets/camera/app_multi_shot_camera_screen.dart';

/// Representasi berkas media hasil tangkapan kamera, galeri, atau pemilih
/// dokumen.
@immutable
class AppMediaFile extends Equatable {
  /// Membuat instance [AppMediaFile].
  const AppMediaFile({
    required this.name,
    this.path,
    this.bytes,
    this.sizeInBytes,
    this.extension,
  });

  /// Nama berkas beserta ekstensinya (contoh: `foto_patroli.jpg`).
  final String name;

  /// Jalur berkas di penyimpanan lokal perangkat jika tersedia.
  final String? path;

  /// Data biner berkas dalam memori.
  final Uint8List? bytes;

  /// Ukuran berkas dalam satuan bita (*bytes*).
  final int? sizeInBytes;

  /// Ekstensi berkas dalam huruf kecil tanpa tanda titik awal (contoh:
  /// `jpg`, `png`, `pdf`).
  final String? extension;

  @override
  List<Object?> get props => [name, path, bytes, sizeInBytes, extension];

  @override
  bool? get stringify => true;

  /// Membuat [AppMediaFile] dari instance [XFile] native secara DRY.
  ///
  /// Parameter [fallbackName] digunakan apabila nama dan jalur pada [xFile]
  /// tidak berisi nama berkas yang valid.
  static Future<AppMediaFile> fromXFile(
    XFile xFile, {
    String fallbackName = 'image.jpg',
  }) async {
    int? length;
    try {
      length = await xFile.length();
    } on Object catch (_) {
      length = null;
    }

    final rawName = xFile.name.isNotEmpty
        ? xFile.name.split(RegExp(r'[/\\]')).last
        : (xFile.path.split(RegExp(r'[/\\]')).lastOrNull ?? fallbackName);
    final fileName = rawName.isNotEmpty ? rawName : fallbackName;

    final dotIndex = fileName.lastIndexOf('.');
    final ext = dotIndex > 0 && dotIndex < fileName.length - 1
        ? fileName.substring(dotIndex + 1).toLowerCase()
        : null;

    return AppMediaFile(
      name: fileName,
      path: xFile.path,
      sizeInBytes: length,
      extension: ext,
    );
  }

  /// Membuat [AppMediaFile] dari instance [PlatformFile] native secara DRY.
  static Future<AppMediaFile> fromPlatformFile(PlatformFile file) async {
    final length = file.lengthSync() ?? await file.length();
    return AppMediaFile(
      name: file.name,
      path: file.path,
      sizeInBytes: length,
      extension: file.extension?.toLowerCase(),
    );
  }
}

/// Kontrak layanan pemilihan media yang bersih dan framework-agnostic.
///
/// Memfasilitasi pengujian unit dan widget terisolasi pada komponen
/// formulir seperti [InformationFormDialog].
abstract interface class MediaPickerService {
  /// Mengambil banyak foto sekaligus dari galeri penyimpanan perangkat.
  ///
  /// Parameter [limit] menentukan batas kuota maksimal foto yang boleh dipilih.
  Future<List<AppMediaFile>> pickMultiImagesFromGallery({int? limit});

  /// Mengambil banyak foto sekaligus menggunakan antarmuka kamera multi-shot.
  ///
  /// Parameter [maxPhotos] menentukan kapasitas maksimal jepretan foto, dan
  /// [alreadyAttachedCount] menentukan jumlah foto yang sudah terpasang.
  /// See `AppMultiShotCameraScreen.allowSkip` for [allowSkip].
  Future<List<AppMediaFile>> captureMultiImagesFromCamera(
    BuildContext context, {
    int maxPhotos = DefaultMediaPickerService.defaultMaxPhotos,
    int alreadyAttachedCount = 0,
    bool allowSkip = false,
  });

  /// Memilih satu dokumen lokal dari penyimpanan berkas perangkat.
  ///
  /// Mengembalikan [AppMediaFile] dokumen terpilih, atau `null` jika pengguna
  /// membatalkan dialog pemilihan.
  Future<AppMediaFile?> pickDocumentFile();
}

/// Signature fungsi callback untuk meluncurkan layar kamera multi-shot.
typedef CameraScreenLauncher =
    Future<List<AppMediaFile>> Function(
      BuildContext context, {
      int maxPhotos,
      int alreadyAttachedCount,
      double maxWidth,
      double maxHeight,
      int imageQuality,
      bool allowSkip,
    });

/// Signature fungsi callback untuk memilih dokumen tunggal dari penyimpanan
/// berkas.
typedef DocumentPicker =
    Future<PlatformFile?> Function({
      FileType type,
      List<String>? allowedExtensions,
    });

/// Implementasi default [MediaPickerService] yang menggunakan `image_picker`
/// dan `file_picker`.
final class DefaultMediaPickerService implements MediaPickerService {
  /// Membuat instance [DefaultMediaPickerService].
  DefaultMediaPickerService({
    ImagePicker? imagePicker,
    DocumentPicker? documentPicker,
    this.maxWidth = defaultMaxWidth,
    this.maxHeight = defaultMaxHeight,
    this.imageQuality = defaultImageQuality,
    this.allowedDocumentExtensions = defaultAllowedDocumentExtensions,
    CameraScreenLauncher? cameraLauncher,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _documentPicker = documentPicker ?? FilePicker.pickFile,
       _cameraLauncher = cameraLauncher ?? AppMultiShotCameraScreen.show;

  /// Resolusi lebar maksimum standar dalam piksel (Full HD boundary).
  static const double defaultMaxWidth = 1920;

  /// Resolusi tinggi maksimum standar dalam piksel (Full HD boundary).
  static const double defaultMaxHeight = 1920;

  /// Quality of the intermediate JPEG handed back by the picker. It stays at
  /// 100 because `ImageCompressor` re-encodes it to WebP (90-100) afterwards;
  /// a lossy intermediate would be compressed twice.
  static const int defaultImageQuality = 100;

  /// Kapasitas maksimum standar jepretan kamera multi-shot.
  static const int defaultMaxPhotos = 4;

  /// Daftar ekstensi dokumen standar yang diizinkan untuk dipilih.
  static const List<String> defaultAllowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt',
  ];

  final ImagePicker _imagePicker;
  final DocumentPicker _documentPicker;
  final CameraScreenLauncher _cameraLauncher;

  /// Batas lebar maksimum citra saat dikompresi native.
  final double maxWidth;

  /// Batas tinggi maksimum citra saat dikompresi native.
  final double maxHeight;

  /// Kualitas kompresi citra native pada skala 0–100.
  final int imageQuality;

  /// Daftar ekstensi dokumen yang diizinkan untuk dipilih.
  final List<String> allowedDocumentExtensions;

  @override
  Future<List<AppMediaFile>> pickMultiImagesFromGallery({int? limit}) async {
    final xFiles = await _imagePicker.pickMultiImage(
      limit: limit,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (xFiles.isEmpty) return const [];

    final targetFiles = limit != null && limit > 0
        ? xFiles.take(limit)
        : xFiles;

    return await Future.wait(targetFiles.map(AppMediaFile.fromXFile));
  }

  @override
  Future<List<AppMediaFile>> captureMultiImagesFromCamera(
    BuildContext context, {
    int maxPhotos = defaultMaxPhotos,
    int alreadyAttachedCount = 0,
    bool allowSkip = false,
  }) {
    return _cameraLauncher(
      context,
      maxPhotos: maxPhotos,
      alreadyAttachedCount: alreadyAttachedCount,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      allowSkip: allowSkip,
    );
  }

  @override
  Future<AppMediaFile?> pickDocumentFile() async {
    final file = await _documentPicker(
      type: FileType.custom,
      allowedExtensions: allowedDocumentExtensions,
    );
    if (file == null) return null;

    return await AppMediaFile.fromPlatformFile(file);
  }
}
