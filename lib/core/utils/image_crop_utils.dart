/// @docImport 'package:kawalo_mobile/core/widgets/app_multi_shot_camera_screen.dart';
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:image/image.dart' as img;

/// Nilai koordinat dan dimensi area pemotongan (*crop rectangle*).
///
/// Merepresentasikan koordinat asal ([x], [y]) beserta [width] dan [height]
/// dari area pemotongan citra dua dimensi dalam satuan piksel.
///
/// Digunakan oleh [ImageCropUtils.calculateCenterCrop] untuk menentukan area
/// pemotongan simetris di tengah (*center crop*) sebelum citra dipotong
/// menggunakan paket `image`.
@immutable
class CropRect extends Equatable {
  /// Membuat instans [CropRect].
  const CropRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Koordinat horizontal titik awal pemotongan dalam piksel.
  final int x;

  /// Koordinat vertikal titik awal pemotongan dalam piksel.
  final int y;

  /// Lebar area pemotongan dalam piksel.
  final int width;

  /// Tinggi area pemotongan dalam piksel.
  final int height;

  @override
  List<Object?> get props => [x, y, width, height];
}

/// Parameter pemrosesan pemotongan citra untuk background isolate.
///
/// Mengelompokkan seluruh data masukan yang dibutuhkan oleh
/// [ImageCropUtils.cropBytesTo9x16Sync] agar dapat dikirim melintasi
/// *isolate boundary* via [compute].
///
/// Seluruh properti bersifat immutable dan mendukung perbandingan nilai
/// melalui [Equatable].
@immutable
class CropImagePayload extends Equatable {
  /// Membuat instans [CropImagePayload].
  const CropImagePayload({
    required this.bytes,
    this.orientation = DeviceOrientation.portraitUp,
    this.quality = defaultQuality,
    this.maxWidth = defaultMaxWidth,
    this.maxHeight = defaultMaxHeight,
    this.isFrontCamera = false,
  });

  /// Byte citra mentah yang akan diproses.
  final Uint8List bytes;

  /// Orientasi fisik pengambilan citra saat foto ditangkap.
  final DeviceOrientation orientation;

  /// Kualitas kompresi JPEG hasil pemotongan dalam rentang 1 hingga 100.
  final int quality;

  /// Batas lebar maksimum hasil citra dalam satuan piksel.
  final double maxWidth;

  /// Batas tinggi maksimum hasil citra dalam satuan piksel.
  final double maxHeight;

  /// Apakah citra diambil menggunakan kamera depan (selfie).
  ///
  /// Jika bernilai `true`, citra akan dibalik secara horizontal (*mirroring*)
  /// agar hasil tangkapan selaras dengan tampilan pratinjau viewfinder.
  final bool isFrontCamera;

  /// Kualitas kompresi JPEG standar (85, selaras dengan galeri).
  static const int defaultQuality = 85;

  /// Resolusi lebar maksimum standar (Full HD boundary 1920 piksel).
  static const double defaultMaxWidth = 1920;

  /// Resolusi tinggi maksimum standar (Full HD boundary 1920 piksel).
  static const double defaultMaxHeight = 1920;

  @override
  List<Object?> get props => [
        bytes,
        orientation,
        quality,
        maxWidth,
        maxHeight,
        isFrontCamera,
      ];
}

/// Kontrak abstraksi layanan pemotongan citra berbasis GoF Strategy.
///
/// Mengabstraksikan operasi pemotongan dan kompresi citra dari implementasi
/// perangkat keras/sistem berkas langsung, mematuhi prinsip Dependency
/// Inversion Principle (DIP) dan Inversion of Control (IoC).
///
/// Memungkinkan konsumen seperti [AppMultiShotCameraScreen] untuk
/// menyuntikkan implementasi alternatif saat pengujian tanpa menyentuh disk
/// I/O atau memicu background isolate.
///
/// ### Contoh Implementasi Stub Pengujian
/// ```dart
/// class FakeImageCropper implements ImageCropper {
///   @override
///   Future<bool> cropFileTo9x16(
///     String filePath, {
///     DeviceOrientation orientation = DeviceOrientation.portraitUp,
///     double maxWidth = CropImagePayload.defaultMaxWidth,
///     double maxHeight = CropImagePayload.defaultMaxHeight,
///     int quality = CropImagePayload.defaultQuality,
///     bool isFrontCamera = false,
///   }) async => true;
/// }
/// ```
abstract interface class ImageCropper {
  /// Memotong berkas gambar pada [filePath] menjadi rasio 9:16 atau 16:9.
  ///
  /// Menyesuaikan rasio target berdasarkan [orientation] fisik perangkat
  /// (rasio 9:16 untuk portrait atau 16:9 untuk landscape) serta membatasi
  /// resolusi agar tidak melampaui [maxWidth] dan [maxHeight].
  ///
  /// Jika [isFrontCamera] bernilai `true`, citra dibalik secara horizontal
  /// (*mirroring*) agar selaras dengan tampilan pratinjau viewfinder selfie.
  ///
  /// Mengembalikan `true` jika pemotongan berhasil dan berkas terbarui,
  /// atau `false` jika pemotongan gagal atau format berkas tidak valid.
  Future<bool> cropFileTo9x16(
    String filePath, {
    DeviceOrientation orientation = DeviceOrientation.portraitUp,
    double maxWidth = CropImagePayload.defaultMaxWidth,
    double maxHeight = CropImagePayload.defaultMaxHeight,
    int quality = CropImagePayload.defaultQuality,
    bool isFrontCamera = false,
  });
}

/// Implementasi standar [ImageCropper] berbasis delegasi ke background isolate.
///
/// Menggunakan [ImageCropUtils.cropFileTo9x16] untuk menjalankan proses
/// decoding, koreksi rotasi EXIF, kalkulasi center crop, pengecilan skala,
/// dan kompresi JPEG di dalam background isolate melalui [compute].
///
/// Dirancang bersifat immutable dan stateless sehingga dapat dibuat sebagai
/// konstanta compile-time (`const [DefaultImageCropper.new]`).
@immutable
class DefaultImageCropper extends Equatable implements ImageCropper {
  /// Membuat instans [DefaultImageCropper].
  const DefaultImageCropper();

  @override
  Future<bool> cropFileTo9x16(
    String filePath, {
    DeviceOrientation orientation = DeviceOrientation.portraitUp,
    double maxWidth = CropImagePayload.defaultMaxWidth,
    double maxHeight = CropImagePayload.defaultMaxHeight,
    int quality = CropImagePayload.defaultQuality,
    bool isFrontCamera = false,
  }) =>
      ImageCropUtils.cropFileTo9x16(
        filePath,
        orientation: orientation,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        isFrontCamera: isFrontCamera,
      );

  @override
  List<Object?> get props => const [];
}

/// Utilitas pemrosesan citra dan kalkulasi pemotongan rasio 9:16 dan 16:9.
///
/// Menyediakan fungsi matematika murni untuk rotasi, penentuan rasio aspek,
/// koordinat pemotongan di tengah (*center crop*), dan penskalaan dimensi,
/// serta fungsi eksekusi pemrosesan citra pada background isolate.
///
/// Dirancang sebagai namespace statis murni yang tidak dapat diinstansiasi
/// ([ImageCropUtils._]).
abstract final class ImageCropUtils {
  const ImageCropUtils._();

  /// Toleransi perbandingan rasio aspek (1%).
  ///
  /// Jika selisih absolut antara rasio aspek saat ini dan target kurang dari
  /// nilai ini, tahap pemotongan piksel dilewati karena citra sudah dianggap
  /// cukup dekat dengan rasio target secara visual.
  static const double aspectRatioTolerance = 0.01;

  /// Rasio aspek standar 9:16 untuk kamera portrait (lebar / tinggi = 0.5625).
  static const double aspect9x16 = 9 / 16;

  /// Rasio aspek standar 16:9 untuk kamera landscape (lebar / tinggi = 1.7778).
  static const double aspect16x9 = 16 / 9;

  /// Menentukan sudut rotasi dalam derajat searah jarum jam untuk citra.
  ///
  /// Menyelaraskan citra sensor kamera ke orientasi fisik [orientation]
  /// jika dimensi vertikal lebih besar dari horizontal
  /// ([isHeightGreaterThanWidth]).
  ///
  /// Menyesuaikan arah rotasi berdasarkan [isFrontCamera] karena orientasi
  /// pemasangan sensor perangkat keras kamera depan berlawanan 180 derajat
  /// dengan kamera belakang pada orientasi landscape.
  ///
  /// Mengembalikan `null` jika citra tidak memerlukan koreksi rotasi
  /// tambahan.
  static int? rotationAngleFor({
    required DeviceOrientation orientation,
    required bool isHeightGreaterThanWidth,
    bool isFrontCamera = false,
  }) =>
      switch (orientation) {
        DeviceOrientation.portraitDown => 180,
        DeviceOrientation.landscapeLeft when isHeightGreaterThanWidth =>
          isFrontCamera ? 90 : 270,
        DeviceOrientation.landscapeRight when isHeightGreaterThanWidth =>
          isFrontCamera ? 270 : 90,
        _ => null,
      };

  /// Menentukan rasio aspek target pemotongan citra.
  ///
  /// Menghasilkan [aspect16x9] jika [orientation] berada dalam posisi
  /// landscape atau dimensi [width] lebih besar dari [height], dan
  /// menghasilkan [aspect9x16] untuk kondisi portrait vertikal.
  static double resolveTargetAspectRatio({
    required DeviceOrientation orientation,
    required int width,
    required int height,
  }) =>
      (orientation == DeviceOrientation.landscapeLeft ||
              orientation == DeviceOrientation.landscapeRight ||
              width > height)
          ? aspect16x9
          : aspect9x16;

  /// Menghitung koordinat pemotongan di tengah (*center crop*) dari dimensi
  /// sumber.
  ///
  /// Mengembalikan [CropRect] yang berisi koordinat `x`, `y`, `width`, dan
  /// `height` simetris di tengah citra berdasarkan [sourceWidth],
  /// [sourceHeight], dan [targetAspect].
  static CropRect calculateCenterCrop({
    required int sourceWidth,
    required int sourceHeight,
    required double targetAspect,
  }) {
    final currentAspect = sourceWidth / sourceHeight;
    if (currentAspect > targetAspect) {
      final cropHeight = sourceHeight;
      final cropWidth =
          (sourceHeight * targetAspect).round().clamp(1, sourceWidth);
      final cropX = ((sourceWidth - cropWidth) / 2)
          .round()
          .clamp(0, sourceWidth - cropWidth);
      return CropRect(
        x: cropX,
        y: 0,
        width: cropWidth,
        height: cropHeight,
      );
    } else {
      final cropWidth = sourceWidth;
      final cropHeight =
          (sourceWidth / targetAspect).round().clamp(1, sourceHeight);
      final cropY = ((sourceHeight - cropHeight) / 2)
          .round()
          .clamp(0, sourceHeight - cropHeight);
      return CropRect(
        x: 0,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );
    }
  }

  /// Menghitung dimensi baru hasil pengecilan skala jika melebihi batas
  /// resolusi.
  ///
  /// Mengembalikan record `({int width, int height})` dengan proporsi aspek
  /// asli jika [currentWidth] melampaui [maxWidth] atau [currentHeight]
  /// melampaui [maxHeight].
  ///
  /// Mengembalikan `null` jika dimensi citra sudah berada di dalam batas
  /// maksimum yang diizinkan.
  static ({int width, int height})? calculateDownscaleDimensions({
    required int currentWidth,
    required int currentHeight,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (currentHeight <= maxHeight && currentWidth <= maxWidth) {
      return null;
    }
    final scale = math.min(
      maxHeight / currentHeight,
      maxWidth / currentWidth,
    );
    return (
      width: (currentWidth * scale).round(),
      height: (currentHeight * scale).round(),
    );
  }

  /// Memotong berkas gambar pada [filePath] menjadi rasio 9:16 atau 16:9.
  ///
  /// Menjalankan pemrosesan di background isolate via [compute] agar tidak
  /// memblokir thread antarmuka pengguna. Jika pemotongan atau decoding
  /// gagal, berkas asli dipertahankan secara utuh dan mengembalikan `false`.
  ///
  /// Jika [isFrontCamera] bernilai `true`, citra dibalik secara horizontal
  /// (*mirroring*) agar selaras dengan tampilan pratinjau viewfinder selfie.
  ///
  /// Operasi penulisan berkas menggunakan opsi `flush: true` untuk menjamin
  /// persistensi data fisik ke penyimpanan perangkat.
  static Future<bool> cropFileTo9x16(
    String filePath, {
    DeviceOrientation orientation = DeviceOrientation.portraitUp,
    double maxWidth = CropImagePayload.defaultMaxWidth,
    double maxHeight = CropImagePayload.defaultMaxHeight,
    int quality = CropImagePayload.defaultQuality,
    bool isFrontCamera = false,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return false;
      }

      final croppedBytes = await compute(
        cropBytesTo9x16Sync,
        CropImagePayload(
          bytes: bytes,
          orientation: orientation,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
          isFrontCamera: isFrontCamera,
        ),
      );

      if (croppedBytes != null && croppedBytes.isNotEmpty) {
        await file.writeAsBytes(croppedBytes, flush: true);
        return true;
      }
      return false;
    } on Object catch (_) {
      return false;
    }
  }

  /// Memotong byte citra mentah ke rasio 9:16 atau 16:9 secara sinkronus.
  ///
  /// Menerima [payload] berisi byte gambar dan parameter pemrosesan. Fungsi
  /// ini dirancang murni memanipulasi memori tanpa menyentuh sistem berkas
  /// sehingga aman dieksekusi di dalam background isolate.
  ///
  /// Mengembalikan [Uint8List] byte JPEG hasil kompresi, atau `null` jika
  /// decoding gagal.
  static Uint8List? cropBytesTo9x16Sync(CropImagePayload payload) {
    try {
      final original = img.decodeImage(payload.bytes);
      if (original == null) {
        return null;
      }

      final oriented = img.bakeOrientation(original);
      final rotationAngle = rotationAngleFor(
        orientation: payload.orientation,
        isHeightGreaterThanWidth: oriented.height > oriented.width,
        isFrontCamera: payload.isFrontCamera,
      );
      final rotated = rotationAngle != null
          ? img.copyRotate(oriented, angle: rotationAngle)
          : oriented;

      final baked = payload.isFrontCamera
          ? img.copyFlip(rotated, direction: img.FlipDirection.horizontal)
          : rotated;

      final width = baked.width;
      final height = baked.height;

      if (width <= 0 || height <= 0) {
        return null;
      }

      final targetAspect = resolveTargetAspectRatio(
        orientation: payload.orientation,
        width: width,
        height: height,
      );

      final currentAspect = width / height;
      final img.Image cropped;
      // Jika rasio aspek sudah sangat mendekati target (toleransi 1%),
      // lewati tahap pemotongan piksel
      if ((currentAspect - targetAspect).abs() < aspectRatioTolerance) {
        cropped = baked;
      } else {
        final crop = calculateCenterCrop(
          sourceWidth: width,
          sourceHeight: height,
          targetAspect: targetAspect,
        );
        cropped = img.copyCrop(
          baked,
          x: crop.x,
          y: crop.y,
          width: crop.width,
          height: crop.height,
        );
      }

      final downscale = calculateDownscaleDimensions(
        currentWidth: cropped.width,
        currentHeight: cropped.height,
        maxWidth: payload.maxWidth,
        maxHeight: payload.maxHeight,
      );
      final processed = switch (downscale) {
        final d? => img.copyResize(
          cropped,
          width: d.width,
          height: d.height,
          interpolation: img.Interpolation.linear,
        ),
        null => cropped,
      };

      return img.encodeJpg(processed, quality: payload.quality);
    } on Object catch (_) {
      return null;
    }
  }
}
