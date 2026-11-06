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
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/image_crop_utils.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_morphing_surface.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

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
  /// Membuat instans [AppMultiShotCameraScreen].
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

  final List<AppMediaFile> _capturedPhotos = [];
  final List<AppMediaFile> _selectedPhotos = [];
  bool _isDoneSubmitted = false;
  String? _removingPhotoPath;

  int get _maxSelectable => widget.maxPhotos - widget.alreadyAttachedCount;
  int get _totalSelected =>
      widget.alreadyAttachedCount + _selectedPhotos.length;
  bool get _canSelectMore => _selectedPhotos.length < _maxSelectable;

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

  bool _hasRestoredSystemUi = false;
  AppLifecycleState? _previousLifecycleState;
  bool _wasInBackground = false;
  Timer? _autoHideTimer;
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

  void _hideStatusBar() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom],
      ),
    );
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
    final durationMs =
        (_teleportHalfDuration.inMilliseconds * clampedRatio).round();
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
            final fadeOutDuration =
                _computeTeleportDuration(_badgeTeleportController.value);
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
          final fadeInDuration =
              _computeTeleportDuration(1.0 - _badgeTeleportController.value);
          try {
            await _badgeTeleportController.animateTo(
              1,
              duration: fadeInDuration,
            );
          } on Object catch (_) {}
        } else if (_badgeTeleportController.value < 1) {
          // Orientasi fisik sudah sesuai namun animasi fade-in terputus
          final fadeInDuration =
              _computeTeleportDuration(1.0 - _badgeTeleportController.value);
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

  void _setupSystemUI() {
    _hideStatusBar();
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]),
    );
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (!mounted || _hasRestoredSystemUi) return;
      if (systemOverlaysAreVisible) {
        _autoHideTimer?.cancel();
        _autoHideTimer = Timer(const Duration(milliseconds: 1500), () {
          if (!mounted || _hasRestoredSystemUi) return;
          _hideStatusBar();
        });
      }
    });
  }

  void _restoreSystemUI() {
    if (_hasRestoredSystemUi) return;
    _hasRestoredSystemUi = true;
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
    try {
      _controller?.unlockCaptureOrientation();
    } on Object catch (_) {}
    SystemChrome.setSystemUIChangeCallback(null);
    unawaited(AppLayout.applyPreferredOrientations());
    unawaited(_restoreBrightness());
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _brightnessService =
        widget.brightnessService ?? const DefaultScreenBrightnessService();
    _setupSystemUI();

    _deviceOrientation = widget.initialDeviceOrientation ??
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

    _orientationSensorService = widget.orientationSensorService ??
        DefaultDeviceOrientationSensorService(
          initialOrientation: _deviceOrientation,
        );
    _orientationSubscription =
        _orientationSensorService.onOrientationChanged.listen(
      _onOrientationChanged,
    );

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
      _cleanupUnsubmittedPhotos();
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
      _hideStatusBar();
      _orientationSubscription?.resume();

      // Rekonsiliasi state otomatis (Auto-Recovery / Self-Healing):
      // Hanya dipicu ketika aplikasi kembali dari background penuh
      // (paused/hidden, misal kembali dari menu Pengaturan OS atau berpindah
      // aplikasi). Transisi fokus sementara (inactive) tidak memicu
      // inisialisasi ulang untuk mencegah infinite loop saat perizinan
      // dinonaktifkan atau terjadi galat HAL.
      final wasBackground = _wasInBackground ||
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
          : CameraController(
              camera,
              ResolutionPreset.high,
              enableAudio: false,
            );

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
      final hasPhysicalFlash = widget.hasPhysicalFlash ??
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

      final targetLens =
          wasFront ? CameraLensDirection.back : CameraLensDirection.front;
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
          await precacheImage(
            FileImage(File(mediaFile.path!)),
            context,
          );
        } on Exception catch (_) {
          // Abaikan kegagalan precache agar alur pengambilan foto tidak macet
        }
      }

      if (mounted) {
        setState(() {
          _latestCapturedPath = mediaFile.path;
          _capturedPhotos.insert(0, mediaFile);
          if (_canSelectMore) {
            _selectedPhotos.add(mediaFile);
          }
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
      if (_selectedPhotos.contains(photo)) {
        _selectedPhotos.remove(photo);
      } else {
        if (_canSelectMore) {
          _selectedPhotos.add(photo);
        } else {
          AppSnackbar.show(
            context,
            message: 'Maksimal $_maxSelectable foto dapat dipilih.',
          );
        }
      }
    });
  }

  void _removeCapturedPhoto(int index) {
    if (index >= 0 && index < _capturedPhotos.length) {
      final photo = _capturedPhotos[index];
      final isReducedMotion = AppMotion.isReducedMotion(context);

      if (isReducedMotion) {
        final removed = _capturedPhotos.removeAt(index);
        _selectedPhotos.remove(removed);
        setState(() {});
        return;
      }

      // Tandai foto untuk animasi pengempisan keluar (exit collapse).
      // Lepas dari seleksi segera agar badge counter responsif seketika.
      setState(() {
        _removingPhotoPath = photo.path;
        _selectedPhotos.remove(photo);
      });

      // Setelah durasi animasi collapse selesai, lepas item dari list.
      Future<void>.delayed(AppDuration.short4, () {
        if (!mounted) return;
        setState(() {
          _capturedPhotos.remove(photo);
          if (_removingPhotoPath == photo.path) {
            _removingPhotoPath = null;
          }
        });
      });
    }
  }

  void _cleanupUnsubmittedPhotos() {
    for (final photo in _capturedPhotos) {
      if (photo.path != null) {
        try {
          final file = File(photo.path!);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } on Exception catch (_) {
          // Abaikan kegagalan penghapusan berkas sementara
        }
      }
    }
    _capturedPhotos.clear();
    _selectedPhotos.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  void _handleBackOrClose() {
    if (_selectedPhotos.isNotEmpty) {
      setState(_selectedPhotos.clear);
      return;
    }
    _restoreSystemUI();
    _cleanupUnsubmittedPhotos();
    Navigator.of(context).pop();
  }

  void _handleDone() {
    _isDoneSubmitted = true;
    _restoreSystemUI();
    Navigator.of(context).pop(List<AppMediaFile>.unmodifiable(_selectedPhotos));
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
                child: _CameraQuotaBadge(
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
        canPop: _selectedPhotos.isEmpty,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _restoreSystemUI();
            if (!_isDoneSubmitted) {
              _cleanupUnsubmittedPhotos();
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
                    _CameraTopBar(
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
                                  const _CameraLoadingIndicator()
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
                                            child: _CameraViewfinder(
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
                                  const _CameraLoadingIndicator(),

                                // 2. Lapisan Screen Flash Kamera Depan
                                // (Illuminated Frame Translusen).
                                if (_actionableError == null &&
                                    _isScreenFlashActive)
                                  const Positioned.fill(
                                    child: _IlluminatedFrameOverlay(
                                      key: ValueKey<String>(
                                        'camera_screen_flash_overlay',
                                      ),
                                    ),
                                  ),

                                // 3. Lapisan Kilatan Tirai Rana (Shutter
                                // Flash tepat saat sensor merekam citra).
                                if (_actionableError == null)
                                  _CameraShutterFlash(
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
                                    child: _CameraBottomControls(
                                      capturedPhotos: _capturedPhotos,
                                      selectedPhotos: _selectedPhotos,
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
                                      onSwitchCamera:
                                          _isCapturing ? null : _switchCamera,
                                      onTogglePhotoSelection:
                                          _togglePhotoSelection,
                                      onRemoveCapturedPhoto:
                                          _removeCapturedPhoto,
                                      removingPhotoPath: _removingPhotoPath,
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

// ─────────────────────────────────────────────────────────────────────────────
// Subkomponen Molekul Atomik (Atomic Design)
// ─────────────────────────────────────────────────────────────────────────────

/// Indikator pemuatan viewport kamera dengan tema terang (Light Theme)
/// Material 3 Expressive dan label semantik aksesibilitas.
class _CameraLoadingIndicator extends StatelessWidget {
  const _CameraLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: M3ETheme(
        data: AppTheme.m3eDark(),
        child: Theme(
          data: AppTheme.darkThemeData(),
          child: const AppLoadingIndicator(
            semanticLabel: 'Menyiapkan kamera',
          ),
        ),
      ),
    );
  }
}

/// Molekul viewfinder kamera dengan gesture touch-to-focus
/// dan indikator reticle Material 3 Expressive.
class _CameraViewfinder extends StatefulWidget {
  const _CameraViewfinder({
    required this.controller,
    required this.colorScheme,
    required this.flashMode,
    this.hasPhysicalFlash = false,
  });

  final CameraController controller;
  final M3EColorScheme colorScheme;
  final FlashMode flashMode;
  final bool hasPhysicalFlash;

  @override
  State<_CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<_CameraViewfinder>
    with TickerProviderStateMixin {
  Offset? _focusPosition;
  late final AnimationController _entryController;
  late final AnimationController _exitController;
  Timer? _hideTimer;
  Timer? _dismissTimer;
  bool _isAfAssistActive = false;
  bool _isFocusUnsupportedOnDevice = false;
  bool _isExposureUnsupportedOnDevice = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController.unbounded(
      vsync: this,
      duration: AppDuration.medium1,
    );
    _exitController = AnimationController(
      vsync: this,
      duration: AppDuration.short3,
    );
  }

  @override
  void didUpdateWidget(covariant _CameraViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _isFocusUnsupportedOnDevice = false;
      _isExposureUnsupportedOnDevice = false;
    }
    if (oldWidget.flashMode != widget.flashMode && _isAfAssistActive) {
      _deactivateAfAssist();
    }
  }

  @override
  void dispose() {
    _deactivateAfAssist();
    _hideTimer?.cancel();
    _dismissTimer?.cancel();
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _deactivateAfAssist() async {
    if (_isAfAssistActive) {
      _isAfAssistActive = false;
      try {
        await widget.controller.setFlashMode(widget.flashMode);
      } on Object catch (_) {
        // Abaikan error hardware saat restorasi mode flash
      }
    }
  }

  Future<void> _handleTapDown(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    final local = details.localPosition;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    if (width <= 0 || height <= 0) return;

    final controller = widget.controller;
    if (!controller.value.isInitialized) return;

    // Periksa kapabilitas hardware aktual untuk titik fokus dan eksposur
    final isFocusSupported = controller.value.focusPointSupported;
    final isExposureSupported = controller.value.exposurePointSupported;

    // Jika perangkat sama sekali tidak mendukung titik fokus maupun eksposur
    // (misalnya sensor fixed-focus murni tanpa kustomisasi metering),
    // abaikan ketukan agar tidak memunculkan indikator palsu.
    if (!isFocusSupported && !isExposureSupported) return;

    // Normalisasi koordinat ke rentang [0.0, 1.0] untuk CameraController
    final nx = (local.dx / width).clamp(0.0, 1.0);
    final ny = (local.dy / height).clamp(0.0, 1.0);

    setState(() {
      _focusPosition = local;
    });

    _hideTimer?.cancel();
    _dismissTimer?.cancel();
    _exitController.reset();

    final isReducedMotion = AppMotion.isReducedMotion(context);
    if (isReducedMotion) {
      _entryController.value = 1;
    } else {
      _entryController.value = 0;
      final simulation = AppMotion.createSimulation(
        AppMotion.expressiveSpatialFast,
        start: 0,
        end: 1,
      );
      _entryController.animateWith(simulation);
    }

    // Haptic feedback saat mengetuk untuk memfokuskan (Material 3 standard)
    unawaited(HapticFeedback.lightImpact());

    // AF Assist Lamp: nyalakan senter sementara jika flashMode adalah always
    // pada kamera yang memiliki modul LED fisik untuk membantu penguncian
    // fokus di ruang gelap.
    final canUseAfAssist =
        widget.hasPhysicalFlash && widget.flashMode == FlashMode.always;
    if (canUseAfAssist) {
      _isAfAssistActive = true;
      try {
        await controller.setFlashMode(FlashMode.torch);
      } on Object catch (_) {
        // Abaikan jika modul tidak mendukung torch
      }
    }

    try {
      if (isFocusSupported && !_isFocusUnsupportedOnDevice) {
        await controller.setFocusPoint(Offset(nx, ny));
      }
    } on Object catch (_) {
      // Tandai modul kamera tidak mendukung titik fokus kustom
      _isFocusUnsupportedOnDevice = true;
    }

    try {
      if (isExposureSupported && !_isExposureUnsupportedOnDevice) {
        await controller.setExposurePoint(Offset(nx, ny));
      }
    } on Object catch (_) {
      // Tandai modul kamera tidak mendukung titik eksposur kustom
      _isExposureUnsupportedOnDevice = true;
    }

    // Reticle bertengger selama 1250ms, lalu memudar keluar selama 150ms.
    // Total waktu kemunculan: 1400ms (< 1600ms batas auto-hide unit test).
    _hideTimer = Timer(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      _deactivateAfAssist();
      if (isReducedMotion) {
        setState(() {
          _focusPosition = null;
        });
      } else {
        _exitController.forward(from: 0);
      }
    });

    _dismissTimer = Timer(const Duration(milliseconds: 1450), () {
      if (mounted) {
        _deactivateAfAssist();
        setState(() {
          _focusPosition = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    // Guard pencegah race condition layout pass terhadap controller
    // yang belum siap, telah di-dispose, atau mengalami runtime error.
    if (!controller.value.isInitialized || controller.value.hasError) {
      return const _CameraLoadingIndicator();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          key: const ValueKey<String>('camera_preview_gesture_detector'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTapDown(details, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              if (_focusPosition != null)
                _FocusReticle(
                  key: const ValueKey<String>('camera_focus_reticle'),
                  position: _focusPosition!,
                  entryAnimation: _entryController,
                  exitAnimation: _exitController,
                  colorScheme: widget.colorScheme,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Atom indikator reticle visual untuk interaksi touch-to-focus M3 Expressive.
class _FocusReticle extends StatelessWidget {
  const _FocusReticle({
    required this.position,
    required this.entryAnimation,
    required this.exitAnimation,
    required this.colorScheme,
    super.key,
  });

  final Offset position;
  final Animation<double> entryAnimation;
  final Animation<double> exitAnimation;
  final M3EColorScheme colorScheme;

  static const double _reticleSize = 64;

  @override
  Widget build(BuildContext context) {
    final isReducedMotion = AppMotion.isReducedMotion(context);

    return Positioned(
      left: position.dx - (_reticleSize / 2),
      top: position.dy - (_reticleSize / 2),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([entryAnimation, exitAnimation]),
            builder: (context, _) {
              final entryProgress = entryAnimation.value;
              final exitProgress =
                  Curves.easeIn.transform(exitAnimation.value.clamp(0.0, 1.0));

              // 1. Skala Pegas Spasial M3 Expressive
              // Masuk: snap dari 1.35 ke 1.0 dengan overshoot pegas
              // Keluar: menyusut halus dari 1.0 ke 0.85
              final double scale;
              if (isReducedMotion) {
                scale = 1.0;
              } else {
                final entryScale = 1.35 - (0.35 * entryProgress);
                final exitScaleFactor = 1.0 - (0.15 * exitProgress);
                scale = entryScale * exitScaleFactor;
              }

              // 2. Opasitas Efek M3 Expressive (masuk cepat, keluar memudar)
              final entryOpacity = (entryProgress * 3.0).clamp(0.0, 1.0);
              final exitOpacity = 1.0 - exitProgress;
              final overallOpacity =
                  (entryOpacity * exitOpacity).clamp(0.0, 1.0);

              // 3. Gelombang Gema Luar (Echo Ripple Wave)
              final rippleScale = 1.0 + (0.45 * entryProgress.clamp(0.0, 1.0));
              final rippleOpacity = isReducedMotion
                  ? 0.0
                  : ((1.0 - entryProgress.clamp(0.0, 1.0)) * 0.50 * exitOpacity)
                      .clamp(0.0, 1.0);

              return Opacity(
                opacity: overallOpacity,
                child: SizedBox(
                  width: _reticleSize,
                  height: _reticleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // A. Gelombang Gema Luar (Echo Ripple)
                      if (rippleOpacity > 0.01)
                        Transform.scale(
                          scale: rippleScale,
                          child: Container(
                            width: _reticleSize,
                            height: _reticleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: rippleOpacity,
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                      // B. Cincin Fokus Utama M3 Expressive
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: _reticleSize,
                          height: _reticleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              // 1. Key Shadow (Tepi Presisi & Kontras)
                              BoxShadow(
                                color:
                                    colorScheme.scrim.withValues(alpha: 0.40),
                                blurRadius: 2,
                                spreadRadius: 0.5,
                              ),
                              // 2. Ambient Shadow (Pendaran Halus Lembut)
                              BoxShadow(
                                color:
                                    colorScheme.scrim.withValues(alpha: 0.20),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 4 Aksen Kuadran Kardinal
                              _CardinalFocusTicks(
                                color: colorScheme.primary,
                                shadowColor: colorScheme.scrim.withValues(
                                  alpha: 0.40,
                                ),
                              ),

                              // Titik Presisi Tengah
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.scrim.withValues(
                                        alpha: 0.40,
                                      ),
                                      blurRadius: 1.5,
                                      spreadRadius: 0.5,
                                    ),
                                    BoxShadow(
                                      color: colorScheme.scrim.withValues(
                                        alpha: 0.20,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Aksen kuadran kardinal pada cincin fokus Material 3 Expressive.
class _CardinalFocusTicks extends StatelessWidget {
  const _CardinalFocusTicks({
    required this.color,
    required this.shadowColor,
  });

  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 64),
      painter: _CardinalTicksPainter(
        color: color,
        shadowColor: shadowColor,
      ),
    );
  }
}

class _CardinalTicksPainter extends CustomPainter {
  const _CardinalTicksPainter({
    required this.color,
    required this.shadowColor,
  });

  final Color color;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const double tickLen = 4;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    _drawTicks(canvas, center, radius, tickLen, shadowPaint);
    _drawTicks(canvas, center, radius, tickLen, tickPaint);
  }

  void _drawTicks(
    Canvas canvas,
    Offset center,
    double radius,
    double tickLen,
    Paint paint,
  ) {
    canvas
      ..drawLine(
        Offset(center.dx, center.dy - radius - 2),
        Offset(center.dx, center.dy - radius + tickLen),
        paint,
      )
      ..drawLine(
        Offset(center.dx, center.dy + radius + 2),
        Offset(center.dx, center.dy + radius - tickLen),
        paint,
      )
      ..drawLine(
        Offset(center.dx - radius - 2, center.dy),
        Offset(center.dx - radius + tickLen, center.dy),
        paint,
      )
      ..drawLine(
        Offset(center.dx + radius + 2, center.dy),
        Offset(center.dx + radius - tickLen, center.dy),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CardinalTicksPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
}

/// Atom indikator kuota foto kamera multi-shot.
class _CameraQuotaBadge extends StatelessWidget {
  const _CameraQuotaBadge({
    required this.totalPhotos,
    required this.maxPhotos,
    required this.colorScheme,
    required this.emphasizedTypeScale,
    super.key,
  });

  final int totalPhotos;
  final int maxPhotos;
  final M3EColorScheme colorScheme;
  final M3ETypeScale emphasizedTypeScale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$totalPhotos dari $maxPhotos foto dipilih',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space150,
          vertical: AppSpacing.space50,
        ),
        decoration: BoxDecoration(
          color: colorScheme.scrim.withValues(alpha: 0.60),
          borderRadius: AppRadius.borderFull,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSvgIcon(
              KawaloVectors.camera01,
              size: 16,
              color: Colors.white,
            ),
            AppSpacing.hGap100,
            Text(
              '$totalPhotos / $maxPhotos foto',
              style: emphasizedTypeScale.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper pembangun dekorasi tombol overlay translusen kamera Material 3
/// Expressive.
M3EIconButtonDecoration _buildCameraOverlayButtonDecoration({
  required M3EColorScheme colorScheme,
  bool isScreenFlashActive = false,
}) {
  return M3EIconButtonDecoration(
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) {
        if (isScreenFlashActive) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.black.withValues(
              alpha: 0.12 * AppStateLayer.disabledContainerOpacity,
            );
          }
          return Colors.black.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.scrim.withValues(
            alpha: 0.60 * AppStateLayer.disabledContainerOpacity,
          );
        }
        return colorScheme.scrim.withValues(alpha: 0.60);
      },
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) {
        if (isScreenFlashActive) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.black.withValues(
              alpha: AppStateLayer.disabledOpacity,
            );
          }
          return Colors.black;
        }
        if (states.contains(WidgetState.disabled)) {
          return Colors.white.withValues(
            alpha: AppStateLayer.disabledOpacity,
          );
        }
        return Colors.white;
      },
    ),
    side: WidgetStateProperty.resolveWith(
      (states) {
        if (isScreenFlashActive) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: Colors.black.withValues(
                alpha: 0.20 * AppStateLayer.disabledOpacity,
              ),
            );
          }
          return BorderSide(
            color: Colors.black.withValues(alpha: 0.20),
          );
        }
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: Colors.white.withValues(
              alpha: 0.30 * AppStateLayer.disabledOpacity,
            ),
          );
        }
        return BorderSide(
          color: Colors.white.withValues(alpha: 0.30),
        );
      },
    ),
  );
}

/// Molekul bar navigasi atas kamera (tutup, indikator kuota, flash).
class _CameraTopBar extends StatelessWidget {
  const _CameraTopBar({
    required this.onClose,
    required this.totalPhotos,
    required this.maxPhotos,
    required this.flashMode,
    required this.deviceOrientation,
    required this.orientationTurns,
    required this.activeBadgeOrientation,
    required this.badgeFadeAnimation,
    required this.badgeScaleAnimation,
    this.onToggleFlash,
    this.isFlashSupported = true,
    this.topCutoutPadding = 0,
    this.hasError = false,
  });

  final VoidCallback onClose;
  final int totalPhotos;
  final int maxPhotos;
  final FlashMode flashMode;
  final DeviceOrientation deviceOrientation;
  final double orientationTurns;
  final DeviceOrientation activeBadgeOrientation;
  final Animation<double> badgeFadeAnimation;
  final Animation<double> badgeScaleAnimation;
  final VoidCallback? onToggleFlash;
  final bool isFlashSupported;
  final double topCutoutPadding;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final emphasizedTypeScale = AppTheme.emphasizedTypeScaleOf(context);
    final isReducedMotion = AppMotion.isReducedMotion(context);
    final isTopBarBadgeActive = activeBadgeOrientation.isPortrait;
    final isPortraitDown =
        activeBadgeOrientation == DeviceOrientation.portraitDown;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        top: topCutoutPadding + AppSpacing.space100,
        bottom: AppSpacing.space100,
        left: AppSpacing.space200,
        right: AppSpacing.space200,
      ),
      child: Row(
        children: [
          // Sayap Kiri: Tombol Batal/Tutup
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppIconButton(
                key: const ValueKey<String>('camera_close_button'),
                semanticLabel: 'Tutup kamera',
                onPressed: onClose,
                haptic: M3EHapticFeedback.light,
                decoration: M3EIconButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.scrim.withValues(alpha: 0.60),
                  ),
                  foregroundColor: const WidgetStatePropertyAll(
                    Colors.white,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                ),
                icon: const AppSvgIcon(
                  KawaloVectors.cancel01,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Tengah: Badge Indikator Kuota Foto M3 Expressive Seimbang
          // (Zero-Layout Shift: Dimensi layout tetap dipertahankan meski
          // badge memudar keluar saat mode lanskap. Disembunyikan saat error).
          if (!hasError)
            FadeTransition(
              key: const ValueKey<String>('camera_quota_badge'),
              opacity: isTopBarBadgeActive
                  ? badgeFadeAnimation
                  : const AlwaysStoppedAnimation(0),
              child: ScaleTransition(
                scale: isTopBarBadgeActive
                    ? badgeScaleAnimation
                    : const AlwaysStoppedAnimation(1),
                child: IgnorePointer(
                  ignoring: !isTopBarBadgeActive,
                  child: RotatedBox(
                    quarterTurns: isPortraitDown ? 2 : 0,
                    child: _CameraQuotaBadge(
                      totalPhotos: totalPhotos,
                      maxPhotos: maxPhotos,
                      colorScheme: colorScheme,
                      emphasizedTypeScale: emphasizedTypeScale,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          // Sayap Kanan: Kontrol Flash (atau slot kosong jika tidak didukung/error)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: (!hasError && isFlashSupported)
                  ? AppIconButton(
                      key: const ValueKey<String>('camera_flash_button'),
                      semanticLabel: _flashSemanticLabel(flashMode),
                      onPressed: onToggleFlash,
                      haptic: M3EHapticFeedback.light,
                      decoration: _buildCameraOverlayButtonDecoration(
                        colorScheme: colorScheme,
                      ),
                      icon: AnimatedRotation(
                        turns: orientationTurns,
                        duration: isReducedMotion
                            ? Duration.zero
                            : AppMultiShotCameraScreen.rotationDuration,
                        curve: AppMultiShotCameraScreen.rotationCurve,
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            key: const ValueKey<String>(
                              'camera_flash_switcher',
                            ),
                            duration: isReducedMotion
                                ? Duration.zero
                                : AppDuration.medium2,
                            switchInCurve: Curves.easeInOutCubic,
                            switchOutCurve: Curves.easeInOutCubic.flipped,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (child, animation) {
                              final isIncoming =
                                  child.key == ValueKey<FlashMode>(flashMode);
                              final inTween = Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              );
                              final outTween = Tween<Offset>(
                                begin: const Offset(0, -1),
                                end: Offset.zero,
                              );
                              final offsetAnimation =
                                  (isIncoming ? inTween : outTween)
                                      .animate(animation);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: AppSvgIcon(
                              key: ValueKey<FlashMode>(flashMode),
                              _flashIcon(flashMode),
                              color: _flashIconColor(
                                flashMode,
                                isEnabled: onToggleFlash != null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  static const Color _activeFlashAmber = Color(0xFFFFD54F);

  static Color _flashIconColor(
    FlashMode mode, {
    required bool isEnabled,
  }) {
    final isAmber = mode == FlashMode.always || mode == FlashMode.torch;
    final baseColor = isAmber ? _activeFlashAmber : Colors.white;
    if (!isEnabled) {
      return baseColor.withValues(alpha: AppStateLayer.disabledOpacity);
    }
    return baseColor;
  }

  static String _flashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return KawaloVectors.flashAuto;
      case FlashMode.always:
        return KawaloVectors.flash;
      case FlashMode.torch:
        return KawaloVectors.flashTorch;
      case FlashMode.off:
        return KawaloVectors.flashOff;
    }
  }

  static String _flashSemanticLabel(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return 'Lampu kilat otomatis';
      case FlashMode.always:
        return 'Lampu kilat selalu menyala saat foto';
      case FlashMode.torch:
        return 'Lampu senter terus menyala';
      case FlashMode.off:
        return 'Lampu kilat mati';
    }
  }
}

/// Molekul baki thumbnail foto yang ditangkap pada sesi berjalan.
class _CameraThumbnailTray extends StatelessWidget {
  const _CameraThumbnailTray({
    required this.photos,
    required this.selectedPhotos,
    required this.scrollController,
    required this.colorScheme,
    required this.onToggleSelection,
    required this.onRemovePhoto,
    this.orientationTurns = 0,
    this.latestCapturedPath,
    this.removingPhotoPath,
  });

  final List<AppMediaFile> photos;
  final List<AppMediaFile> selectedPhotos;
  final ScrollController scrollController;
  final String? latestCapturedPath;
  final String? removingPhotoPath;
  final M3EColorScheme colorScheme;
  final double orientationTurns;
  final ValueChanged<AppMediaFile> onToggleSelection;
  final ValueChanged<int> onRemovePhoto;

  static const double _thumbnailSize = 72;
  static const double _deleteButtonSize = 20;
  static const double _deleteButtonOffset = _deleteButtonSize / 4;
  static const double _itemSize = _thumbnailSize + _deleteButtonOffset;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isReducedMotion = AppMotion.isReducedMotion(context);

    return RepaintBoundary(
      child: SizedBox(
        height: _itemSize,
        child: ListView.separated(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space300,
          ),
          itemCount: photos.length,
          separatorBuilder: (context, sepIndex) {
            // Animasi masuk separator baru (0 -> 8dp) saat foto terbaru masuk
            final isFirstSepNewest = sepIndex == 0 &&
                photos.isNotEmpty &&
                photos.first.path != null &&
                photos.first.path == latestCapturedPath;
            if (isFirstSepNewest && !isReducedMotion) {
              return TweenAnimationBuilder<double>(
                key: ValueKey<String>('tray_sep_${photos.first.path}'),
                tween: Tween<double>(begin: 0, end: 1),
                duration: AppDuration.medium2,
                curve: AppMotion.emphasized,
                builder: (_, val, __) => SizedBox(
                  width: AppSpacing.space100 * val,
                ),
              );
            }

            // Animasi keluar separator (8dp -> 0) saat foto di sampingnya
            // sedang dihapus (collapse horizontal mulus)
            if (removingPhotoPath != null && !isReducedMotion) {
              final isAdjacentToRemoving =
                  (sepIndex < photos.length &&
                      photos[sepIndex].path == removingPhotoPath) ||
                  (sepIndex + 1 < photos.length &&
                      photos[sepIndex + 1].path == removingPhotoPath);
              if (isAdjacentToRemoving) {
                return TweenAnimationBuilder<double>(
                  key: ValueKey<String>(
                    'tray_sep_removing_$removingPhotoPath',
                  ),
                  tween: Tween<double>(begin: 1, end: 0),
                  duration: AppDuration.short4,
                  curve: Curves.easeInCubic,
                  builder: (_, val, __) => SizedBox(
                    width: AppSpacing.space100 * val,
                  ),
                );
              }
            }

            return AppSpacing.hGap100;
          },
          itemBuilder: (context, index) {
            final photo = photos[index];
            final isSelected = selectedPhotos.contains(photo);
            final selectionIndex =
                isSelected ? selectedPhotos.indexOf(photo) : -1;
            final isNewest = photo.path != null &&
                photo.path == latestCapturedPath &&
                index == 0;
            final photoKey = photo.path ?? '$index';

            final cardWidget = RepaintBoundary(
              child: SizedBox(
                key: ValueKey<String>('tray_item_$photoKey'),
                width: _itemSize,
                height: _itemSize,
                child: AnimatedRotation(
                  turns: orientationTurns,
                  duration: isReducedMotion
                      ? Duration.zero
                      : AppMultiShotCameraScreen.rotationDuration,
                  curve: AppMultiShotCameraScreen.rotationCurve,
                  alignment: const Alignment(-5 / 77, 5 / 77),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Kartu Thumbnail 1:1 Murni (Bebas dari tombol hapus)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        width: _thumbnailSize,
                        height: _thumbnailSize,
                        child: AppMorphingSurface(
                          key: ValueKey<String>('captured_thumbnail_$photoKey'),
                          onTap: () => onToggleSelection(photo),
                          border: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          semanticLabel: isSelected
                              ? 'Foto ke-${index + 1} terpilih '
                                  '(urutan ke-${selectionIndex + 1})'
                              : 'Pilih foto ke-${index + 1}',
                          overlay: IgnorePointer(
                            child: AnimatedSwitcher(
                              duration: isReducedMotion
                                  ? Duration.zero
                                  : AppDuration.short4,
                              reverseDuration: isReducedMotion
                                  ? Duration.zero
                                  : AppDuration.short3,
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.80,
                                      end: 1,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: isSelected
                                  ? Center(
                                      key: ValueKey<String>(
                                        'selected_${photo.path}_'
                                        '$selectionIndex',
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          // Ikon centang putih di tengah
                                          const AppSvgIcon(
                                            KawaloVectors.check,
                                            size: 28,
                                            color: Colors.white,
                                          ),

                                          // Urutan pilihan di kanan bawah ikon
                                          Positioned(
                                            left: 20,
                                            top: 14,
                                            child: Text(
                                              '${selectionIndex + 1}',
                                              style: theme.typography.emphasized
                                                  .labelMedium
                                                  .copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey<String>(
                                        'unselected_overlay',
                                      ),
                                    ),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (photo.path != null && photo.path!.isNotEmpty)
                                Image.file(
                                  File(photo.path!),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  excludeFromSemantics: true,
                                  frameBuilder: (
                                    context,
                                    child,
                                    frame,
                                    wasSynchronouslyLoaded,
                                  ) {
                                    if (wasSynchronouslyLoaded ||
                                        frame != null) {
                                      return child;
                                    }
                                    return const AppImagePlaceholder(
                                      borderRadius: BorderRadius.zero,
                                      width: double.infinity,
                                      height: double.infinity,
                                      iconSize: 24,
                                      iconPath: KawaloVectors.image02Filled,
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const AppImagePlaceholder(
                                    borderRadius: BorderRadius.zero,
                                    width: double.infinity,
                                    height: double.infinity,
                                    iconSize: 24,
                                    iconPath: KawaloVectors.imageNotFound01,
                                  ),
                                )
                              else
                                const AppImagePlaceholder(
                                  borderRadius: BorderRadius.zero,
                                  width: double.infinity,
                                  height: double.infinity,
                                  iconSize: 24,
                                  iconPath: KawaloVectors.image02Filled,
                                ),
                              // Scrim halus pada foto yang terpilih dengan
                              // transisi animasi fade.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedContainer(
                                    duration: isReducedMotion
                                        ? Duration.zero
                                        : AppDuration.short4,
                                    curve: AppMotion.standard,
                                    color: isSelected
                                        ? colorScheme.scrim.withValues(
                                            alpha: 0.24,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Tombol Hapus Mengambang di Pojok Kanan Atas
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SizedBox(
                          width: _deleteButtonSize,
                          height: _deleteButtonSize,
                          child: AppIconButton(
                            key: ValueKey<String>(
                              'remove_captured_photo_$photoKey',
                            ),
                            onPressed: () => onRemovePhoto(index),
                            semanticLabel: 'Hapus foto ke-${index + 1}',
                            size: AppIconButtonSize.xs,
                            visualSize: const Size(
                              _deleteButtonSize,
                              _deleteButtonSize,
                            ),
                            haptic: M3EHapticFeedback.light,
                            decoration: M3EIconButtonDecoration(
                              backgroundColor: WidgetStatePropertyAll(
                                colorScheme.error,
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                colorScheme.onError,
                              ),
                              side: WidgetStatePropertyAll(
                                BorderSide(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            icon: AppSvgIcon(
                              KawaloVectors.cancel01,
                              size: 12,
                              color: colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            // Animasi pengempisan keluar (exit collapse) saat foto dihapus.
            // Tanpa ClipRect agar thumbnail tidak terpotong (terselip/terswipe).
            final isRemoving = photo.path != null &&
                photo.path == removingPhotoPath;
            if (isRemoving && !isReducedMotion) {
              return SizedBox(
                key: ValueKey<String>('tray_item_removing_$photoKey'),
                height: _itemSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1, end: 0),
                  duration: AppDuration.short4,
                  curve: Curves.easeInCubic,
                  builder: (context, val, child) {
                    return SizedBox(
                      width: _itemSize * val,
                      height: _itemSize,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: _itemSize,
                        maxWidth: _itemSize,
                        minHeight: _itemSize,
                        maxHeight: _itemSize,
                        child: Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.80 + (0.20 * val),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: cardWidget,
                ),
              );
            }

            // Animasi pemekaran masuk (enter expand) saat foto baru ditangkap.
            // Tanpa ClipRect agar thumbnail tampil utuh dan mulus tanpa
            // efek terpotong (swipe-cut).
            if (isNewest && !isReducedMotion) {
              return SizedBox(
                key: ValueKey<String>('tray_item_animated_$photoKey'),
                height: _itemSize,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey<String>('tray_newest_$photoKey'),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppDuration.medium2,
                  curve: AppMotion.emphasized,
                  builder: (context, val, child) {
                    return SizedBox(
                      width: _itemSize * val,
                      height: _itemSize,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: _itemSize,
                        maxWidth: _itemSize,
                        minHeight: _itemSize,
                        maxHeight: _itemSize,
                        child: Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.85 + (0.15 * val),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: cardWidget,
                ),
              );
            }

            return cardWidget;
          },
        ),
      ),
    );
  }
}

/// Molekul tombol shutter besar Material 3 Expressive.
class _CameraShutterButton extends StatelessWidget {
  const _CameraShutterButton({
    required this.canCapture,
    required this.isCapturing,
    required this.colorScheme,
    required this.onTap,
    this.isScreenFlashActive = false,
  });

  final bool canCapture;
  final bool isCapturing;
  final M3EColorScheme colorScheme;
  final VoidCallback onTap;
  final bool isScreenFlashActive;

  static const double _buttonSize = 72;
  static const double _strokeWidth = 4;

  @override
  Widget build(BuildContext context) {
    final isReducedMotion = AppMotion.isReducedMotion(context);

    // Label aksesibilitas dinamis Material 3
    final String semanticLabel;
    if (isCapturing) {
      semanticLabel = 'Sedang memproses foto';
    } else {
      semanticLabel = 'Ambil foto';
    }

    return AppTappable.builder(
      key: const ValueKey<String>('camera_shutter_button'),
      onTap: canCapture ? onTap : null,
      enabled: canCapture,
      pressedScale: 1, // Pertahankan housing lingkar luar tetap stabil
      haptic: M3EHapticFeedback.medium,
      semanticLabel: semanticLabel,
      builder: (context, state) {
        final isPressed = state.pressed && canCapture;

        // Skala inti dalam: saat ditekan mengecil halus (0.88),
        // saat capturing/sibuk berada di 0.92, saat normal 1.0.
        final double coreScale;
        if (isReducedMotion) {
          coreScale = 1;
        } else if (isPressed) {
          coreScale = 0.88;
        } else if (isCapturing) {
          coreScale = 0.92;
        } else {
          coreScale = 1;
        }

        // Warna dasar bergantung pada state screen flash (inversi dark theme)
        final baseColor = isScreenFlashActive ? Colors.black : Colors.white;

        // Warna piringan inti dalam
        final Color coreColor;
        if (isCapturing) {
          coreColor = baseColor.withValues(
            alpha: AppStateLayer.disabledOpacity,
          );
        } else if (canCapture) {
          coreColor = baseColor;
        } else {
          coreColor = baseColor.withValues(
            alpha: AppStateLayer.disabledContainerOpacity,
          );
        }

        // Warna lingkar luar (housing)
        final Color ringColor;
        if (canCapture) {
          ringColor = baseColor;
        } else {
          ringColor = baseColor.withValues(
            alpha: AppStateLayer.disabledOpacity,
          );
        }

        return SizedBox(
          width: _buttonSize,
          height: _buttonSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Lingkar Luar (Housing Ring)
              AnimatedContainer(
                duration: isReducedMotion ? Duration.zero : AppDuration.short3,
                curve: AppEasing.standard,
                width: _buttonSize,
                height: _buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ringColor,
                    width: _strokeWidth,
                  ),
                ),
              ),

              // 2. Piringan Inti Shutter M3 Expressive
              AnimatedScale(
                scale: coreScale,
                duration: isReducedMotion ? Duration.zero : AppDuration.short3,
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration:
                      isReducedMotion ? Duration.zero : AppDuration.short3,
                  curve: AppEasing.standard,
                  width: _buttonSize - 12,
                  height: _buttonSize - 12,
                  decoration: BoxDecoration(
                    color: coreColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Organisme kontrol bawah (tombol selesai, baki thumbnail, shutter, switch).
class _CameraBottomControls extends StatelessWidget {
  const _CameraBottomControls({
    required this.capturedPhotos,
    required this.selectedPhotos,
    required this.scrollController,
    required this.isCapturing,
    required this.colorScheme,
    required this.hasMultipleCameras,
    required this.onTogglePhotoSelection,
    required this.onRemoveCapturedPhoto,
    required this.onTakePicture,
    required this.onDone,
    this.orientationTurns = 0,
    this.switchCameraTurns = 0,
    this.isScreenFlashActive = false,
    this.isCurrentCameraFront = false,
    this.onSwitchCamera,
    this.latestCapturedPath,
    this.removingPhotoPath,
  });

  final List<AppMediaFile> capturedPhotos;
  final List<AppMediaFile> selectedPhotos;
  final ScrollController scrollController;
  final String? latestCapturedPath;
  final String? removingPhotoPath;
  final bool isCapturing;
  final bool isScreenFlashActive;
  final bool isCurrentCameraFront;
  final M3EColorScheme colorScheme;
  final bool hasMultipleCameras;
  final double orientationTurns;
  final double switchCameraTurns;
  final VoidCallback? onSwitchCamera;
  final ValueChanged<AppMediaFile> onTogglePhotoSelection;
  final ValueChanged<int> onRemoveCapturedPhoto;
  final VoidCallback onTakePicture;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final canCapture = !isCapturing;
    final hasSelected = selectedPhotos.isNotEmpty;

    final isReducedMotion = AppMotion.isReducedMotion(context);
    final switchIconBaseColor =
        isScreenFlashActive ? Colors.black : Colors.white;
    final switchIconColor = onSwitchCamera != null
        ? switchIconBaseColor
        : switchIconBaseColor.withValues(
            alpha: AppStateLayer.disabledOpacity,
          );

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space200,
        bottom: AppSpacing.space200,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Baris Tombol Selesai & Baki Thumbnail ────────────────────
          // Berupa slot langsung tanpa animasi ekspansi vertikal
          // (AnimatedSize), sehingga elemen foto dan tombol selesai
          // langsung muncul di posisinya tanpa reflow melompat.
          if (capturedPhotos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space200,
              ),
              child: SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: isReducedMotion
                        ? Duration.zero
                        : AppDuration.medium2,
                    reverseDuration: isReducedMotion
                        ? Duration.zero
                        : AppDuration.short4,
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.80,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: hasSelected
                        ? AnimatedRotation(
                            turns: orientationTurns,
                            duration: isReducedMotion
                                ? Duration.zero
                                : AppMultiShotCameraScreen
                                    .rotationDuration,
                            curve: AppMultiShotCameraScreen
                                .rotationCurve,
                            child: AppIconButton(
                              key: const ValueKey<String>(
                                'camera_done_button',
                              ),
                              variant: AppIconButtonColor.filled,
                              size: AppIconButtonSize.md,
                              semanticLabel:
                                  'Selesai mengambil foto '
                                  '(${selectedPhotos.length} '
                                  'foto dipilih)',
                              badgeValue: selectedPhotos.length,
                              badgeColor:
                                  colorScheme.surfaceContainerHigh,
                              badgeTextColor:
                                  colorScheme.onSurface,
                              haptic: M3EHapticFeedback.medium,
                              onPressed: onDone,
                              icon: AppSvgIcon(
                                KawaloVectors.check,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey<String>(
                              'empty_done_slot',
                            ),
                          ),
                  ),
                ),
              ),
            ),
            AppSpacing.vGap150,
            _CameraThumbnailTray(
              photos: capturedPhotos,
              selectedPhotos: selectedPhotos,
              scrollController: scrollController,
              latestCapturedPath: latestCapturedPath,
              removingPhotoPath: removingPhotoPath,
              colorScheme: colorScheme,
              orientationTurns: orientationTurns,
              onToggleSelection: onTogglePhotoSelection,
              onRemovePhoto: onRemoveCapturedPhoto,
            ),
            AppSpacing.vGap200,
          ],

          // ── Baris Tombol Aksi Shutter & Switch Kamera Simetris ────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space200,
            ),
            child: Row(
              children: [
                // Sayap Kiri: Spacer penyeimbang simetri shutter
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                    ),
                  ),
                ),

                // Slot Tengah: Tombol Shutter Besar M3 Expressive
                _CameraShutterButton(
                  canCapture: canCapture,
                  isCapturing: isCapturing,
                  colorScheme: colorScheme,
                  onTap: onTakePicture,
                  isScreenFlashActive: isScreenFlashActive,
                ),

                // Sayap Kanan: Tombol Switch Kamera Depan/Belakang
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: hasMultipleCameras
                        ? AppIconButton(
                            key: const ValueKey<String>('camera_switch_button'),
                            size: AppIconButtonSize.md,
                            semanticLabel: isCurrentCameraFront
                                ? 'Beralih ke kamera belakang'
                                : 'Beralih ke kamera depan',
                            onPressed: onSwitchCamera,
                            haptic: M3EHapticFeedback.light,
                            decoration: _buildCameraOverlayButtonDecoration(
                              colorScheme: colorScheme,
                              isScreenFlashActive: isScreenFlashActive,
                            ),
                            icon: AnimatedRotation(
                              turns: orientationTurns + switchCameraTurns,
                              duration: isReducedMotion
                                  ? Duration.zero
                                  : AppMultiShotCameraScreen.rotationDuration,
                              curve: AppMultiShotCameraScreen.rotationCurve,
                              child: AppSvgIcon(
                                KawaloVectors.refreshCcwDot,
                                color: switchIconColor,
                              ),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey<String>('camera_switch_placeholder'),
                            width: 56,
                            height: 56,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper pemetaan kesalahan terstandarisasi untuk antarmuka modul kamera.
///
/// Mengonversi berbagai bentuk galat platform, [CameraException], maupun
/// kegagalan runtime menjadi model tampilan [AppActionableErrorData] yang
/// ramah pengguna, dilengkapi tips pemecahan masalah serta tombol aksi nyata.
class CameraActionableError {
  const CameraActionableError._();

  /// Memformat rincian teknis diagnostik galat menggunakan
  /// [DiagnosticErrorFormatter] berstandar proyek.
  ///
  /// Menerapkan pola GoF Strategy dengan sanitasi token pada lingkungan
  /// produksi jika [isProduction] bernilai `true`. Parameter [domainPrefix]
  /// menentukan awalan kode diagnostik (default: `'CAM'`), dan [errorFormatter]
  /// menyediakan strategi pemformatan kustom jika diberikan.
  static String formatTechnicalDetails(
    Object error, {
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
    String? domainPrefix = 'CAM',
  }) {
    return DiagnosticErrorFormatter.formatError(
      error,
      domainPrefix: domainPrefix,
      isProduction: isProduction,
      formatter: errorFormatter,
    );
  }

  /// Membangun model galat penolakan izin kamera dengan panduan ke menu
  /// pengaturan.
  static AppActionableErrorData _buildPermissionDenied({
    required VoidCallback onExit,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.cameraOff01Filled,
      title: 'Izin kamera dinonaktifkan',
      message: 'Izin kamera diperlukan untuk mengambil foto.',
      troubleshootingTips: const [
        'Ketuk Buka pengaturan di bawah.',
        'Pilih menu Izin aplikasi.',
        'Aktifkan izin Kamera.',
        'Kembali ke aplikasi untuk melanjutkan.',
      ],
      primaryActionLabel: 'Buka pengaturan',
      onPrimaryAction: () {
        if (openAppSettingsFn != null) {
          unawaited(openAppSettingsFn());
        } else {
          unawaited(launcherService.openAppSettings());
        }
      },
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Memetakan [CameraException] atau galat platform ke dalam
  /// [AppActionableErrorData].
  ///
  /// Mengidentifikasi galat penolakan izin kamera, sensor yang sedang dikunci
  /// oleh aplikasi lain (*CameraInUse*), atau kendala inisialisasi tak terduga.
  /// Callback [onRetry] dieksekusi saat tombol coba lagi ditekan, dan [onExit]
  /// dipanggil ketika pengguna memilih kembali/menutup layar.
  /// Parameter [openAppSettingsFn] dan [launcherService] digunakan untuk
  /// mengarahkan pengguna ke pengaturan perizinan sistem operasi.
  static AppActionableErrorData fromCameraException(
    CameraException e, {
    required VoidCallback onRetry,
    required VoidCallback onExit,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    final code = e.code;
    final desc = e.description?.toLowerCase() ?? '';
    final codeLower = code.toLowerCase();
    final isPermissionDenied = code == 'CameraAccessDenied' ||
        code == 'CameraAccessDeniedWithoutPrompt' ||
        code == 'cameraPermission' ||
        code == 'permissionDenied' ||
        codeLower.contains('permission') ||
        codeLower.contains('denied') ||
        desc.contains('permission') ||
        desc.contains('denied');

    if (isPermissionDenied) {
      return _buildPermissionDenied(
        onExit: onExit,
        openAppSettingsFn: openAppSettingsFn,
        launcherService: launcherService,
      );
    }

    final isCameraInUse = code == 'CameraInUse' ||
        code == 'cameraInUse' ||
        code == 'cameraExclusiveAccessFailed';

    if (isCameraInUse) {
      return AppActionableErrorData(
        icon: KawaloVectors.alert02Filled,
        title: 'Kamera sedang digunakan',
        message: 'Sensor kamera sedang diakses atau dikunci oleh '
            'aplikasi lain di perangkat Anda.',
        troubleshootingTips: const [
          'Tutup panggilan video atau aplikasi kamera lain yang sedang aktif.',
          'Pastikan tidak ada perekaman latar belakang yang aktif.',
          'Ketuk Coba lagi untuk menghubungkan ulang kamera.',
        ],
        primaryActionLabel: 'Coba lagi',
        onPrimaryAction: onRetry,
        secondaryActionLabel: 'Kembali',
        onSecondaryAction: onExit,
        themeMode: AppActionableErrorThemeMode.dark,
      );
    }

    // Kesalahan Tak Terduga (Unexpected)
    return AppActionableErrorData(
      icon: KawaloVectors.alertDiamondFilled,
      title: 'Kendala inisialisasi kamera',
      message: 'Modul kamera mengalami kendala saat dihubungkan ke sistem.',
      technicalDetails: formatTechnicalDetails(
        e,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      ),
      isUnexpected: true,
      troubleshootingTips: const [
        'Ketuk Coba lagi untuk memuat ulang kamera.',
        'Tutup aplikasi dari daftar aplikasi terkini, lalu buka kembali.',
      ],
      primaryActionLabel: 'Coba lagi',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Memetakan kesalahan inisialisasi kamera umum ke dalam
  /// [AppActionableErrorData].
  ///
  /// Jika [error] merupakan instans [CameraException], penanganan didelegasikan
  /// ke [fromCameraException]. Jika berupa galat platform lain yang mengandung
  /// indikasi penolakan izin, antarmuka akan menampilkan panduan membuka
  /// pengaturan OS. Kesalahan lainnya akan dipetakan sebagai galat tak
  /// terduga via [unexpected].
  static AppActionableErrorData fromInitializationError(
    Object error, {
    required VoidCallback onRetry,
    required VoidCallback onExit,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    if (error is CameraException) {
      return fromCameraException(
        error,
        onRetry: onRetry,
        onExit: onExit,
        openAppSettingsFn: openAppSettingsFn,
        launcherService: launcherService,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      );
    }

    final errorStr = error.toString().toLowerCase();
    final isPermissionDenied = errorStr.contains('permission') ||
        errorStr.contains('denied') ||
        errorStr.contains('cameraaccessdenied');

    if (isPermissionDenied) {
      return _buildPermissionDenied(
        onExit: onExit,
        openAppSettingsFn: openAppSettingsFn,
        launcherService: launcherService,
      );
    }

    return unexpected(
      error,
      onRetry: onRetry,
      onExit: onExit,
      errorFormatter: errorFormatter,
      isProduction: isProduction,
    );
  }

  /// Membuat [AppActionableErrorData] ketika perangkat tidak memiliki sensor
  /// kamera aktif.
  ///
  /// Menampilkan pesan informatif bahwa sensor kamera fisik tidak terdeteksi
  /// beserta langkah-langkah diagnostik perangkat keras.
  static AppActionableErrorData noCamerasAvailable({
    required VoidCallback onRetry,
    required VoidCallback onExit,
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.cameraOff01,
      title: 'Kamera tidak terdeteksi',
      message: 'Sistem tidak menemukan modul kamera aktif pada perangkat ini.',
      troubleshootingTips: const [
        'Pastikan perangkat memiliki modul kamera fisik yang berfungsi.',
        'Periksa apakah kebijakan keamanan membatasi akses kamera.',
        'Ketuk Coba lagi setelah memastikan kamera tersedia.',
      ],
      primaryActionLabel: 'Coba lagi',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Membuat [AppActionableErrorData] untuk kesalahan teknis generic yang
  /// tak terduga.
  ///
  /// Menyertakan rincian teknis yang telah diformat menggunakan
  /// [formatTechnicalDetails] serta panduan pemecahan masalah dasar.
  static AppActionableErrorData unexpected(
    Object error, {
    required VoidCallback onRetry,
    required VoidCallback onExit,
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.alertSquareFilled,
      title: 'Terjadi kesalahan teknis',
      message: 'Sistem mendeteksi kendala tak terduga pada antarmuka kamera.',
      technicalDetails: formatTechnicalDetails(
        error,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      ),
      isUnexpected: true,
      troubleshootingTips: const [
        'Ketuk Coba lagi untuk memuat ulang kamera.',
        'Tutup aplikasi dari daftar aplikasi terkini, lalu buka kembali.',
        'Mulai ulang perangkat jika kendala masih berlanjut.',
      ],
      primaryActionLabel: 'Coba lagi',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Membuat [AppActionableErrorData] untuk kegagalan pemrosesan atau
  /// penyimpanan berkas foto.
  ///
  /// Digunakan ketika penangkapan gambar, pemotongan rasio, atau penyimpanan
  /// lokal mengalami kendala (misalnya memori internal penuh). Callback
  /// [onDismiss] dipanggil saat pengguna menutup lembar galat (*error bottom
  /// sheet*).
  static AppActionableErrorData captureFailure(
    Object error, {
    VoidCallback? onDismiss,
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.alertCircleFilled,
      title: 'Gagal menyimpan foto',
      message: 'Terjadi kendala saat memproses atau menyimpan berkas foto. '
          'Foto sebelumnya tetap aman.',
      technicalDetails: formatTechnicalDetails(
        error,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      ),
      isUnexpected: true,
      troubleshootingTips: const [
        'Pastikan ruang penyimpanan perangkat masih mencukupi.',
        'Coba ambil foto kembali.',
      ],
      primaryActionLabel: 'Mengerti',
      onPrimaryAction: onDismiss,
    );
  }
}

/// Atom efek visual kilatan tirai rana kamera Material 3 Expressive.
class _CameraShutterFlash extends StatelessWidget {
  const _CameraShutterFlash({
    required this.animation,
    required this.colorScheme,
    super.key,
  });

  final Animation<double> animation;
  final M3EColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = animation.value;
          if (progress <= 0 || progress >= 1.0) {
            return const SizedBox.shrink();
          }

          // Tirai menutup dalam 30% awal durasi, lalu memudar kembali ke 0.0
          final double opacity;
          if (progress < 0.30) {
            opacity = (progress / 0.30) * 0.90;
          } else {
            opacity = (1.0 - ((progress - 0.30) / 0.70)) * 0.90;
          }

          return Container(
            color: colorScheme.scrim.withValues(
              alpha: opacity.clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

/// Atom overlay bingkai cahaya translusen kamera depan (Illuminated Frame).
class _IlluminatedFrameOverlay extends StatelessWidget {
  const _IlluminatedFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Jendela tengah 72% dari dimensi kontainer
        final cutoutWidth = size.width * 0.72;
        final cutoutHeight = size.height * 0.72;
        final cutoutLeft = (size.width - cutoutWidth) / 2;
        final cutoutTop = (size.height - cutoutHeight) / 2;

        final cutoutRect = Rect.fromLTWH(
          cutoutLeft,
          cutoutTop,
          cutoutWidth,
          cutoutHeight,
        );

        return CustomPaint(
          size: size,
          painter: _IlluminatedFramePainter(
            cutoutRect: cutoutRect,
            borderRadius: AppRadius.borderExtraLarge,
            frameColor: Colors.white.withValues(alpha: 0.70),
            borderColor: Colors.white,
            borderWidth: 2,
          ),
        );
      },
    );
  }
}

class _IlluminatedFramePainter extends CustomPainter {
  const _IlluminatedFramePainter({
    required this.cutoutRect,
    required this.borderRadius,
    required this.frameColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final Rect cutoutRect;
  final BorderRadius borderRadius;
  final Color frameColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = Path()..addRect(Offset.zero & size);
    final cutoutRRect = borderRadius.toRRect(cutoutRect);
    final cutoutPath = Path()..addRRect(cutoutRRect);

    // 1. Bingkai cahaya translusen luar (Difference path)
    final framePath =
        Path.combine(PathOperation.difference, fullPath, cutoutPath);
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(framePath, framePaint);

    // 2. Garis tepi penegas jendela tengah
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(cutoutRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _IlluminatedFramePainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
