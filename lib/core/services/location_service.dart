/// @docImport 'package:kawalo_mobile/core/services/app_launcher_service.dart';
/// @docImport 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
/// @docImport 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/app_map_picker_dialog.dart';
library;

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';

export 'package:geolocator/geolocator.dart'
    show LocationAccuracy, LocationAccuracyStatus, LocationPermission, Position;

/// Status hasil evaluasi dan perolehan koordinat lokasi perangkat.
///
/// Digunakan oleh [LocationResult] dan [LocationActionableError] untuk
/// menentukan tindakan resolusi antarmuka yang tepat.
enum LocationStatus {
  /// Lokasi berhasil diperoleh dan aman dari manipulasi tiruan.
  success,

  /// Layanan GPS atau sensor lokasi perangkat dalam keadaan nonaktif.
  serviceDisabled,

  /// Pengguna menolak izin akses lokasi pada dialog permintaan sistem.
  permissionDenied,

  /// Pengguna menolak izin akses lokasi secara permanen di pengaturan sistem.
  permissionDeniedForever,

  /// Pengguna hanya memberikan izin akses lokasi perkiraan (Approximate).
  preciseLocationRequired,

  /// Sistem mendeteksi adanya manipulasi lokasi tiruan (Mock Location).
  mockLocationDetected,

  /// Batas waktu pengambilan koordinat lokasi terlampaui.
  timeout,

  /// Terjadi kesalahan sistem operasi atau platform yang tidak terduga.
  unknownError;

  /// Menyatakan apakah status operasi berhasil.
  bool get isSuccess => this == LocationStatus.success;

  /// Menyatakan apakah status operasi mengalami kegagalan.
  bool get isFailure => this != LocationStatus.success;

  /// Menyatakan apakah kegagalan berkaitan langsung dengan perizinan aplikasi.
  bool get isPermissionRelated =>
      this == LocationStatus.permissionDenied ||
      this == LocationStatus.permissionDeniedForever ||
      this == LocationStatus.preciseLocationRequired;
}

/// Hasil inspeksi koordinat lokasi terpadu (Value Object).
///
/// Objek pembawa hasil yang bersifat *immutable* dan mengimplementasikan
/// [Equatable] untuk memfasilitasi perbandingan kesetaraan nilai struktural.
///
/// Komponen presentasi seperti [AppMapPickerDialog] menggunakan kesetaraan
/// nilai pada kelas ini untuk mencegah proses render ulang yang tidak perlu
/// (*Targeted Rebuilds*).
@immutable
class LocationResult extends Equatable {
  /// Membuat instans [LocationResult].
  const LocationResult({
    required this.status,
    this.position,
    this.isMocked = false,
    this.errorMessage,
  });

  /// Menghasilkan instans keberhasilan perolehan koordinat lokasi.
  const LocationResult.success(Position position, {bool isMocked = false})
    : this(
        status: LocationStatus.success,
        position: position,
        isMocked: isMocked,
      );

  /// Menghasilkan instans kegagalan akibat sensor lokasi perangkat nonaktif.
  const LocationResult.serviceDisabled({
    String message = 'Layanan lokasi perangkat sedang nonaktif.',
  }) : this(status: LocationStatus.serviceDisabled, errorMessage: message);

  /// Menghasilkan instans kegagalan akibat izin akses lokasi belum diberikan.
  const LocationResult.permissionDenied({
    String message = 'Izin akses lokasi belum diberikan.',
  }) : this(status: LocationStatus.permissionDenied, errorMessage: message);

  /// Menghasilkan instans kegagalan akibat izin lokasi dinonaktifkan permanen.
  const LocationResult.permissionDeniedForever({
    String message =
        'Izin akses lokasi dinonaktifkan. Aktifkan '
        'izin lokasi di pengaturan perangkat.',
  }) : this(
         status: LocationStatus.permissionDeniedForever,
         errorMessage: message,
       );

  /// Menghasilkan instans kegagalan akibat izin lokasi hanya berupa perkiraan.
  const LocationResult.preciseLocationRequired({
    String message =
        'Akses lokasi presisi diperlukan. Aktifkan lokasi '
        'akurat di pengaturan perangkat.',
  }) : this(
         status: LocationStatus.preciseLocationRequired,
         errorMessage: message,
       );

  /// Menghasilkan instans peringatan akibat deteksi lokasi tiruan.
  const LocationResult.mockDetected({
    Position? position,
    String message = 'Penggunaan lokasi tiruan terdeteksi.',
  }) : this(
         status: LocationStatus.mockLocationDetected,
         position: position,
         isMocked: true,
         errorMessage: message,
       );

  /// Menghasilkan instans kegagalan akibat batas waktu pengambilan habis.
  const LocationResult.timeout({
    String message = 'Waktu pencarian lokasi berakhir.',
  }) : this(status: LocationStatus.timeout, errorMessage: message);

  /// Menghasilkan instans kegagalan akibat kesalahan umum atau tak terduga.
  const LocationResult.error(String message)
    : this(status: LocationStatus.unknownError, errorMessage: message);

  /// Status hasil operasi penentuan lokasi.
  final LocationStatus status;

  /// Data koordinat geografis perangkat jika berhasil diperoleh.
  final Position? position;

  /// Menyatakan apakah koordinat terdeteksi dari penyedia lokasi tiruan.
  final bool isMocked;

  /// Pesan deskriptif kegagalan jika terjadi kendala teknis atau perizinan.
  final String? errorMessage;

  /// Menyatakan apakah koordinat valid dan aman dari manipulasi tiruan.
  bool get isSafe => status == LocationStatus.success && position != null;

  /// Menyatakan apakah operasi penentuan lokasi berhasil.
  bool get isSuccess => status == LocationStatus.success;

  /// Menyatakan apakah operasi penentuan lokasi mengalami kegagalan.
  bool get isFailure => status != LocationStatus.success;

  /// Pasangan koordinat lintang dan bujur dalam format Dart 3 Record.
  ///
  /// Bernilai `null` jika [position] belum tersedia. Memfasilitasi
  /// dekonstruksi pattern matching ringkas:
  ///
  /// ```dart
  /// if (result.coordinates case (final lat, final lng)) {
  ///   print('Latitude: $lat, Longitude: $lng');
  /// }
  /// ```
  (double latitude, double longitude)? get coordinates =>
      position != null ? (position!.latitude, position!.longitude) : null;

  static const Object _sentinel = Object();

  /// Menghasilkan salinan baru [LocationResult] dengan pembaruan parsial.
  ///
  /// Menerapkan pola *sentinel* sehingga nilai `null` dapat ditugaskan secara
  /// eksplisit ke [position] atau [errorMessage] tanpa tertimpa nilai lama.
  LocationResult copyWith({
    LocationStatus? status,
    Object? position = _sentinel,
    bool? isMocked,
    Object? errorMessage = _sentinel,
  }) {
    return LocationResult(
      status: status ?? this.status,
      position: identical(position, _sentinel)
          ? this.position
          : position as Position?,
      isMocked: isMocked ?? this.isMocked,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, position, isMocked, errorMessage];
}

/// Kontrak layanan penentuan lokasi GPS terpadu aplikasi Kawalo Mobile.
///
/// Bertindak sebagai Unified Façade & Adapter untuk seluruh kebutuhan lokasi
/// perangkat, mencakup pemeriksaan sakelar GPS, perizinan bertingkat,
/// pengambilan koordinat, penanganan batas waktu (*timeout*), dan verifikasi
/// integritas Anti-Mock GPS.
///
/// Mengikuti prinsip Dependency Inversion (DIP) dan Interface Segregation
/// (ISP), diimplementasikan secara default oleh [DefaultLocationService].
///
/// Contoh integrasi dengan Pure Dependency Injection:
///
/// ```dart
/// class AttendanceManager {
///   const AttendanceManager({
///     this.locationService = const DefaultLocationService(),
///   });
///
///   final LocationService locationService;
///
///   Future<void> checkIn() async {
///     final result = await locationService.getCurrentPosition();
///     if (result.isSafe) {
///       print('Koordinat terverifikasi: ${result.coordinates}');
///     }
///   }
/// }
/// ```
@immutable
abstract interface class LocationService {
  /// Durasi batas waktu default pengambilan koordinat lokasi (15 detik).
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// Instans default [LocationService] untuk kemudahan injeksi dan akses cepat.
  static const LocationService instance = DefaultLocationService();

  /// Mengambil posisi koordinat terkini secara aman dengan verifikasi
  /// Anti-Mock GPS.
  ///
  /// Memeriksa status sakelar GPS perangkat, memvalidasi perizinan aplikasi,
  /// dan meminta koordinat menggunakan tingkat akurasi [accuracy] serta batas
  /// waktu [timeLimit].
  ///
  /// Jika [enforceMockDetection] tidak ditentukan, penegakan anti-mock aktif
  /// secara otomatis di luar mode debug dan environment Dev.
  Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = defaultTimeout,
    bool? enforceMockDetection,
  });

  /// Mengambil posisi terakhir yang diketahui dari cache hardware perangkat.
  ///
  /// Mengembalikan `null` jika cache hardware belum tersedia atau gagal dibaca.
  /// Berguna sebagai petunjuk awal kamera peta (*viewport hint*) tanpa perlu
  /// menunggu penguncian sinyal satelit GPS baru.
  Future<Position?> getLastKnownPosition();

  /// Menghitung jarak garis lurus antara dua titik koordinat dalam
  /// satuan meter.
  ///
  /// Menghitung jarak geodesik antara ([startLatitude], [startLongitude]) dan
  /// ([endLatitude], [endLongitude]) menggunakan formula kalkulasi platform.
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );
}

/// Implementasi standar [LocationService] berbasis platform
/// [GeolocatorPlatform].
///
/// Menyediakan orkestrasi penentuan lokasi yang fail-safe, mendeteksi lokasi
/// tiruan (Anti-Mock GPS), dan menangani kegagalan sistem tanpa melempar
/// unhandled exception ke lapisan UI.
///
/// Mendukung Pure Dependency Injection melalui konstruktor konstan
/// [DefaultLocationService.new], memfasilitasi pengujian unit terisolasi tanpa
/// test pollution atau mutable static state.
///
/// Contoh penggunaan dalam pengujian unit terisolasi:
///
/// ```dart
/// final mockPlatform = MockGeolocatorPlatform();
/// final service = DefaultLocationService(geolocatorPlatform: mockPlatform);
///
/// final result = await service.getCurrentPosition();
/// expect(result.isSuccess, isTrue);
/// ```
@immutable
final class DefaultLocationService implements LocationService {
  /// Membuat instans [DefaultLocationService].
  ///
  /// Menerima delegator [geolocatorPlatform] opsional untuk memfasilitasi
  /// pengujian unit terisolasi. Jika bernilai `null`, instans akan menggunakan
  /// [GeolocatorPlatform.instance] bawaan platform secara dinamis saat runtime.
  const DefaultLocationService({GeolocatorPlatform? geolocatorPlatform})
    : _geolocatorPlatform = geolocatorPlatform;

  final GeolocatorPlatform? _geolocatorPlatform;

  GeolocatorPlatform get _geolocator =>
      _geolocatorPlatform ?? GeolocatorPlatform.instance;

  @override
  Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = LocationService.defaultTimeout,
    bool? enforceMockDetection,
  }) async {
    try {
      final serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.serviceDisabled();
      }

      final permissionResult = await _verifyPermissions();
      if (permissionResult != null) {
        return permissionResult;
      }

      final accuracyStatus = await _checkLocationAccuracy();
      if (accuracyStatus == LocationAccuracyStatus.reduced) {
        final upgradedAccuracy = await _requestPrecisePermission();
        if (upgradedAccuracy != LocationAccuracyStatus.precise) {
          return const LocationResult.preciseLocationRequired();
        }
      }

      final position = await _geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );

      final isMocked = position.isMocked;
      final isDev = EnvConfig.isInitialized && EnvConfig.isDev;
      final shouldEnforce = enforceMockDetection ?? (!kDebugMode && !isDev);

      if (isMocked && shouldEnforce) {
        return LocationResult.mockDetected(position: position);
      }

      return LocationResult.success(position, isMocked: isMocked);
    } on TimeoutException {
      return const LocationResult.timeout();
    } on LocationServiceDisabledException {
      return const LocationResult.serviceDisabled();
    } on PermissionDeniedException {
      return const LocationResult.permissionDenied();
    } on Object catch (e) {
      return LocationResult.error('Gagal memperoleh lokasi: $e');
    }
  }

  Future<LocationAccuracyStatus> _checkLocationAccuracy() async {
    try {
      return await _geolocator.getLocationAccuracy();
    } on Object {
      return LocationAccuracyStatus.unknown;
    }
  }

  Future<LocationAccuracyStatus> _requestPrecisePermission() async {
    try {
      await _geolocator.requestPermission();
      return await _geolocator.getLocationAccuracy();
    } on Object {
      return LocationAccuracyStatus.reduced;
    }
  }

  Future<LocationResult?> _verifyPermissions() async {
    final currentPermission = await _geolocator.checkPermission();

    return switch (currentPermission) {
      LocationPermission.deniedForever =>
        const LocationResult.permissionDeniedForever(),
      LocationPermission.denied => await _requestPermission(),
      LocationPermission.whileInUse || LocationPermission.always => null,
      LocationPermission.unableToDetermine => const LocationResult.error(
        'Status perizinan lokasi tidak dapat ditentukan.',
      ),
    };
  }

  Future<LocationResult?> _requestPermission() async {
    final requestedPermission = await _geolocator.requestPermission();
    return switch (requestedPermission) {
      LocationPermission.denied => const LocationResult.permissionDenied(),
      LocationPermission.deniedForever =>
        const LocationResult.permissionDeniedForever(),
      LocationPermission.whileInUse || LocationPermission.always => null,
      LocationPermission.unableToDetermine => const LocationResult.error(
        'Status perizinan lokasi tidak dapat ditentukan.',
      ),
    };
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    try {
      return await _geolocator.getLastKnownPosition();
    } on Object {
      return null;
    }
  }

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) => _geolocator.distanceBetween(
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
  );
}
