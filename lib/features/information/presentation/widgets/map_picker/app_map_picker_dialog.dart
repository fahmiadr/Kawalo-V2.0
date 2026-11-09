/// @docImport 'package:geolocator/geolocator.dart';
/// @docImport 'package:kawalo_mobile/core/widgets/app_dialog.dart';
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_center_pin_marker.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_bottom_overlay.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_canvas.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_overlay_state.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_result.dart';
import 'package:latlong2/latlong.dart' hide Path;
export 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_result.dart';

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
  late final ValueNotifier<MapPickerOverlayState> _overlayStateNotifier;
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

    final shouldGeocodeInitial =
        _hasInitialCoordinates &&
        (widget.initialAddress == null ||
            widget.initialAddress!.trim().isEmpty);

    _overlayStateNotifier = ValueNotifier<MapPickerOverlayState>(
      MapPickerOverlayState(
        hasConfirmedFix: _hasInitialCoordinates,
        resolvedAddress: _hasInitialCoordinates && !shouldGeocodeInitial
            ? widget.initialAddress
            : null,
        isResolvingAddress: shouldGeocodeInitial,
      ),
    );

    // Layer 2: Lifecycle-Driven Auto-Recovery (Self-Healing)
    _lifecycleListener = AppLifecycleListener(onResume: _handleAppResume);

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
      final fetchLastKnown =
          widget.lastKnownLocationProvider ??
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
    _overlayStateNotifier.value = state.copyWith(isLocatingUser: true);

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
          InteractiveMapCanvas(
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
                _mapController.move(center, state.hasConfirmedFix ? 18 : 17);
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
          MapCenterPinMarker(isMovingListenable: _isMovingNotifier),

          // ── Kontrol Melayang Bawah & Kartu Konfirmasi (Targeted Rebuild) ──
          ValueListenableBuilder<MapPickerOverlayState>(
            valueListenable: _overlayStateNotifier,
            builder: (context, overlayState, _) {
              return MapPickerBottomOverlay(
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
        LocationActionableError.showTimeoutSnackbar(context, onRetry: onRetry);
      case LocationStatus.success:
        break;
    }
  }
}
