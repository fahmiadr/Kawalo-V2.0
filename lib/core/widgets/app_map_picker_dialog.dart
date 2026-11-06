/// @docImport 'package:geolocator/geolocator.dart';
/// @docImport 'package:kawalo_mobile/core/widgets/app_dialog.dart';
library;

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';
import 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Hasil pemilihan koordinat pada [AppMapPickerDialog].
///
/// Objek pembawa data (*value object*) yang bersifat *immutable* dan
/// mengimplementasikan [Equatable] untuk memfasilitasi perbandingan nilai
/// kesetaraan struktural koordinat dan alamat.
///
/// Dihasilkan oleh [AppMapPickerDialog.show] saat pengguna mengonfirmasi
/// pemilihan titik lokasi.
@immutable
class AppMapPickerResult extends Equatable {
  /// Membuat instans [AppMapPickerResult].
  const AppMapPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  /// Garis lintang (Latitude) koordinat yang dipilih.
  final double latitude;

  /// Garis bujur (Longitude) koordinat yang dipilih.
  final double longitude;

  /// Alamat jalan representatif hasil proses *reverse geocoding*.
  ///
  /// Bernilai `null` jika reverse geocoding belum selesai, tidak berhasil
  /// menemukan alamat, atau layanan reverse geocoding tidak disediakan.
  final String? address;

  @override
  List<Object?> get props => [latitude, longitude, address];
}

/// Dialog layar penuh pemilih titik lokasi interaktif berbasis OpenStreetMap.
///
/// Memungkinkan pengguna menavigasi kanvas peta melalui gestur geser dan cubit
/// (*pan and zoom*), meletakkan penanda titik tengah secara visual, mendeteksi
/// posisi GPS pengguna secara otomatis maupun eksplisit, serta mengonfirmasi
/// koordinat yang dipilih.
///
/// Menerapkan arsitektur *Zero Root setState* berbasis [ValueNotifier] untuk
/// menjamin kanvas peta dan penanda tengah terisolasi dari proses render ulang
/// (*targeted rebuilds*) selama proses pencarian alamat berlangsung.
///
/// Mendukung mekanisme pemulihan otomatis (*Self-Healing State Reconciliation*)
/// dua lapis:
/// 1. Lapisan navigasi saat kembali dari modal lembar bawah actionable error.
/// 2. Lapisan siklus hidup aplikasi ([AppLifecycleListener.onResume]) saat
///    pengguna kembali ke aplikasi setelah mengaktifkan GPS di pengaturan OS.
///
/// Contoh menampilkan dialog pemilih lokasi:
/// ```dart
/// final result = await AppMapPickerDialog.show(
///   context,
///   initialLatitude: -6.2088,
///   initialLongitude: 106.8456,
///   reverseGeocodeService: ReverseGeocodeService.instance,
/// );
/// if (result != null) {
///   debugPrint('Koordinat: ${result.latitude}, ${result.longitude}');
///   debugPrint('Alamat: ${result.address}');
/// }
/// ```
class AppMapPickerDialog extends StatefulWidget {
  /// Membuat instans [AppMapPickerDialog].
  const AppMapPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.reverseGeocodeService,
    this.locationService = const DefaultLocationService(),
    this.locationProvider,
    this.lastKnownLocationProvider,
    this.launcherService = const DefaultAppLauncherService(),
    this.openAppSettingsFn,
    this.openLocationSettingsFn,
    this.autoTriggerGps = true,
  });

  /// Garis lintang awal untuk posisi tengah kamera peta.
  ///
  /// Jika tidak ditentukan (`null`), posisi awal akan menggunakan titik
  /// default atau posisi cache terakhir perangkat.
  final double? initialLatitude;

  /// Garis bujur awal untuk posisi tengah kamera peta.
  ///
  /// Jika tidak ditentukan (`null`), posisi awal akan menggunakan titik
  /// default atau posisi cache terakhir perangkat.
  final double? initialLongitude;

  /// Alamat awal representatif sebelum proses reverse geocoding baru berjalan.
  final String? initialAddress;

  /// Layanan resolusi alamat (*reverse geocoding*) opsional.
  final ReverseGeocodeService? reverseGeocodeService;

  /// Layanan inspeksi lokasi dan penentuan izin GPS terpadu (Pure DI).
  final LocationService locationService;

  /// Delegasi kustom perolehan [LocationResult] untuk injeksi dependensi dan
  /// pengujian unit/widget.
  final Future<LocationResult> Function()? locationProvider;

  /// Delegasi kustom perolehan posisi cache terakhir ([Position]) untuk kamera
  /// *viewport hint* sebelum sinyal GPS akurat diperoleh.
  final Future<Position?> Function()? lastKnownLocationProvider;

  /// Layanan peluncur intent eksternal untuk membuka pengaturan sistem
  /// operasi (Pure DI).
  final AppLauncherService launcherService;

  /// Delegasi fungsi pembuka pengaturan perizinan aplikasi di sistem operasi.
  final Future<bool> Function()? openAppSettingsFn;

  /// Delegasi fungsi pembuka pengaturan layanan lokasi di sistem operasi.
  final Future<bool> Function()? openLocationSettingsFn;

  /// Apakah pencarian lokasi GPS otomatis dipicu satu kali saat dialog
  /// dibuka tanpa koordinat awal (default: `true`).
  final bool autoTriggerGps;

  /// Menampilkan [AppMapPickerDialog] melalui dialog layar penuh
  /// terstandarisasi [AppDialog.showFullScreen].
  ///
  /// Mengembalikan [AppMapPickerResult] yang berisi koordinat dan alamat
  /// yang dipilih pengguna, atau `null` jika dialog dibatalkan.
  static Future<AppMapPickerResult?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialAddress,
    ReverseGeocodeService? reverseGeocodeService,
    LocationService locationService = const DefaultLocationService(),
    Future<LocationResult> Function()? locationProvider,
    Future<Position?> Function()? lastKnownLocationProvider,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    Future<bool> Function()? openAppSettingsFn,
    Future<bool> Function()? openLocationSettingsFn,
    bool autoTriggerGps = true,
  }) {
    return AppDialog.showFullScreen<AppMapPickerResult>(
      context,
      title: 'Pilih di peta',
      body: AppMapPickerDialog(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialAddress: initialAddress,
        reverseGeocodeService: reverseGeocodeService,
        locationService: locationService,
        locationProvider: locationProvider,
        lastKnownLocationProvider: lastKnownLocationProvider,
        launcherService: launcherService,
        openAppSettingsFn: openAppSettingsFn,
        openLocationSettingsFn: openLocationSettingsFn,
        autoTriggerGps: autoTriggerGps,
      ),
    );
  }

  @override
  State<AppMapPickerDialog> createState() => _AppMapPickerDialogState();
}

class _AppMapPickerDialogState extends State<AppMapPickerDialog> {
  static const LatLng _defaultCoordinate = LatLng(-6.2088, 106.8456);

  late final MapController _mapController;
  late final ReverseGeocodeService _geocodeService;
  late final ValueNotifier<LatLng> _centerNotifier;
  late final ValueNotifier<_MapPickerOverlayState> _overlayStateNotifier;
  late final ValueNotifier<bool> _isMovingNotifier;
  late final AppLifecycleListener _lifecycleListener;

  int _geocodeRequestId = 0;
  int _gpsGeneration = 0;
  bool _isMapReady = false;
  bool _isErrorSheetVisible = false;
  Timer? _debounceTimer;
  AppCancellationToken? _geocodeCancelToken;

  bool get _hasInitialCoordinates =>
      widget.initialLatitude != null && widget.initialLongitude != null;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _geocodeService =
        widget.reverseGeocodeService ?? ReverseGeocodeService.instance;

    final initialCenter = _hasInitialCoordinates
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _defaultCoordinate;

    _centerNotifier = ValueNotifier<LatLng>(initialCenter);
    _isMovingNotifier = ValueNotifier<bool>(false);

    final shouldGeocodeInitial = _hasInitialCoordinates &&
        (widget.initialAddress == null ||
            widget.initialAddress!.trim().isEmpty);

    _overlayStateNotifier = ValueNotifier<_MapPickerOverlayState>(
      _MapPickerOverlayState(
        hasConfirmedFix: _hasInitialCoordinates,
        resolvedAddress: _hasInitialCoordinates && !shouldGeocodeInitial
            ? widget.initialAddress
            : null,
        isResolvingAddress: shouldGeocodeInitial,
      ),
    );

    // Layer 2: Lifecycle-Driven Auto-Recovery (Self-Healing)
    _lifecycleListener = AppLifecycleListener(
      onResume: _handleAppResume,
    );

    if (_hasInitialCoordinates) {
      if (shouldGeocodeInitial) {
        _scheduleGeocode(initialCenter, immediate: true);
      }
    } else {
      _applyLastKnownViewportHint();
      if (widget.autoTriggerGps) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_handleGoToCurrentLocation());
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _debounceTimer?.cancel();
    _geocodeCancelToken?.cancel();
    _isMovingNotifier.dispose();
    _overlayStateNotifier.dispose();
    _centerNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Self-Healing State Reconciliation saat aplikasi kembali aktif
  /// (misalnya pengguna mengaktifkan GPS di OS Settings atau panel
  /// Quick Settings dan kembali ke app).
  void _handleAppResume() {
    if (!mounted) return;
    final state = _overlayStateNotifier.value;

    // Self-Healing Auto-Recovery reaktif HANYA dipicu jika error bottom sheet
    // sedang aktif tampil di layar (_isErrorSheetVisible) saat aplikasi
    // melanjutkan fokus (resumed).
    // Jika pengguna telah menutup lembar galat secara manual ("Pilih manual"
    // atau swipe down), _isErrorSheetVisible bernilai false, sehingga
    // auto-recovery TIDAK AKAN berjalan dan tidak memunculkan kembali error.
    final shouldRecover = _isErrorSheetVisible && !state.isLocatingUser;

    if (shouldRecover) {
      unawaited(_handleGoToCurrentLocation(isAutoRecovery: true));
    }
  }

  void _scheduleGeocode(LatLng target, {bool immediate = false}) {
    _debounceTimer?.cancel();
    _geocodeCancelToken?.cancel();
    _geocodeCancelToken = null;
    if (immediate) {
      _startGeocode(target);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 650), () {
      _startGeocode(target);
    });
  }

  void _startGeocode(LatLng target) {
    if (!mounted) return;
    _isMovingNotifier.value = false;
    _overlayStateNotifier.value = _overlayStateNotifier.value.copyWith(
      isResolvingAddress: true,
      hasGeocodeError: false,
    );
    unawaited(_executeGeocode(target));
  }

  Future<void> _executeGeocode(LatLng target) async {
    _geocodeCancelToken?.cancel();
    final cancelToken = DioCancellationToken();
    _geocodeCancelToken = cancelToken;
    final currentRequestId = ++_geocodeRequestId;
    try {
      final result = await _geocodeService.reverseGeocode(
        latitude: target.latitude,
        longitude: target.longitude,
        cancelToken: cancelToken,
      );
      if (!mounted || currentRequestId != _geocodeRequestId) return;

      if (result.isCancelled) return;

      final (resolvedAddress, hasError) = switch (result.address?.trim()) {
        final text? when text.isNotEmpty => (text, false),
        _ => (null, true),
      };

      _overlayStateNotifier.value = _overlayStateNotifier.value.copyWith(
        resolvedAddress: resolvedAddress,
        isResolvingAddress: false,
        hasGeocodeError: hasError,
      );
    } on Object catch (_) {
      if (!mounted || currentRequestId != _geocodeRequestId) return;
      _overlayStateNotifier.value = _overlayStateNotifier.value.copyWith(
        resolvedAddress: null,
        isResolvingAddress: false,
        hasGeocodeError: true,
      );
    }
  }

  void _handleRetryGeocode() {
    final state = _overlayStateNotifier.value;
    if (state.isResolvingAddress || state.isLocatingUser) return;
    _scheduleGeocode(_centerNotifier.value, immediate: true);
  }

  Future<void> _applyLastKnownViewportHint() async {
    try {
      final fetchLastKnown = widget.lastKnownLocationProvider ??
          widget.locationService.getLastKnownPosition;
      final lastKnown = await fetchLastKnown();
      final state = _overlayStateNotifier.value;
      if (!mounted ||
          state.hasConfirmedFix ||
          state.hasUserInteracted ||
          lastKnown == null) {
        return;
      }

      final hintCenter = LatLng(lastKnown.latitude, lastKnown.longitude);
      _centerNotifier.value = hintCenter;
      if (_isMapReady) {
        _mapController.move(hintCenter, 17);
      }
    } on Object catch (_) {
      // Abaikan kegagalan cache, kamera tetap pada posisi awal default.
    }
  }

  Future<void> _handleGoToCurrentLocation({bool isAutoRecovery = false}) async {
    final state = _overlayStateNotifier.value;
    if (state.isLocatingUser) return;

    final generation = ++_gpsGeneration;
    _overlayStateNotifier.value = state.copyWith(
      isLocatingUser: true,
    );

    try {
      final fetchPosition =
          widget.locationProvider ?? widget.locationService.getCurrentPosition;
      final result = await fetchPosition();
      if (!mounted || generation != _gpsGeneration) return;

      if (result.isSuccess && result.coordinates != null) {
        _dismissErrorSheetIfVisible();

        // Lindungi koordinat pilihan manual jika pengguna sempat menggeser
        // peta saat auto-recovery sedang memproses asinkron di background.
        if (isAutoRecovery && _overlayStateNotifier.value.hasUserInteracted) {
          return;
        }

        final (lat, lng) = result.coordinates!;
        final newCenter = LatLng(lat, lng);
        if (_isMapReady) {
          _mapController.move(newCenter, 18);
        }
        _centerNotifier.value = newCenter;
        _overlayStateNotifier.value = _overlayStateNotifier.value.copyWith(
          hasConfirmedFix: true,
          hasGeocodeError: false,
        );
        _scheduleGeocode(newCenter, immediate: true);
      } else {
        if (!mounted || generation != _gpsGeneration) return;
        if (!_isErrorSheetVisible) {
          _presentLocationFeedback(result);
        }
      }
    } on Object catch (_) {
      if (!mounted || generation != _gpsGeneration) return;
      if (!_isErrorSheetVisible) {
        _presentLocationFeedback(
          const LocationResult.error(
            'Gagal mendeteksi lokasi GPS perangkat Anda.',
          ),
        );
      }
    } finally {
      if (mounted && generation == _gpsGeneration) {
        _overlayStateNotifier.value = _overlayStateNotifier.value.copyWith(
          isLocatingUser: false,
        );
      }
    }
  }

  void _dismissErrorSheetIfVisible() {
    if (!_isErrorSheetVisible) return;
    _isErrorSheetVisible = false;
    final dialogRoute = ModalRoute.of(context);
    if (dialogRoute != null && !dialogRoute.isCurrent) {
      Navigator.of(context).maybePop();
    }
  }

  void _presentLocationFeedback(LocationResult result) {
    if (result.status == LocationStatus.timeout) {
      unawaited(
        _LocationFeedbackPresenter.present(
          context: context,
          result: result,
          onRetry: () => unawaited(_handleGoToCurrentLocation()),
          launcherService: widget.launcherService,
        ),
      );
      return;
    }

    if (_isErrorSheetVisible) return;
    _isErrorSheetVisible = true;
    unawaited(
      _LocationFeedbackPresenter.present(
        context: context,
        result: result,
        onRetry: () => unawaited(_handleGoToCurrentLocation()),
        onDismiss: () {
          _isErrorSheetVisible = false;
        },
        launcherService: widget.launcherService,
        openAppSettingsFn: widget.openAppSettingsFn,
        openLocationSettingsFn: widget.openLocationSettingsFn,
      ).whenComplete(() {
        _isErrorSheetVisible = false;
      }),
    );
  }

  void _handleConfirm() {
    final currentCenter = _centerNotifier.value;
    Navigator.of(context).pop(
      AppMapPickerResult(
        latitude: currentCenter.latitude,
        longitude: currentCenter.longitude,
        address: _overlayStateNotifier.value.resolvedAddress,
      ),
    );
  }

  void _handleMapEvent(MapEvent event) {
    if (event is MapEventMoveStart ||
        event is MapEventFlingAnimationStart ||
        event is MapEventDoubleTapZoomStart ||
        event is MapEventScrollWheelZoom) {
      _isMovingNotifier.value = true;
    } else if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd) {
      _isMovingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Kanvas Peta Interaktif (Organism - Targeted Rebuild Immune) ──
          _InteractiveMapCanvas(
            mapController: _mapController,
            centerNotifier: _centerNotifier,
            onMapEvent: _handleMapEvent,
            onMapReady: () {
              _isMapReady = true;
              final center = _centerNotifier.value;
              final state = _overlayStateNotifier.value;
              if (!_hasInitialCoordinates &&
                  !state.hasUserInteracted &&
                  center != _defaultCoordinate) {
                _mapController.move(
                  center,
                  state.hasConfirmedFix ? 18 : 17,
                );
              }
            },
            onPositionChanged: (camera, hasGesture) {
              _centerNotifier.value = camera.center;
              if (hasGesture) {
                if (!_isMovingNotifier.value) {
                  _isMovingNotifier.value = true;
                }
                final current = _overlayStateNotifier.value;
                if (!current.hasUserInteracted || current.hasGeocodeError) {
                  _overlayStateNotifier.value = current.copyWith(
                    hasUserInteracted: true,
                    hasGeocodeError: false,
                  );
                }
                _scheduleGeocode(camera.center);
              }
            },
          ),

          // ── Penanda Titik Tengah Presisi (Molecule) ──────────────
          _MapCenterPinMarker(
            isMovingListenable: _isMovingNotifier,
          ),

          // ── Kontrol Melayang Bawah & Kartu Konfirmasi (Targeted Rebuild) ──
          ValueListenableBuilder<_MapPickerOverlayState>(
            valueListenable: _overlayStateNotifier,
            builder: (context, overlayState, _) {
              return _MapPickerBottomOverlay(
                state: overlayState,
                centerListenable: _centerNotifier,
                onGoToCurrentLocation: _handleGoToCurrentLocation,
                onConfirm: _handleConfirm,
                onRetryGeocode: _handleRetryGeocode,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STRATEGY (GoF): Location Feedback Presenter
// ============================================================================

/// Strategi terpadu untuk menyajikan umpan balik galat lokasi.
abstract final class _LocationFeedbackPresenter {
  const _LocationFeedbackPresenter._();

  static Future<void> present({
    required BuildContext context,
    required LocationResult result,
    required VoidCallback onRetry,
    required AppLauncherService launcherService,
    VoidCallback? onDismiss,
    VoidCallback? onOpenSettings,
    Future<bool> Function()? openAppSettingsFn,
    Future<bool> Function()? openLocationSettingsFn,
  }) async {
    switch (result.status) {
      case LocationStatus.serviceDisabled:
      case LocationStatus.permissionDenied:
      case LocationStatus.permissionDeniedForever:
      case LocationStatus.preciseLocationRequired:
      case LocationStatus.mockLocationDetected:
      case LocationStatus.unknownError:
        await LocationActionableError.showBottomSheet<void>(
          context,
          result: result,
          onDismiss: () {
            Navigator.of(context).maybePop();
            onDismiss?.call();
          },
          onRetry: onRetry,
          onOpenSettings: onOpenSettings,
          openAppSettingsFn: openAppSettingsFn,
          openLocationSettingsFn: openLocationSettingsFn,
          launcherService: launcherService,
        );
      case LocationStatus.timeout:
        LocationActionableError.showTimeoutSnackbar(
          context,
          onRetry: onRetry,
        );
      case LocationStatus.success:
        break;
    }
  }
}

// ============================================================================
// VALUE OBJECT / STATE (GoF): Uni-Directional Flow Overlay State
// ============================================================================

const _sentinel = Object();

/// State antarmuka untuk [_MapPickerBottomOverlay] yang sepenuhnya
/// merefleksikan alur data satu arah (Uni-Directional Data Flow / UDF).
@immutable
class _MapPickerOverlayState extends Equatable {
  const _MapPickerOverlayState({
    this.isLocatingUser = false,
    this.isResolvingAddress = false,
    this.hasGeocodeError = false,
    this.hasConfirmedFix = false,
    this.hasUserInteracted = false,
    this.resolvedAddress,
  });

  /// Status pencarian posisi GPS pengguna.
  final bool isLocatingUser;

  /// Status proses reverse geocoding alamat jalan.
  final bool isResolvingAddress;

  /// Apakah resolusi alamat jalan mengalami kegagalan.
  final bool hasGeocodeError;

  /// Apakah titik lokasi telah memiliki fix koordinat GPS terkonfirmasi.
  final bool hasConfirmedFix;

  /// Apakah pengguna telah melakukan interaksi geser/zoom secara manual.
  final bool hasUserInteracted;

  /// Alamat jalan yang berhasil diperoleh dari reverse geocoding.
  final String? resolvedAddress;

  /// Apakah tombol konfirmasi titik dapat diaktifkan.
  bool get canConfirm =>
      !isLocatingUser && (hasConfirmedFix || hasUserInteracted);

  /// Apakah baris petunjuk manual harus ditampilkan di atas tombol.
  bool get showGuidingHelper =>
      !hasConfirmedFix && !hasUserInteracted && !isLocatingUser;

  /// Menghasilkan state baru dengan mutasi data spesifik (GoF State Pattern).
  _MapPickerOverlayState copyWith({
    bool? isLocatingUser,
    bool? isResolvingAddress,
    bool? hasGeocodeError,
    bool? hasConfirmedFix,
    bool? hasUserInteracted,
    Object? resolvedAddress = _sentinel,
  }) {
    return _MapPickerOverlayState(
      isLocatingUser: isLocatingUser ?? this.isLocatingUser,
      isResolvingAddress: isResolvingAddress ?? this.isResolvingAddress,
      hasGeocodeError: hasGeocodeError ?? this.hasGeocodeError,
      hasConfirmedFix: hasConfirmedFix ?? this.hasConfirmedFix,
      hasUserInteracted: hasUserInteracted ?? this.hasUserInteracted,
      resolvedAddress: identical(resolvedAddress, _sentinel)
          ? this.resolvedAddress
          : resolvedAddress as String?,
    );
  }

  @override
  List<Object?> get props => [
        isLocatingUser,
        isResolvingAddress,
        hasGeocodeError,
        hasConfirmedFix,
        hasUserInteracted,
        resolvedAddress,
      ];
}

// ============================================================================
// ORGANISM: Interactive Map Canvas
// ============================================================================

/// Kanvas peta OpenStreetMap interaktif yang menangani rendering tile
/// dan penangkapan gestur interaksi pengguna.
class _InteractiveMapCanvas extends StatelessWidget {
  const _InteractiveMapCanvas({
    required this.mapController,
    required this.centerNotifier,
    required this.onMapReady,
    required this.onPositionChanged,
    this.onMapEvent,
  });

  final MapController mapController;
  final ValueListenable<LatLng> centerNotifier;
  final VoidCallback onMapReady;
  final PositionCallback onPositionChanged;
  final MapEventCallback? onMapEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: centerNotifier.value,
        initialZoom: 17,
        onMapReady: onMapReady,
        onPositionChanged: onPositionChanged,
        onMapEvent: onMapEvent,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kawalo.app',
          tileBuilder: isDark ? darkModeTileBuilder : null,
        ),
      ],
    );
  }
}

// ============================================================================
// MOLECULE: Center Precision Pin Marker (M3 Expressive Custom Shape & Lift)
// ============================================================================

/// Painter kustom untuk bayangan elips dinamis di lantai di bawah target dot.
class _GroundShadowPainter extends CustomPainter {
  const _GroundShadowPainter({
    required this.shadowColor,
    required this.liftProgress,
  });

  final Color shadowColor;
  final double liftProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Saat terangkat (liftProgress -> 1.0), bayangan memudar dan melembut.
    final radiusX = 6.0 - (1.5 * liftProgress);
    final radiusY = 2.5 - (0.5 * liftProgress);
    final opacity = (0.28 - (0.16 * liftProgress)).clamp(0.05, 0.35);

    final paint = Paint()
      ..color = shadowColor.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        2.0 + (2.0 * liftProgress),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GroundShadowPainter oldDelegate) {
    return oldDelegate.shadowColor != shadowColor ||
        oldDelegate.liftProgress != liftProgress;
  }
}

/// Painter kustom untuk siluet pin lokasi Material 3 Expressive.
///
/// Menggambar pin geometris dengan kepala lingkaran di bagian atas, kurva
/// kubik presisi menyambung ke ujung runcingan di bawah, border kontras
/// permukaan, lingkaran dalam (inner core), dan bayangan elevasi dinamis.
class _MapPinPainter extends CustomPainter {
  const _MapPinPainter({
    required this.pinColor,
    required this.strokeColor,
    required this.shadowColor,
    this.elevation = 3,
  });

  final Color pinColor;
  final Color strokeColor;
  final Color shadowColor;
  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final scaleX = w / 32;
    final scaleY = h / 42;

    canvas
      ..save()
      ..scale(scaleX, scaleY);

    final path = Path()
      // Mulai dari ujung jarum bawah
      ..moveTo(16, 42)
      // Kurva sisi kiri mengalir mulus ke tepi kiri lingkaran kepala
      ..cubicTo(13.5, 34, 0, 26, 0, 16)
      // Busur setengah lingkaran atas beradius 16dp
      ..arcToPoint(
        const Offset(32, 16),
        radius: const Radius.circular(16),
      )
      // Kurva sisi kanan simetris kembali ke ujung jarum
      ..cubicTo(32, 26, 18.5, 34, 16, 42)
      ..close();

    // 1. Gambar bayangan elevasi pin
    if (elevation > 0) {
      canvas.drawShadow(path, shadowColor, elevation, false);
    }

    // 2. Gambar badan pin (fill)
    final fillPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Gambar stroke kontras luar (1.5dp)
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 4. Gambar lingkaran dalam (inner core) di pusat lingkaran atas (16, 16)
    final innerPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas
      ..drawCircle(const Offset(16, 16), 5, innerPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _MapPinPainter oldDelegate) {
    return oldDelegate.pinColor != pinColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}

/// Penanda titik tengah interaktif dengan ground target dot presisi
/// dan custom shape pin Material 3 Expressive yang terangkat saat peta
/// digeser.
class _MapCenterPinMarker extends StatefulWidget {
  const _MapCenterPinMarker({
    required this.isMovingListenable,
  });

  final ValueListenable<bool> isMovingListenable;

  @override
  State<_MapCenterPinMarker> createState() => _MapCenterPinMarkerState();
}

class _MapCenterPinMarkerState extends State<_MapCenterPinMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _liftAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutBack,
    );

    widget.isMovingListenable.addListener(_handleMovingChange);
    if (widget.isMovingListenable.value) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _MapCenterPinMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMovingListenable != widget.isMovingListenable) {
      oldWidget.isMovingListenable.removeListener(_handleMovingChange);
      widget.isMovingListenable.addListener(_handleMovingChange);
    }
  }

  @override
  void dispose() {
    widget.isMovingListenable.removeListener(_handleMovingChange);
    _animController.dispose();
    super.dispose();
  }

  void _handleMovingChange() {
    if (!mounted) return;
    final isReduced = AppMotion.isReducedMotion(context);
    if (widget.isMovingListenable.value) {
      if (isReduced) {
        _animController.value = 1.0;
      } else {
        _animController.forward();
      }
    } else {
      if (isReduced) {
        _animController.value = 0.0;
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return IgnorePointer(
      child: Center(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _liftAnimation,
            builder: (context, _) {
              final progress = _liftAnimation.value;
              // Saat idle: progress = 0.0 -> Y = -21 (ujung jarum di 0, 0)
              // Saat moving: progress = 1.0 -> Y = -29 (terangkat 8dp)
              final translateY = -21 - (8 * progress);
              final scale = 1 + (0.04 * progress);
              final elevation = 3 + (3 * progress);

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. Bayangan elips di lantai
                  CustomPaint(
                    size: const Size(24, 12),
                    painter: _GroundShadowPainter(
                      shadowColor: colorScheme.shadow,
                      liftProgress: progress,
                    ),
                  ),

                  // 2. Ground target dot permanen terkunci di pusat (0, 0)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),

                  // 3. Badan Pin Kustom M3 Expressive terangkat saat bergerak
                  Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: const Size(32, 42),
                        painter: _MapPinPainter(
                          pinColor: colorScheme.primary,
                          strokeColor: colorScheme.surface,
                          shadowColor: colorScheme.shadow,
                          elevation: elevation,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MOLECULE: Coordinates Display (Real-time 60fps ValueListenable)
// ============================================================================

/// Teks penampil koordinat lintang dan bujur yang mendengarkan perubahan
/// posisi kamera secara real-time tanpa memicu rebuild pada kanvas peta.
class _CoordinatesDisplay extends StatelessWidget {
  const _CoordinatesDisplay({
    required this.centerListenable,
  });

  final ValueListenable<LatLng> centerListenable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final style = AppTheme.emphasizedTypeScaleOf(context).labelMedium.copyWith(
          color: colorScheme.onSurface,
        );

    return ValueListenableBuilder<LatLng>(
      valueListenable: centerListenable,
      builder: (context, center, _) {
        return Text(
          'Koordinat: '
          '${center.latitude.toStringAsFixed(6)}, '
          '${center.longitude.toStringAsFixed(6)}',
          style: style,
        );
      },
    );
  }
}

// ============================================================================
// MOLECULE: Address Error & Retry Action
// ============================================================================

/// Baris aksi error dan tombol coba lagi ketika resolusi alamat gagal,
/// mematuhi standar Material 3 Expressive dan WCAG AA touch target 48x48dp.
class _AddressErrorRetry extends StatelessWidget {
  const _AddressErrorRetry({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasizedTypeScale = AppTheme.emphasizedTypeScaleOf(context);
    final linkColor = colorScheme.primary;

    return Text.rich(
      TextSpan(
        style: typeScale.bodySmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        text: 'Detail alamat jalan tidak tersedia',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: AppTooltip(
              message: 'Coba lagi memuat alamat lokasi',
              child: AppTappable.builder(
                semanticLabel: 'Coba lagi memuat alamat lokasi',
                onTap: onRetry,
                builder: (context, state) {
                  final contentColor = state.pressed
                      ? linkColor.withValues(
                          alpha: 1.0 - AppStateLayer.pressedOpacity,
                        )
                      : linkColor;

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderExtraSmall,
                      border:
                          state.focused ? Border.all(color: linkColor) : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 2,
                        top: 1,
                        bottom: 1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSvgIcon(
                            KawaloVectors.reload,
                            size: 11,
                            color: contentColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Coba lagi',
                            style: emphasizedTypeScale.bodySmall.copyWith(
                              color: contentColor,
                              decoration: TextDecoration.underline,
                              decorationColor: contentColor,
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
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ============================================================================
// MOLECULE: Address Shimmer Skeleton
// ============================================================================

/// Skeleton shimmer memuat alamat dengan animasi shimmer berulang
/// yang mematuhi reduced motion dan anti layout-shift.
class _AddressShimmerSkeleton extends StatefulWidget {
  const _AddressShimmerSkeleton();

  @override
  State<_AddressShimmerSkeleton> createState() =>
      _AddressShimmerSkeletonState();
}

class _AddressShimmerSkeletonState extends State<_AddressShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.extraLong4,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startOrStopAnimation();
  }

  void _startOrStopAnimation() {
    final isRunningInTest = WidgetsBinding.instance is! WidgetsFlutterBinding;
    if (isRunningInTest || AppMotion.isReducedMotion(context)) {
      _controller
        ..stop()
        ..value = 0.5;
      return;
    }
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isReduced = AppMotion.isReducedMotion(context);

    final baseColor = colorScheme.surfaceContainerHigh;
    final highlightColor = colorScheme.surfaceContainerHighest;

    return RepaintBoundary(
      child: Semantics(
        label: 'Memuat alamat lokasi',
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final gradient = isReduced
                ? null
                : LinearGradient(
                    begin: Alignment(
                      -2.0 + 4.0 * _controller.value,
                      -0.3,
                    ),
                    end: Alignment(
                      -1.0 + 4.0 * _controller.value,
                      0.3,
                    ),
                    colors: [baseColor, highlightColor, baseColor],
                    stops: const [0.0, 0.5, 1.0],
                  );

            return Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 180,
                    height: 10,
                    decoration: BoxDecoration(
                      color: gradient == null ? baseColor : null,
                      gradient: gradient,
                      borderRadius: AppRadius.borderExtraSmall,
                    ),
                  ),
                  AppSpacing.vGap25,
                  Container(
                    width: 110,
                    height: 10,
                    decoration: BoxDecoration(
                      color: gradient == null ? baseColor : null,
                      gradient: gradient,
                      borderRadius: AppRadius.borderExtraSmall,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// MOLECULE: Address Resolution Section
// ============================================================================

/// Area tampilan alamat 3 baris yang dipreservasi untuk mencegah
/// Cumulative Layout Shift (CLS) saat transisi loading, teks, error, atau
/// petunjuk manual.
class _AddressResolutionSection extends StatelessWidget {
  const _AddressResolutionSection({
    required this.state,
    required this.onRetry,
  });

  final _MapPickerOverlayState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: ExcludeSemantics(
            child: AppSvgIcon.color(
              KawaloColorVectors.location1,
              size: 16,
            ),
          ),
        ),
        AppSpacing.hGap100,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppStateLayer.minTouchTarget,
              ),
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  ExcludeSemantics(
                    child: Opacity(
                      opacity: 0,
                      child: Text(
                        ' \n \n ',
                        style: typeScale.bodySmall,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  if (state.isResolvingAddress)
                    const _AddressShimmerSkeleton()
                  else if (state.resolvedAddress != null &&
                      state.resolvedAddress!.isNotEmpty)
                    Text(
                      state.resolvedAddress!,
                      style: typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (state.hasGeocodeError && !state.isLocatingUser)
                    _AddressErrorRetry(onRetry: onRetry)
                  else if (state.showGuidingHelper)
                    Text(
                      'Geser peta untuk menentukan titik secara manual',
                      style: typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ORGANISM: Map Picker Bottom Overlay
// ============================================================================

/// Organisme kontrol bawah melayang yang menampung FAB GPS, kartu info
/// koordinat, area resolusi alamat, dan tombol konfirmasi titik.
class _MapPickerBottomOverlay extends StatelessWidget {
  const _MapPickerBottomOverlay({
    required this.state,
    required this.centerListenable,
    required this.onGoToCurrentLocation,
    required this.onConfirm,
    required this.onRetryGeocode,
  });

  /// Status data UI yang mengalir satu arah (UDF).
  final _MapPickerOverlayState state;

  /// Posisi koordinat tengah peta real-time.
  final ValueListenable<LatLng> centerListenable;

  /// Pemicu pencarian lokasi saat ini.
  final VoidCallback onGoToCurrentLocation;

  /// Pemicu konfirmasi koordinat terpilih.
  final VoidCallback onConfirm;

  /// Pemicu percobaan ulang resolusi alamat.
  final VoidCallback onRetryGeocode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return Positioned(
      left: AppSpacing.space200,
      right: AppSpacing.space200,
      bottom: AppSpacing.space200,
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppFab(
              onPressed: state.isLocatingUser ? null : onGoToCurrentLocation,
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.primary,
              tooltip: 'Lokasi saat ini',
              icon: state.isLocatingUser
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: AppLoadingIndicator(
                        size: AppLoadingIndicatorSize.small,
                      ),
                    )
                  : const AppSvgIcon(
                      KawaloVectors.gps01,
                      size: 24,
                    ),
            ),
            AppSpacing.vGap150,
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.space200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CoordinatesDisplay(centerListenable: centerListenable),
                  AppSpacing.vGap100,
                  _AddressResolutionSection(
                    state: state,
                    onRetry: onRetryGeocode,
                  ),
                  AppSpacing.vGap200,
                  AppButton(
                    onPressed: state.canConfirm ? onConfirm : null,
                    child: const Text('Pilih titik ini'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
