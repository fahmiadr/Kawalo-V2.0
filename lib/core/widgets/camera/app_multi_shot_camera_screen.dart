import 'dart:async';
import 'dart:io' show File;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/error/diagnostic_error_formatter.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/device_orientation_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/services/screen_brightness_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/image_crop_utils.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_bottom_controls.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_overlays.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_quota_badge.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_top_bar.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_viewfinder.dart';
import 'package:kawalo_mobile/core/widgets/camera/controllers/camera_system_ui_controller.dart';
import 'package:kawalo_mobile/core/widgets/camera/controllers/captured_photos_controller.dart';

/// Layar kamera multi-shot standar Material 3 Expressive untuk menangkap
/// foto dokumentasi secara berurutan.
///
/// Layar ini mempertahankan *viewfinder* kamera tetap terbuka setelah
/// setiap pengambilan foto, sehingga pengguna dapat mengambil serangkaian foto
/// dengan cepat tanpa alur buka-tutup layar yang berulang.
///
/// ### Arsitektur 5-Fase Siklus Hidup (Lifecycle)
///
/// Layar ini menerapkan arsitektur siklus hidup 5 fase standar industri:
/// 1. **Ingress & Hardware Probing**: Mengunci orientasi UI ke
///    [DeviceOrientation.portraitUp], mengaktifkan mode *fullscreen immersive*
///    dengan *auto-hide* 1500ms, mendeteksi perangkat keras kamera, serta
///    menginisialisasi sensor akselerometer.
/// 2. **Controller & Surface Attachment**: Menginisialisasi [CameraController]
///    secara terisolasi dengan perlindungan *race condition* berbasis token
///    generasi.
/// 3. **Active Operation & Pipeline Synchronization**: Penguncian status sibuk
///    (*busy-lock*), alur *screen flash* kamera depan, pemotongan rasio 9:16/16:9
///    di latar belakang via [ImageCropper.cropFileTo9x16], dan pra-*caching*
///    tekstur GPU sebelum mutasi status tampilan.
/// 4. **OS Interruption & Resource Eviction (Dual-Layer)**: Membedakan
///    kehilangan fokus sementara ([AppLifecycleState.inactive]) dari
///    penggusuran latar belakang penuh ([AppLifecycleState.paused] /
///    [AppLifecycleState.hidden]) untuk mencegah pelepasan sumber daya
///    prematur atau *infinite retry loop*, serta pemulihan otomatis
///    (*self-healing*) saat kembali aktif.
/// 5. **Clean Teardown & Storage Reconciliation**: Deseleksi bertahap via
///    [PopScope], pembersihan berkas foto yang dibatalkan, serta restorasi
///    penuh bilah sistem OS saat ditutup.
///
/// ### Contoh Penggunaan
///
/// ```dart
/// final List<AppMediaFile> photos = await AppMultiShotCameraScreen.show(
///   context,
///   maxPhotos: 4,
///   alreadyAttachedCount: 1,
/// );
/// ```
class AppMultiShotCameraScreen extends StatefulWidget {
  const AppMultiShotCameraScreen({
    this.maxPhotos = 4,
    this.alreadyAttachedCount = 0,
    this.maxWidth = CropImagePayload.defaultMaxWidth,
    this.maxHeight = CropImagePayload.defaultMaxHeight,
    this.imageQuality = CropImagePayload.defaultQuality,
    this.cameras,
    this.controller,
    this.hasPhysicalFlash,
    this.brightnessService,
    this.initialDeviceOrientation,
    this.orientationSensorService,
    this.openAppSettingsFn,
    this.launcherService = const DefaultAppLauncherService(),
    this.controllerFactory,
    this.errorFormatter,
    this.isProduction,
    this.imageCropper = const DefaultImageCropper(),
    super.key,
  });

  /// Jumlah kuota maksimum foto yang diizinkan untuk formulir ini.
  final int maxPhotos;

  /// Jumlah foto yang sudah terpasang pada formulir sebelumnya.
  final int alreadyAttachedCount;

  /// Batas lebar maksimum citra hasil kompresi dalam satuan piksel.
  final double maxWidth;

  /// Batas tinggi maksimum citra hasil kompresi dalam satuan piksel.
  final double maxHeight;

  /// Kualitas kompresi foto dalam rentang skala 0 hingga 100.
  final int imageQuality;

  /// Daftar deskripsi kamera yang tersedia pada perangkat.
  ///
  /// Jika bernilai `null`, sistem mendeteksi perangkat keras kamera secara
  /// otomatis menggunakan [availableCameras].
  final List<CameraDescription>? cameras;

  /// Kontroler kamera eksternal yang telah disiapkan sebelumnya.
  ///
  /// Jika disediakan, layar ini menggunakan kontroler tersebut secara langsung
  /// tanpa melakukan inisialisasi hardware mandiri.
  final CameraController? controller;

  /// Fungsi pabrik (*factory method*) untuk instansiasi [CameraController]
  /// kustom.
  ///
  /// Berguna untuk menentukan konfigurasi resolusi khusus atau driver tiruan
  /// saat pengujian.
  final CameraController Function(CameraDescription description)?
  controllerFactory;

  /// Apakah modul lampu kilat LED fisik tersedia pada kamera aktif.
  ///
  /// Jika bernilai `null`, ketersediaan lampu kilat LED fisik akan dideteksi
  /// secara dinamis dari pengujian perangkat keras kamera.
  final bool? hasPhysicalFlash;

  /// Layanan kontrol kecerahan layar untuk implementasi *Screen Flash*.
  ///
  /// Digunakan pada kamera depan untuk menerangi wajah pengguna saat memotret
  /// di lingkungan minim cahaya. Jika bernilai `null`, menggunakan
  /// [DefaultScreenBrightnessService].
  final ScreenBrightnessService? brightnessService;

  /// Orientasi fisik awal perangkat saat layar pertama kali dibuka.
  final DeviceOrientation? initialDeviceOrientation;

  /// Layanan pemantau sensor orientasi fisik perangkat (akselerometer).
  ///
  /// Menggerakkan auto-rotasi kontrol UI tanpa merotasi *viewfinder* kamera.
  /// Jika bernilai `null`, menggunakan [DefaultDeviceOrientationSensorService].
  final DeviceOrientationSensorService? orientationSensorService;

  /// Delegasi fungsi untuk membuka menu pengaturan aplikasi di tingkat sistem
  /// operasi.
  ///
  /// Jika bernilai `null`, delegasi dialihkan ke [launcherService].
  final Future<bool> Function()? openAppSettingsFn;

  /// Layanan peluncur intent eksternal terpadu.
  ///
  /// Default menggunakan [DefaultAppLauncherService].
  final AppLauncherService launcherService;

  /// Formatter diagnostik kustom untuk rincian teknis galat berdasarkan pola
  /// GoF Strategy.
  final DiagnosticErrorFormatter? errorFormatter;

  /// Apakah aplikasi berjalan dalam lingkungan produksi.
  ///
  /// Saat bernilai `true`, rincian teknis galat disanitasi secara ketat
  /// untuk mencegah kebocoran informasi sensitif (seperti path direktori
  /// lokal).
  final bool? isProduction;

  /// Layanan pemotongan dan kompresi citra berbasis abstraksi [ImageCropper]
  /// (GoF Strategy).
  ///
  /// Memungkinkan pengujian terisolasi dan inversi ketergantungan (DIP / IoC)
  /// pada alur pemrosesan foto kamera. Nilai default menggunakan
  /// [DefaultImageCropper.new].
  final ImageCropper imageCropper;

  /// Menampilkan layar kamera multi-shot dan mengembalikan daftar
  /// [AppMediaFile] terpilih.
  ///
  /// Membuka layar kamera secara modal menggunakan dialog layar penuh
  /// ([MaterialPageRoute.fullscreenDialog]).
  /// Jika pengguna membatalkan atau menutup layar tanpa menekan tombol
  /// selesai, metode ini mengembalikan daftar kosong.
  ///
  /// Parameter [context] menentukan konteks navigator tempat layar dibuka.
  /// Batas kuota diatur oleh [maxPhotos] dikurangi [alreadyAttachedCount].
  /// Kualitas dan resolusi foto dikendalikan oleh [maxWidth], [maxHeight],
  /// dan [imageQuality]. Dependensi eksternal seperti [cameras], [controller],
  /// [brightnessService], [orientationSensorService], [launcherService],
  /// [errorFormatter], [isProduction], dan [imageCropper] dapat diinjeksi
  /// untuk kebutuhan kustomisasi atau pengujian.
  static Future<List<AppMediaFile>> show(
    BuildContext context, {
    int maxPhotos = 4,
    int alreadyAttachedCount = 0,
    double maxWidth = CropImagePayload.defaultMaxWidth,
    double maxHeight = CropImagePayload.defaultMaxHeight,
    int imageQuality = CropImagePayload.defaultQuality,
    List<CameraDescription>? cameras,
    CameraController? controller,
    bool? hasPhysicalFlash,
    ScreenBrightnessService? brightnessService,
    DeviceOrientation? initialDeviceOrientation,
    DeviceOrientationSensorService? orientationSensorService,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
    ImageCropper imageCropper = const DefaultImageCropper(),
  }) async {
    final results = await Navigator.of(context).push<List<AppMediaFile>>(
      MaterialPageRoute<List<AppMediaFile>>(
        fullscreenDialog: true,
        builder: (context) => AppMultiShotCameraScreen(
          maxPhotos: maxPhotos,
          alreadyAttachedCount: alreadyAttachedCount,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          cameras: cameras,
          controller: controller,
          hasPhysicalFlash: hasPhysicalFlash,
          brightnessService: brightnessService,
          initialDeviceOrientation: initialDeviceOrientation,
          orientationSensorService: orientationSensorService,
          openAppSettingsFn: openAppSettingsFn,
          launcherService: launcherService,
          errorFormatter: errorFormatter,
          isProduction: isProduction,
          imageCropper: imageCropper,
        ),
      ),
    );
    return results ?? const [];
  }

  /// Durasi animasi rotasi kontrol antarmuka saat orientasi perangkat berubah.
  ///
  /// Menggunakan token Material 3 Expressive [AppDuration.long2] (500ms) agar
  /// perputaran terasa berbobot, mulus, dan tidak tergesa-gesa (*snappy*).
  static const Duration rotationDuration = AppDuration.long2;

  /// Kurva animasi rotasi kontrol antarmuka saat orientasi perangkat berubah.
  ///
  /// Menggunakan [Curves.easeOutBack] untuk menghasilkan rotasi dinamis dengan
  /// pantulan kenyal (*expressive overshoot*) khas Material 3 Expressive tanpa
  /// efek tersentak (*dead-shelf*).
  static const Curve rotationCurve = Curves.easeOutBack;

  @override
  State<AppMultiShotCameraScreen> createState() =>
      _AppMultiShotCameraScreenState();
}

bool _isFrontCamera(CameraController controller) {
  try {
    return controller.description.lensDirection == CameraLensDirection.front;
  } on Object catch (_) {
    return false;
  }
}

/// Memeriksa apakah deskripsi error merupakan kegagalan fokus atau eksposur
/// transien yang tidak boleh mematikan operasional kamera.
bool _isTransientFocusOrExposureError(String? errorDescription) {
  if (errorDescription == null) return false;
  final lower = errorDescription.toLowerCase();
  return lower.contains('focus') ||
      lower.contains('exposure') ||
      lower.contains('point') ||
      lower.contains('metering');
}

/// State pengelola layar in-app camera multi-shot.
///
/// Mengikuti arsitektur 5 Fase Utama Lifecycle Standar Industri:
/// 1. Ingress & Hardware Probing: Penguncian orientasi UI ke portraitUp,
///    fullscreen immersive dengan auto-hide 1500ms, probing hardware kamera,
///    dan penyiapan sensor akselerometer.
/// 2. Controller & Surface Attachment: Inisialisasi terisolasi, proteksi
///    race condition via [_initGeneration], deteksi hardware, dan pemasangan
///    Surface.
/// 3. Active Operation & Pipeline Synchronization: Shutter busy-lock, alur
///    screen flash, crop 9:16/16:9, dan pra-caching GPU sebelum mutasi state.
/// 4. OS Interruption & Resource Eviction: Pelepasan hardware kamera
///    seketika saat paused/inactive, pause akselerometer, dan pemulihan
///    otomatis (Auto-Recovery / Self-Healing) saat resumed.
/// 5. Clean Teardown & Storage Reconciliation: Intervensi PopScope
///    bertahap (deselect terlebih dahulu), pemusnahan berkas unsubmitted saat
///    dibatalkan, dan pelepasan seluruh memori pada dispose.
class _AppMultiShotCameraScreenState extends State<AppMultiShotCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isScreenFlashActive = false;
  bool _hasPhysicalFlash = false;

  bool get _isCurrentCameraFront {
    final controller = _controller;
    if (controller != null) {
      return _isFrontCamera(controller);
    }
    if (_selectedCameraIndex < _availableCameras.length) {
      return _availableCameras[_selectedCameraIndex].lensDirection ==
          CameraLensDirection.front;
    }
    return false;
  }

  /// Flash didukung jika kamera memiliki lampu LED fisik ATAU kamera depan
  /// yang mendukung tirai Screen Flash.
  bool get _isFlashSupported {
    if (_availableCameras.isEmpty && _controller == null) {
      return true;
    }
    return _hasPhysicalFlash || _isCurrentCameraFront;
  }

  Future<bool> _checkPhysicalFlashSupport(CameraController controller) async {
    try {
      await controller.setFlashMode(FlashMode.auto);
      try {
        await controller.setFlashMode(FlashMode.off);
      } on Exception catch (_) {}
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;
  AppActionableErrorData? _actionableError;
  int _initGeneration = 0;

  late final AnimationController _shutterFlashController;
  late final AnimationController _badgeTeleportController;
  late final Animation<double> _badgeFadeAnimation;
  late final Animation<double> _badgeScaleAnimation;
  late DeviceOrientation _activeBadgeOrientation;
  int _teleportGeneration = 0;
  late final ScrollController _thumbnailScrollController;
  String? _latestCapturedPath;

  static const Duration _teleportHalfDuration = AppDuration.medium1;

  final CapturedPhotosController _photos = CapturedPhotosController();
  bool _isDoneSubmitted = false;

  int get _maxSelectable => widget.maxPhotos - widget.alreadyAttachedCount;
  int get _totalSelected =>
      widget.alreadyAttachedCount + _photos.selected.length;

  /// Status apakah subsistem kamera sedang berada dalam proses transisi atau
  /// pemotretan.
  bool get _isBusy => _isCapturing || _isInitializing || _isSwitchingCamera;

  /// Status apakah pengguna dapat berinteraksi dengan kontrol kamera tanpa
  /// galat aktif atau busy-lock.
  bool get _canInteract => _actionableError == null && !_isBusy;

  static const SystemUiOverlayStyle _lightOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  final CameraSystemUiController _systemUi = CameraSystemUiController();
  AppLifecycleState? _previousLifecycleState;
  bool _wasInBackground = false;
  late final ScreenBrightnessService _brightnessService;
  double? _originalBrightness;

  Future<bool> _handleOpenAppSettings() async {
    _wasInBackground = true;
    if (widget.openAppSettingsFn != null) {
      return await widget.openAppSettingsFn!();
    }
    return await widget.launcherService.openAppSettings();
  }

  void _attachControllerListeners(CameraController controller) {
    try {
      controller
        ..removeListener(_onCameraControllerValueChanged)
        ..addListener(_onCameraControllerValueChanged);
    } on Object catch (_) {}
  }

  void _detachControllerListeners(CameraController? controller) {
    try {
      controller?.removeListener(_onCameraControllerValueChanged);
    } on Object catch (_) {}
  }

  void _onCameraControllerValueChanged() {
    if (!mounted) return;
    final controller = _controller;
    if (controller != null &&
        controller.value.hasError &&
        _actionableError == null) {
      final errorDescription = controller.value.errorDescription;
      // Abaikan kegagalan titik fokus atau eksposur transien agar tidak
      // memunculkan layar error fatal tak terduga.
      if (_isTransientFocusOrExposureError(errorDescription)) {
        return;
      }
      setState(() {
        _actionableError = CameraActionableError.fromInitializationError(
          errorDescription ?? 'Terjadi kendala saat kamera beroperasi.',
          onRetry: _initCamera,
          onExit: _handleBackOrClose,
          openAppSettingsFn: _handleOpenAppSettings,
          launcherService: widget.launcherService,
          errorFormatter: widget.errorFormatter,
          isProduction: widget.isProduction,
        );
      });
    }
  }

  Future<void> _restoreBrightness() async {
    final original = _originalBrightness;
    _originalBrightness = null;
    if (original != null) {
      await _brightnessService.setBrightness(original);
    } else {
      await _brightnessService.resetBrightness();
    }
  }

  /// Menormalkan kembali kecerahan layar dan menonaktifkan tirai screen flash.
  void _deactivateScreenFlash() {
    if (_isScreenFlashActive) {
      if (mounted) {
        setState(() => _isScreenFlashActive = false);
      } else {
        _isScreenFlashActive = false;
      }
      unawaited(_restoreBrightness());
    }
  }

  late DeviceOrientation _deviceOrientation;
  double _orientationTurns = 0;
  double _switchCameraTurns = 0;
  late final DeviceOrientationSensorService _orientationSensorService;
  StreamSubscription<DeviceOrientation>? _orientationSubscription;

  void _updateOrientationTurns(DeviceOrientation newOrientation) {
    if (_deviceOrientation != newOrientation) {
      final target = newOrientation.turns;
      var delta = (target - _orientationTurns) % 1.0;
      if (delta > 0.5) delta -= 1.0;
      if (delta < -0.5) delta += 1.0;
      setState(() {
        _deviceOrientation = newOrientation;
        _orientationTurns += delta;
        _latestCapturedPath = null;
      });
    }
    _handleBadgeOrientationTransition(newOrientation);
  }

  void _handleBadgeOrientationTransition(DeviceOrientation newOrientation) {
    if (!mounted) return;
    if (AppMotion.isReducedMotion(context)) {
      _teleportGeneration++;
      if (_badgeTeleportController.isAnimating) {
        _badgeTeleportController.stop();
      }
      setState(() {
        _activeBadgeOrientation = newOrientation;
        _badgeTeleportController.value = 1;
      });
      return;
    }

    if (_activeBadgeOrientation == newOrientation &&
        _badgeTeleportController.value == 1) {
      return;
    }

    final generation = ++_teleportGeneration;
    if (_badgeTeleportController.isAnimating) {
      _badgeTeleportController.stop();
    }
    unawaited(_runTeleport(generation));
  }

  Duration _computeTeleportDuration(double ratio) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final durationMs = (_teleportHalfDuration.inMilliseconds * clampedRatio)
        .round();
    return durationMs > 20
        ? Duration(milliseconds: durationMs)
        : const Duration(milliseconds: 20);
  }

  Future<void> _runTeleport(int generation) async {
    try {
      while (mounted && generation == _teleportGeneration) {
        if (_activeBadgeOrientation != _deviceOrientation) {
          // Fase 1: Dissolve / Fade-out badge yang aktif di slot lama
          if (_badgeTeleportController.value > 0) {
            final fadeOutDuration = _computeTeleportDuration(
              _badgeTeleportController.value,
            );
            try {
              await _badgeTeleportController.animateTo(
                0,
                duration: fadeOutDuration,
                curve: Curves.easeIn,
              );
            } on Object catch (_) {}
          }

          if (!mounted || generation != _teleportGeneration) return;

          // Fase Hand-off: Ganti slot saat opacity tepat 0.0
          // Menggunakan orientasi fisik perangkat terkini
          final currentTarget = _deviceOrientation;
          setState(() {
            _activeBadgeOrientation = currentTarget;
          });

          if (!mounted || generation != _teleportGeneration) return;

          // Fase 2: Materialize / Fade-in badge pada slot tujuan
          final fadeInDuration = _computeTeleportDuration(
            1.0 - _badgeTeleportController.value,
          );
          try {
            await _badgeTeleportController.animateTo(
              1,
              duration: fadeInDuration,
            );
          } on Object catch (_) {}
        } else if (_badgeTeleportController.value < 1) {
          // Orientasi fisik sudah sesuai namun animasi fade-in terputus
          final fadeInDuration = _computeTeleportDuration(
            1.0 - _badgeTeleportController.value,
          );
          try {
            await _badgeTeleportController.animateTo(
              1,
              duration: fadeInDuration,
            );
          } on Object catch (_) {}
        } else {
          // Orientasi sinkron dan opasitas telah 100% penuh
          break;
        }
      }
    } finally {
      if (mounted && generation == _teleportGeneration) {
        if (_activeBadgeOrientation != _deviceOrientation) {
          setState(() {
            _activeBadgeOrientation = _deviceOrientation;
          });
        }
        if (_badgeTeleportController.value != 1) {
          _badgeTeleportController.value = 1;
        }
      }
    }
  }

  void _onOrientationChanged(DeviceOrientation newOrientation) {
    if (!mounted) return;
    _updateOrientationTurns(newOrientation);
  }

  // ── FASE 1: Ingress & Hardware Probing ──────────────────────────────────

  void _restoreSystemUI() => _systemUi.restore(
    unlockCaptureOrientation: () => _controller?.unlockCaptureOrientation(),
    restoreBrightness: _restoreBrightness,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _brightnessService =
        widget.brightnessService ?? const DefaultScreenBrightnessService();
    _systemUi.setup(isMounted: () => mounted);

    _deviceOrientation =
        widget.initialDeviceOrientation ??
        widget.orientationSensorService?.currentOrientation ??
        (widget.controller != null
            ? (() {
                try {
                  return widget.controller!.value.deviceOrientation;
                } on Object catch (_) {
                  return DeviceOrientation.portraitUp;
                }
              })()
            : DeviceOrientation.portraitUp);
    _orientationTurns = _deviceOrientation.turns;
    _activeBadgeOrientation = _deviceOrientation;

    _badgeTeleportController = AnimationController(
      vsync: this,
      duration: _teleportHalfDuration,
      value: 1,
    );
    _badgeFadeAnimation = CurvedAnimation(
      parent: _badgeTeleportController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _badgeScaleAnimation = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _badgeTeleportController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _orientationSensorService =
        widget.orientationSensorService ??
        DefaultDeviceOrientationSensorService(
          initialOrientation: _deviceOrientation,
        );
    _orientationSubscription = _orientationSensorService.onOrientationChanged
        .listen(_onOrientationChanged);

    _shutterFlashController = AnimationController(
      vsync: this,
      duration: AppDuration.short4,
    );
    _thumbnailScrollController = ScrollController();

    if (widget.controller != null) {
      _controller = widget.controller;
      _attachControllerListeners(widget.controller!);
      _isInitializing = false;
      try {
        unawaited(
          widget.controller!.lockCaptureOrientation(
            DeviceOrientation.portraitUp,
          ),
        );
      } on Object catch (_) {}
      if (widget.cameras != null) {
        _availableCameras = widget.cameras!;
        try {
          final desc = widget.controller!.description;
          final idx = _availableCameras.indexOf(desc);
          if (idx != -1) {
            _selectedCameraIndex = idx;
          }
        } on Object catch (_) {}
      }
      final isFront = _isFrontCamera(widget.controller!);
      _hasPhysicalFlash = widget.hasPhysicalFlash ?? !isFront;
      if (!_isFlashSupported) {
        _flashMode = FlashMode.off;
      }
    } else {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(covariant AppMultiShotCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _detachControllerListeners(oldWidget.controller);
      _controller = widget.controller;
      if (_controller != null) {
        _attachControllerListeners(_controller!);
      }
    }
    if (widget.initialDeviceOrientation != null &&
        widget.initialDeviceOrientation != oldWidget.initialDeviceOrientation &&
        widget.initialDeviceOrientation != _deviceOrientation) {
      _updateOrientationTurns(widget.initialDeviceOrientation!);
    }
  }

  // ── FASE 5: Clean Teardown & Storage Reconciliation ────────────────────────

  @override
  void dispose() {
    _initGeneration++;
    if (!_isDoneSubmitted) {
      _photos.cleanupUnsubmitted();
    }
    _restoreSystemUI();
    unawaited(_restoreBrightness());
    unawaited(_orientationSubscription?.cancel());
    _orientationSubscription = null;
    if (widget.orientationSensorService == null) {
      _orientationSensorService.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _teleportGeneration++;
    _badgeTeleportController.dispose();
    _shutterFlashController.dispose();
    _thumbnailScrollController.dispose();
    _detachControllerListeners(_controller);
    if (widget.controller == null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  // ── FASE 4: OS Interruption & Resource Eviction ────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _previousLifecycleState;
    _previousLifecycleState = state;

    if (state == AppLifecycleState.inactive) {
      _deactivateScreenFlash();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasInBackground = true;
      _deactivateScreenFlash();
      _orientationSubscription?.pause();
      if (widget.controller == null && _controller != null) {
        _initGeneration++;
        final oldController = _controller;
        _detachControllerListeners(oldController);
        setState(() {
          _controller = null;
        });
        oldController?.dispose();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _systemUi.hideStatusBar();
      _orientationSubscription?.resume();

      // Rekonsiliasi state otomatis (Auto-Recovery / Self-Healing):
      // Hanya dipicu ketika aplikasi kembali dari background penuh
      // (paused/hidden, misal kembali dari menu Pengaturan OS atau berpindah
      // aplikasi). Transisi fokus sementara (inactive) tidak memicu
      // inisialisasi ulang untuk mencegah infinite loop saat perizinan
      // dinonaktifkan atau terjadi galat HAL.
      final wasBackground =
          _wasInBackground ||
          previousState == AppLifecycleState.paused ||
          previousState == AppLifecycleState.hidden;
      _wasInBackground = false;

      if (wasBackground &&
          widget.controller == null &&
          _controller == null &&
          !_isInitializing) {
        _initCamera();
      }
    }
  }

  // ── FASE 2: Controller & Surface Attachment ────────────────────────────────

  Future<void> _initCamera() async {
    final generation = ++_initGeneration;

    if (widget.controller == null && _controller != null) {
      final oldController = _controller;
      _detachControllerListeners(oldController);
      _controller = null;
      await oldController?.dispose();
    }

    if (!mounted || generation != _initGeneration) return;
    setState(() {
      _isInitializing = true;
      _actionableError = null;
    });

    try {
      if (widget.cameras != null) {
        _availableCameras = widget.cameras!;
      } else {
        _availableCameras = await availableCameras();
      }

      if (_availableCameras.isEmpty) {
        if (!mounted || generation != _initGeneration) return;
        setState(() {
          _isInitializing = false;
          _actionableError = CameraActionableError.noCamerasAvailable(
            onRetry: _initCamera,
            onExit: _handleBackOrClose,
          );
        });
        return;
      }

      final camera = _availableCameras[_selectedCameraIndex];
      final isFront = camera.lensDirection == CameraLensDirection.front;

      final newController = widget.controllerFactory != null
          ? widget.controllerFactory!(camera)
          : CameraController(camera, ResolutionPreset.high, enableAudio: false);

      await newController.initialize();

      // Kunci orientasi kontroler kamera secara permanen ke portraitUp
      // agar view kamera dan viewfinder tidak pernah berotasi di layar.
      try {
        await newController.lockCaptureOrientation(
          DeviceOrientation.portraitUp,
        );
      } on Object catch (_) {
        // Abaikan jika platform tidak mendukung lock atau mock tidak distub
      }

      // Deteksi ketersediaan lampu LED fisik pada kamera aktif.
      // Kamera depan secara default tidak memiliki LED fisik (menggunakan
      // Screen Flash). Kamera belakang menguji kapabilitas hardware via
      // controller.
      final hasPhysicalFlash =
          widget.hasPhysicalFlash ??
          (!isFront && await _checkPhysicalFlashSupport(newController));
      _hasPhysicalFlash = hasPhysicalFlash;

      // Normalisasi mode flash berdasarkan ketersediaan hardware
      if (!isFront && !hasPhysicalFlash) {
        _flashMode = FlashMode.off;
      } else if (isFront && !hasPhysicalFlash) {
        if (_flashMode == FlashMode.torch || _flashMode == FlashMode.auto) {
          _flashMode = FlashMode.off;
        }
      }

      try {
        await newController.setFlashMode(_flashMode);
      } on Exception catch (_) {
        if (!isFront && !hasPhysicalFlash) {
          _flashMode = FlashMode.off;
        }
      }

      if (!mounted || generation != _initGeneration) {
        await newController.dispose();
        return;
      }

      setState(() {
        _controller = newController;
        _isInitializing = false;
        _actionableError = null;
      });
      _attachControllerListeners(newController);
    } on CameraException catch (e) {
      if (!mounted || generation != _initGeneration) return;
      setState(() {
        _isInitializing = false;
        _actionableError = CameraActionableError.fromCameraException(
          e,
          onRetry: _initCamera,
          onExit: _handleBackOrClose,
          openAppSettingsFn: _handleOpenAppSettings,
          launcherService: widget.launcherService,
          errorFormatter: widget.errorFormatter,
          isProduction: widget.isProduction,
        );
      });
    } on Object catch (e) {
      if (!mounted || generation != _initGeneration) return;
      setState(() {
        _isInitializing = false;
        _actionableError = CameraActionableError.fromInitializationError(
          e,
          onRetry: _initCamera,
          onExit: _handleBackOrClose,
          openAppSettingsFn: _handleOpenAppSettings,
          launcherService: widget.launcherService,
          errorFormatter: widget.errorFormatter,
          isProduction: widget.isProduction,
        );
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length <= 1 || _isBusy) {
      return;
    }

    _isSwitchingCamera = true;
    _initGeneration++;
    final oldController = _controller;
    _detachControllerListeners(oldController);
    final wasFront = _isCurrentCameraFront;

    // Segera unmount controller lama dari widget tree dan setel state ke
    // loading agar widget CameraPreview tidak pernah mencoba merender
    // controller yang sedang atau telah di-dispose (penyebab Error Boundary).
    // Jika senter sedang menyala, segera normalkan mode flash ke off.
    setState(() {
      _isInitializing = true;
      _controller = null;
      _switchCameraTurns -= 0.5;
      if (_flashMode == FlashMode.torch) {
        _flashMode = FlashMode.off;
      }
    });

    try {
      if (oldController != null) {
        try {
          await oldController.setFlashMode(FlashMode.off);
        } on Exception catch (_) {}
        await oldController.dispose();
      }

      final targetLens = wasFront
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      final targetIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == targetLens,
      );
      _selectedCameraIndex = targetIndex != -1
          ? targetIndex
          : (_selectedCameraIndex + 1) % _availableCameras.length;
      await _initCamera();
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingCamera = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        !_isFlashSupported) {
      return;
    }

    final isFront = _isFrontCamera(controller);
    final isScreenFlashOnly = isFront && !_hasPhysicalFlash;
    // Kamera depan tanpa LED fisik memakai siklus 2 mode untuk Screen Flash.
    // Jika kamera memiliki LED fisik (depan/belakang), pakai siklus 4 mode.
    final order = isScreenFlashOnly
        ? const [FlashMode.off, FlashMode.always]
        : const [
            FlashMode.off,
            FlashMode.auto,
            FlashMode.always,
            FlashMode.torch,
          ];

    final currentIndex = order.indexOf(_flashMode);
    final nextIndex = (currentIndex + 1) % order.length;
    final targetMode = order[nextIndex];
    final previousMode = _flashMode;

    // Optimistic UI Update: Segera perbarui state pada frame ke-0 saat tombol
    // disentuh agar animasi transisi ikon langsung meluncur seketika tanpa
    // tertahan latensi hardware platform channel kamera (150-400ms).
    setState(() => _flashMode = targetMode);

    try {
      await controller.setFlashMode(targetMode);
    } on Exception catch (_) {
      // Kamera depan tanpa LED fisik memakai Screen Flash (software brightness)
      // sehingga penolakan hardware adalah normal dan tidak boleh di-rollback.
      if (!isScreenFlashOnly && mounted) {
        setState(() => _flashMode = previousMode);
      }
    }
  }

  void _triggerShutterFlash() {
    if (!mounted) return;
    if (AppMotion.isReducedMotion(context)) {
      return;
    }
    _shutterFlashController.forward(from: 0);
  }

  // ── FASE 3: Active Operation & Pipeline Synchronization ───────────────────

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    final isFrontCamera = _isFrontCamera(controller);
    final needsScreenFlash =
        isFrontCamera && !_hasPhysicalFlash && _flashMode == FlashMode.always;

    if (needsScreenFlash) {
      _originalBrightness = await _brightnessService.currentBrightness;
      await _brightnessService.setBrightness(1);
      if (mounted) {
        setState(() => _isScreenFlashActive = true);
      }
      // Jeda 180ms agar intensitas cahaya layar sempat menerangi wajah
      // pengguna sebelum shutter sensor kamera merekam citra.
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted || !_isScreenFlashActive) {
        if (mounted) {
          setState(() => _isCapturing = false);
        }
        return;
      }
    }

    try {
      final xFile = await controller.takePicture();

      if (needsScreenFlash && mounted) {
        setState(() => _isScreenFlashActive = false);
      }
      _triggerShutterFlash();

      // Pastikan mode torch tetap menyala jika sedang aktif (proteksi reset)
      if (_flashMode == FlashMode.torch && mounted) {
        try {
          await controller.setFlashMode(FlashMode.torch);
        } on Exception catch (_) {}
      }

      // Potong berkas gambar ke rasio 9:16 (portrait) atau 16:9 (landscape)
      // dan kompresi selaras dengan galeri via [ImageCropper] (GoF Strategy / DIP)
      await widget.imageCropper.cropFileTo9x16(
        xFile.path,
        orientation: _deviceOrientation,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        quality: widget.imageQuality,
        isFrontCamera: isFrontCamera,
      );

      final mediaFile = await AppMediaFile.fromXFile(
        xFile,
        fallbackName: 'foto_kamera.jpg',
      );

      // Pra-caching tekstur gambar ke GPU cache sebelum mutasi state agar
      // tidak terjadi kedipan (flashing) saat thumbnail pertama kali dirender.
      if (mediaFile.path != null && mounted) {
        try {
          await precacheImage(FileImage(File(mediaFile.path!)), context);
        } on Exception catch (_) {
          // Abaikan kegagalan precache agar alur pengambilan foto tidak macet
        }
      }

      if (mounted) {
        setState(() {
          _latestCapturedPath = mediaFile.path;
          _photos.addCaptured(mediaFile, maxSelectable: _maxSelectable);
          _isCapturing = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_thumbnailScrollController.hasClients &&
              _thumbnailScrollController.offset != 0) {
            _thumbnailScrollController.animateTo(
              0,
              duration: AppDuration.medium2,
              curve: AppMotion.emphasized,
            );
          }
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isScreenFlashActive = false;
        });
        unawaited(
          AppActionableErrorBottomSheet.show<void>(
            context,
            data: CameraActionableError.captureFailure(
              e,
              onDismiss: () => Navigator.of(context).pop(),
              errorFormatter: widget.errorFormatter,
              isProduction: widget.isProduction,
            ),
          ),
        );
      }
    } finally {
      if (needsScreenFlash) {
        if (mounted && _isScreenFlashActive) {
          setState(() => _isScreenFlashActive = false);
        }
        await _restoreBrightness();
      }
    }
  }

  void _togglePhotoSelection(AppMediaFile photo) {
    setState(() {
      final accepted = _photos.toggleSelection(
        photo,
        maxSelectable: _maxSelectable,
      );
      if (!accepted) {
        AppSnackbar.show(
          context,
          message: 'Maksimal $_maxSelectable foto dapat dipilih.',
        );
      }
    });
  }

  void _removeCapturedPhoto(int index) {
    if (index >= 0 && index < _photos.captured.length) {
      final photo = _photos.captured[index];
      final isReducedMotion = AppMotion.isReducedMotion(context);

      if (isReducedMotion) {
        _photos.removeNow(index);
        setState(() {});
        return;
      }

      // Tandai foto untuk animasi pengempisan keluar (exit collapse).
      // Lepas dari seleksi segera agar badge counter responsif seketika.
      setState(() => _photos.beginRemoval(photo));

      // Setelah durasi animasi collapse selesai, lepas item dari list.
      Future<void>.delayed(AppDuration.short4, () {
        if (!mounted) return;
        setState(() => _photos.finishRemoval(photo));
      });
    }
  }

  void _handleBackOrClose() {
    if (_photos.selected.isNotEmpty) {
      setState(_photos.clearSelection);
      return;
    }
    _restoreSystemUI();
    _photos.cleanupUnsubmitted();
    Navigator.of(context).pop();
  }

  void _handleDone() {
    _isDoneSubmitted = true;
    _restoreSystemUI();
    Navigator.of(
      context,
    ).pop(List<AppMediaFile>.unmodifiable(_photos.selected));
  }

  Widget _buildLandscapeQuotaBadge({
    required DeviceOrientation orientation,
    required M3EColorScheme colorScheme,
    required M3ETypeScale emphasizedTypeScale,
  }) {
    final isLandscapeLeft = orientation == DeviceOrientation.landscapeLeft;
    return Positioned(
      left: isLandscapeLeft ? null : AppSpacing.space200,
      right: isLandscapeLeft ? AppSpacing.space200 : null,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _badgeFadeAnimation,
            child: ScaleTransition(
              scale: _badgeScaleAnimation,
              child: RotatedBox(
                quarterTurns: isLandscapeLeft ? 1 : 3,
                child: CameraQuotaBadge(
                  key: ValueKey<String>(
                    isLandscapeLeft
                        ? 'camera_quota_badge_landscape_left'
                        : 'camera_quota_badge_landscape_right',
                  ),
                  totalPhotos: _totalSelected,
                  maxPhotos: widget.maxPhotos,
                  colorScheme: colorScheme,
                  emphasizedTypeScale: emphasizedTypeScale,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final emphasizedTypeScale = AppTheme.emphasizedTypeScaleOf(context);
    final controller = _controller;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lightOverlayStyle,
      child: PopScope<List<AppMediaFile>>(
        canPop: _photos.selected.isEmpty,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _restoreSystemUI();
            if (!_isDoneSubmitted) {
              _photos.cleanupUnsubmitted();
            }
            return;
          }
          _handleBackOrClose();
        },
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape):
                _handleBackOrClose,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // ── Baris Atas (Header Bar): Terpisah dari view kamera ───
                    CameraTopBar(
                      topCutoutPadding: MediaQuery.viewPaddingOf(context).top,
                      onClose: _handleBackOrClose,
                      totalPhotos: _totalSelected,
                      maxPhotos: widget.maxPhotos,
                      flashMode: _flashMode,
                      deviceOrientation: _deviceOrientation,
                      orientationTurns: _orientationTurns,
                      activeBadgeOrientation: _activeBadgeOrientation,
                      badgeFadeAnimation: _badgeFadeAnimation,
                      badgeScaleAnimation: _badgeScaleAnimation,
                      hasError: _actionableError != null,
                      onToggleFlash: _canInteract ? _toggleFlash : null,
                      isFlashSupported: _isFlashSupported,
                    ),

                    // ── Viewport Kamera 9:16 dengan Kontrol Bawah ───
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AspectRatio(
                          key: const ValueKey<String>(
                            'camera_viewfinder_container',
                          ),
                          aspectRatio: ImageCropUtils.aspect9x16,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Viewfinder Kamera / State Placeholder
                                if (_isInitializing)
                                  const CameraLoadingIndicator()
                                else if (_actionableError != null)
                                  AppActionableErrorView(
                                    key: const ValueKey<String>(
                                      'camera_actionable_error_view',
                                    ),
                                    data: _actionableError!,
                                  )
                                else if (controller != null &&
                                    controller.value.isInitialized &&
                                    controller.value.previewSize != null &&
                                    controller.value.aspectRatio > 0 &&
                                    !controller.value.hasError)
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final previewAspect =
                                          1 / controller.value.aspectRatio;
                                      const targetAspect =
                                          ImageCropUtils.aspect9x16;
                                      final double scale;
                                      if (previewAspect > targetAspect) {
                                        scale = previewAspect / targetAspect;
                                      } else {
                                        scale = targetAspect / previewAspect;
                                      }
                                      return Transform.scale(
                                        scale: scale,
                                        child: Center(
                                          child: AspectRatio(
                                            aspectRatio: previewAspect,
                                            child: CameraViewfinder(
                                              controller: controller,
                                              colorScheme: colorScheme,
                                              flashMode: _flashMode,
                                              hasPhysicalFlash:
                                                  _hasPhysicalFlash,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else if (_wasInBackground)
                                  const SizedBox.shrink()
                                else
                                  const CameraLoadingIndicator(),

                                // 2. Lapisan Screen Flash Kamera Depan
                                // (Illuminated Frame Translusen).
                                if (_actionableError == null &&
                                    _isScreenFlashActive)
                                  const Positioned.fill(
                                    child: IlluminatedFrameOverlay(
                                      key: ValueKey<String>(
                                        'camera_screen_flash_overlay',
                                      ),
                                    ),
                                  ),

                                // 3. Lapisan Kilatan Tirai Rana (Shutter
                                // Flash tepat saat sensor merekam citra).
                                if (_actionableError == null)
                                  CameraShutterFlash(
                                    key: const ValueKey<String>(
                                      'camera_shutter_flash',
                                    ),
                                    animation: _shutterFlashController,
                                    colorScheme: colorScheme,
                                  ),

                                // 4. Slot Badge Kuota Mode Lanskap
                                // (Sisi Kanan Viewfinder saat Landscape Left,
                                // Sisi Kiri Viewfinder saat Landscape Right).
                                // IgnorePointer menjamin badge tidak memblokir
                                // gestur touch-to-focus pada viewfinder kamera.
                                if (_actionableError == null &&
                                    _activeBadgeOrientation.isLandscape)
                                  _buildLandscapeQuotaBadge(
                                    orientation: _activeBadgeOrientation,
                                    colorScheme: colorScheme,
                                    emphasizedTypeScale: emphasizedTypeScale,
                                  ),

                                // 6. Kontrol Bawah (Tombol Selesai,
                                // Baki Thumbnail, Shutter) dalam frame 9:16.
                                if (_actionableError == null)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: CameraBottomControls(
                                      capturedPhotos: _photos.captured,
                                      selectedPhotos: _photos.selected,
                                      scrollController:
                                          _thumbnailScrollController,
                                      latestCapturedPath: _latestCapturedPath,
                                      isCapturing: _isBusy,
                                      isScreenFlashActive: _isScreenFlashActive,
                                      colorScheme: colorScheme,
                                      isCurrentCameraFront:
                                          _isCurrentCameraFront,
                                      hasMultipleCameras:
                                          _availableCameras.length > 1,
                                      orientationTurns: _orientationTurns,
                                      switchCameraTurns: _switchCameraTurns,
                                      onSwitchCamera: _isCapturing
                                          ? null
                                          : _switchCamera,
                                      onTogglePhotoSelection:
                                          _togglePhotoSelection,
                                      onRemoveCapturedPhoto:
                                          _removeCapturedPhoto,
                                      removingPhotoPath: _photos.removingPath,
                                      onTakePicture: _takePicture,
                                      onDone: _handleDone,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
