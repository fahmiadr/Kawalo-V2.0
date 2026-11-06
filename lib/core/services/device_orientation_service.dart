/// @docImport 'package:flutter/widgets.dart';
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Kontrak layanan pendeteksi orientasi fisik perangkat berbasis sensor
/// akselerometer hardware.
///
/// Layanan ini memantau vektor gravitasi dari sensor akselerometer perangkat
/// dan memancarkan perubahan [DeviceOrientation] secara kontinu, bahkan saat
/// antarmuka pengguna aplikasi dikunci pada orientasi portrait melalui
/// [SystemChrome.setPreferredOrientations].
///
/// ### Contoh Penggunaan
/// ```dart
/// final orientationService = DefaultDeviceOrientationSensorService();
///
/// final subscription =
///     orientationService.onOrientationChanged.listen((orientation) {
///   debugPrint('Orientasi fisik perangkat berubah ke: $orientation');
/// });
///
/// // Bersihkan sumber daya saat tidak lagi digunakan:
/// orientationService.dispose();
/// ```
abstract class DeviceOrientationSensorService {
  /// Stream perubahan orientasi fisik perangkat.
  Stream<DeviceOrientation> get onOrientationChanged;

  /// Orientasi fisik perangkat saat ini.
  DeviceOrientation get currentOrientation;

  /// Menghentikan langganan sensor dan membersihkan seluruh sumber daya.
  void dispose();
}

/// Kontrak strategi (GoF Strategy) untuk menghitung orientasi fisik perangkat
/// dari vektor akselerasi sensor gravitasi (x, y, z).
///
/// Memungkinkan algoritma pendeteksian sudut orientasi ditukar secara fleksibel
/// tanpa memodifikasi [DeviceOrientationSensorService].
abstract class DeviceOrientationStrategy {
  /// Menghitung orientasi perangkat dari koordinat akselerasi sensor.
  ///
  /// Mengembalikan `null` jika perangkat berada dalam posisi datar/telentang
  /// (magnitude bidang XY terlalu kecil dibanding sumbu Z) sehingga orientasi
  /// sebelumnya [current] harus dipertahankan.
  DeviceOrientation? calculate({
    required double x,
    required double y,
    required double z,
    required DeviceOrientation current,
  });
}

/// Strategi kalkulasi orientasi (GoF Concrete Strategy) berbasis algoritma
/// AOSP (Android Open Source Project) dengan toleransi histeresis simetris.
///
/// Menerapkan ambang batas histeresis pada batas kuadran sudut untuk mencegah
/// efek kedipan (*flickering*) atau transisi orientasi yang bolak-balik saat
/// perangkat digenggam mendekati sudut perbatasan (misalnya 45°, 135°, 225°,
/// 315°).
///
/// ### Algoritma Perhitungan
/// 1. Membalikkan sumbu sensor (`-x`, `-y`, `-z`) ke koordinat standar.
/// 2. Memeriksa posisi datar: jika `(x² + y²) * 4 < z²`, perhitungan
///    mengembalikan `null` (pertahankan orientasi aktif).
/// 3. Menghitung sudut rotasi polar via [math.atan2].
/// 4. Menguji apakah sudut masih berada dalam toleransi `45° +
///    [hysteresisDegrees]` dari sektor orientasi saat ini sebelum memutuskan
///    transisi ke kuadran baru.
@immutable
class AospDeviceOrientationStrategy extends Equatable
    implements DeviceOrientationStrategy {
  /// Membuat instance [AospDeviceOrientationStrategy].
  ///
  /// Parameter [hysteresisDegrees] menentukan toleransi sudut tambahan
  /// (dalam derajat) untuk mempertahankan orientasi aktif sebelum berpindah ke
  /// kuadran lain. Nilai default adalah [defaultHysteresisDegrees].
  const AospDeviceOrientationStrategy({
    this.hysteresisDegrees = defaultHysteresisDegrees,
  });

  /// Nilai toleransi histeresis standar dalam derajat (10°).
  static const double defaultHysteresisDegrees = 10;

  /// Besaran toleransi histeresis (dalam derajat) untuk memperluas toleransi
  /// sektor orientasi yang sedang aktif.
  final double hysteresisDegrees;

  @override
  List<Object?> get props => [hysteresisDegrees];

  @override
  DeviceOrientation? calculate({
    required double x,
    required double y,
    required double z,
    required DeviceOrientation current,
  }) {
    // 1. Invert sumbu untuk memetakan arah koordinat standar sensor
    final sensorX = -x;
    final sensorY = -y;
    final sensorZ = -z;

    final magnitude = sensorX * sensorX + sensorY * sensorY;

    // 2. Jika magnitude XY terlalu kecil dibanding Z (perangkat telentang atau
    // telungkup datar di atas meja), pertahankan orientasi saat ini.
    if (magnitude * 4 < sensorZ * sensorZ) {
      return null;
    }

    // 3. Hitung sudut rotasi dalam derajat [0 - 359]
    // 0° = portraitUp, 90° = landscapeRight,
    // 180° = portraitDown, 270° = landscapeLeft
    final angleRad = math.atan2(-sensorY, sensorX);
    final rawAngleDeg = (90 - (angleRad * (180.0 / math.pi)).round()) % 360;
    final angleDeg = rawAngleDeg < 0 ? rawAngleDeg + 360 : rawAngleDeg;

    // 4. Evaluasi histeresis: jika masih berada dalam ambang batas toleransi
    // sektor orientasi saat ini, pertahankan orientasi tersebut.
    final currentCenter = _centerDegreesForOrientation(current);
    if (_angularDistance(angleDeg, currentCenter) <= 45.0 + hysteresisDegrees) {
      return current;
    }

    // 5. Transisi ke kuadran standar terdekat
    return switch (angleDeg) {
      >= 45 && < 135 => DeviceOrientation.landscapeRight,
      >= 135 && < 225 => DeviceOrientation.portraitDown,
      >= 225 && < 315 => DeviceOrientation.landscapeLeft,
      _ => DeviceOrientation.portraitUp,
    };
  }

  static double _angularDistance(int angle, int center) =>
      (((angle - center + 180) % 360) - 180).abs().toDouble();

  static int _centerDegreesForOrientation(DeviceOrientation orientation) =>
      switch (orientation) {
        DeviceOrientation.portraitUp => 0,
        DeviceOrientation.landscapeRight => 90,
        DeviceOrientation.portraitDown => 180,
        DeviceOrientation.landscapeLeft => 270,
      };
}

/// Implementasi bawaan [DeviceOrientationSensorService] menggunakan
/// [accelerometerEventStream] dari `sensors_plus` dan algoritma perhitungan
/// orientasi berbasis [DeviceOrientationStrategy].
///
/// ### Contoh Penggunaan dengan Pure DI
/// ```dart
/// // Menggunakan konfigurasi sensor default dan strategi AOSP:
/// final defaultService = DefaultDeviceOrientationSensorService();
///
/// // Atau menyuntikkan stream kustom dan orientasi awal untuk testing:
/// final customService = DefaultDeviceOrientationSensorService(
///   accelerometerStream: myMockStream,
///   initialOrientation: DeviceOrientation.landscapeLeft,
///   strategy: const AospDeviceOrientationStrategy(hysteresisDegrees: 15),
/// );
/// ```
class DefaultDeviceOrientationSensorService
    implements DeviceOrientationSensorService {
  /// Membuat instance [DefaultDeviceOrientationSensorService].
  ///
  /// Menerima [accelerometerStream] opsional untuk injeksi pengujian,
  /// [initialOrientation] sebagai orientasi awal sebelum sensor memancarkan
  /// event pertama, serta [strategy] untuk kalkulasi orientasi (default
  /// menggunakan [AospDeviceOrientationStrategy.new]).
  DefaultDeviceOrientationSensorService({
    Stream<AccelerometerEvent>? accelerometerStream,
    DeviceOrientation initialOrientation = DeviceOrientation.portraitUp,
    this.strategy = const AospDeviceOrientationStrategy(),
  }) : _currentOrientation = initialOrientation {
    final stream = accelerometerStream ??
        accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        );
    _subscription = stream.listen(
      _handleAccelerometerEvent,
      onError: (_) {
        // Abaikan error sensor jika perangkat/emulator tidak memiliki sensor
      },
      cancelOnError: false,
    );
  }

  /// Strategi kalkulasi orientasi (GoF Strategy) yang didelegasikan.
  final DeviceOrientationStrategy strategy;

  DeviceOrientation _currentOrientation;
  StreamSubscription<AccelerometerEvent>? _subscription;
  final StreamController<DeviceOrientation> _controller =
      StreamController<DeviceOrientation>.broadcast();
  bool _isDisposed = false;

  @override
  Stream<DeviceOrientation> get onOrientationChanged => _controller.stream;

  @override
  DeviceOrientation get currentOrientation => _currentOrientation;

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (_isDisposed || _controller.isClosed) return;

    final orientation = strategy.calculate(
      x: event.x,
      y: event.y,
      z: event.z,
      current: _currentOrientation,
    );

    if (orientation != null && orientation != _currentOrientation) {
      _currentOrientation = orientation;
      if (!_isDisposed && !_controller.isClosed) {
        _controller.add(orientation);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}

/// Implementasi Null Object (GoF Null Object Pattern) untuk
/// [DeviceOrientationSensorService] yang tidak melakukan operasi sensor apa
/// pun (no-op).
///
/// Bermanfaat untuk platform tanpa sensor hardware (desktop/web) atau
/// isolasi pengujian widget/unit test tanpa polusi sensor.
///
/// Mengembalikan stream kosong pada [onOrientationChanged] dan selalu
/// mengembalikan [initialOrientation] statis pada [currentOrientation].
///
/// ### Contoh Penggunaan
/// ```dart
/// // Menyuntikkan no-op service pada pengujian widget:
/// await tester.pumpWidget(
///   AppMultiShotCameraScreen(
///     orientationSensorService: const NoOpDeviceOrientationSensorService(
///       initialOrientation: DeviceOrientation.landscapeLeft,
///     ),
///   ),
/// );
/// ```
@immutable
class NoOpDeviceOrientationSensorService extends Equatable
    implements DeviceOrientationSensorService {
  /// Membuat instance [NoOpDeviceOrientationSensorService].
  ///
  /// Menetapkan [initialOrientation] statis yang akan selalu dikembalikan
  /// oleh [currentOrientation]. Default bernilai
  /// [DeviceOrientation.portraitUp].
  const NoOpDeviceOrientationSensorService({
    this.initialOrientation = DeviceOrientation.portraitUp,
  });

  /// Orientasi statis yang dikembalikan oleh layanan ini.
  final DeviceOrientation initialOrientation;

  @override
  Stream<DeviceOrientation> get onOrientationChanged => const Stream.empty();

  @override
  DeviceOrientation get currentOrientation => initialOrientation;

  @override
  void dispose() {}

  @override
  List<Object?> get props => [initialOrientation];
}

/// Ekstensi konversi [DeviceOrientation] ke pecahan putaran (*turns*)
/// searah jarum jam untuk widget rotasi (seperti [AnimatedRotation]) serta
/// helper inspeksi orientasi.
///
/// ### Contoh Penggunaan
/// ```dart
/// final orientation = DeviceOrientation.landscapeLeft;
///
/// // Mendapatkan pecahan putaran untuk widget AnimatedRotation:
/// final turns = orientation.turns; // 0.25
///
/// // Memeriksa tipe orientasi:
/// final isLandscape = orientation.isLandscape; // true
/// final isPortrait = orientation.isPortrait; // false
/// ```
extension DeviceOrientationTurns on DeviceOrientation {
  /// Pecahan putaran (*turns*) searah jarum jam relatif terhadap
  /// [DeviceOrientation.portraitUp].
  ///
  /// Pemetaan putaran:
  /// * [DeviceOrientation.portraitUp]: `0.0` putaran (0°).
  /// * [DeviceOrientation.landscapeLeft]: `0.25` putaran (90° CW).
  /// * [DeviceOrientation.portraitDown]: `0.5` putaran (180°).
  /// * [DeviceOrientation.landscapeRight]: `0.75` putaran (270° CW).
  double get turns => switch (this) {
    DeviceOrientation.portraitUp => 0.0,
    DeviceOrientation.landscapeLeft => 0.25,
    DeviceOrientation.portraitDown => 0.5,
    DeviceOrientation.landscapeRight => 0.75,
  };

  /// Apakah orientasi berada pada posisi tegak/portrait (vertikal).
  ///
  /// Mengembalikan `true` untuk [DeviceOrientation.portraitUp] dan
  /// [DeviceOrientation.portraitDown].
  bool get isPortrait =>
      this == DeviceOrientation.portraitUp ||
      this == DeviceOrientation.portraitDown;

  /// Apakah orientasi berada pada posisi menyamping/landscape (horizontal).
  ///
  /// Mengembalikan `true` untuk [DeviceOrientation.landscapeLeft] dan
  /// [DeviceOrientation.landscapeRight].
  bool get isLandscape =>
      this == DeviceOrientation.landscapeLeft ||
      this == DeviceOrientation.landscapeRight;
}
