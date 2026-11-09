import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_overlay_state.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Mengelola reverse geocoding (debounce, pembatalan, request id) dan
/// pencarian GPS untuk dialog pemilih peta.
///
/// Efek samping yang terikat widget (kamera peta, bottom sheet galat) tetap
/// di UI dan dipicu lewat callback.
class MapPickerCubit extends Cubit<MapPickerOverlayState> {
  MapPickerCubit(
    this._geocodeService,
    this._locationService, {
    required MapPickerOverlayState initialState,
    Future<LocationResult> Function()? locationProvider,
    Future<Position?> Function()? lastKnownLocationProvider,
    VoidCallback? onGeocodeStart,
  }) : _locationProvider = locationProvider,
       _lastKnownLocationProvider = lastKnownLocationProvider,
       _onGeocodeStart = onGeocodeStart,
       super(initialState);

  static const _geocodeDebounce = Duration(milliseconds: 650);

  final ReverseGeocodeService _geocodeService;
  final LocationService _locationService;
  final Future<LocationResult> Function()? _locationProvider;
  final Future<Position?> Function()? _lastKnownLocationProvider;
  final VoidCallback? _onGeocodeStart;

  int _geocodeRequestId = 0;
  int _gpsGeneration = 0;
  Timer? _debounceTimer;
  AppCancellationToken? _geocodeCancelToken;

  void scheduleGeocode(LatLng target, {bool immediate = false}) {
    _debounceTimer?.cancel();
    _geocodeCancelToken?.cancel();
    _geocodeCancelToken = null;
    if (immediate) {
      _startGeocode(target);
      return;
    }

    _debounceTimer = Timer(_geocodeDebounce, () {
      _startGeocode(target);
    });
  }

  void retryGeocode(LatLng center) {
    if (state.isResolvingAddress || state.isLocatingUser) return;
    scheduleGeocode(center, immediate: true);
  }

  /// Records a user pan/zoom gesture and schedules a debounced geocode.
  void handleUserGesture(LatLng center) {
    final current = state;
    if (!current.hasUserInteracted || current.hasGeocodeError) {
      emit(current.copyWith(hasUserInteracted: true, hasGeocodeError: false));
    }
    scheduleGeocode(center);
  }

  /// Returns the last known position when it is still usable as a camera
  /// hint, or `null` when a fix/interaction has superseded it or lookup fails.
  Future<Position?> fetchViewportHint() async {
    try {
      final fetchLastKnown =
          _lastKnownLocationProvider ?? _locationService.getLastKnownPosition;
      final lastKnown = await fetchLastKnown();
      if (isClosed ||
          state.hasConfirmedFix ||
          state.hasUserInteracted ||
          lastKnown == null) {
        return null;
      }
      return lastKnown;
    } on Object catch (_) {
      return null;
    }
  }

  /// Acquires the device position.
  ///
  /// [onFixFound] runs as soon as a successful fix arrives, even when an
  /// auto-recovery result is then discarded because the user already moved the
  /// map. [onLocated] receives the center to apply; [onFailure] the error.
  Future<void> goToCurrentLocation({
    required VoidCallback onFixFound,
    required void Function(LatLng center) onLocated,
    required void Function(LocationResult result) onFailure,
    bool isAutoRecovery = false,
  }) async {
    if (state.isLocatingUser) return;

    final generation = ++_gpsGeneration;
    emit(state.copyWith(isLocatingUser: true));

    try {
      final fetchPosition =
          _locationProvider ?? _locationService.getCurrentPosition;
      final result = await fetchPosition();
      if (isClosed || generation != _gpsGeneration) return;

      if (result.isSuccess && result.coordinates != null) {
        onFixFound();

        // Protect a manually chosen point when the user panned the map while
        // auto-recovery was still resolving in the background.
        if (isAutoRecovery && state.hasUserInteracted) return;

        final (lat, lng) = result.coordinates!;
        final newCenter = LatLng(lat, lng);
        onLocated(newCenter);
        emit(state.copyWith(hasConfirmedFix: true, hasGeocodeError: false));
        scheduleGeocode(newCenter, immediate: true);
      } else {
        onFailure(result);
      }
    } on Object catch (_) {
      if (isClosed || generation != _gpsGeneration) return;
      onFailure(
        const LocationResult.error(
          'Gagal mendeteksi lokasi GPS perangkat Anda.',
        ),
      );
    } finally {
      if (!isClosed && generation == _gpsGeneration) {
        emit(state.copyWith(isLocatingUser: false));
      }
    }
  }

  void _startGeocode(LatLng target) {
    if (isClosed) return;
    _onGeocodeStart?.call();
    emit(state.copyWith(isResolvingAddress: true, hasGeocodeError: false));
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
      if (isClosed || currentRequestId != _geocodeRequestId) return;

      if (result.isCancelled) return;

      final (resolvedAddress, hasError) = switch (result.address?.trim()) {
        final text? when text.isNotEmpty => (text, false),
        _ => (null, true),
      };

      emit(
        state.copyWith(
          resolvedAddress: resolvedAddress,
          isResolvingAddress: false,
          hasGeocodeError: hasError,
        ),
      );
    } on Object catch (_) {
      if (isClosed || currentRequestId != _geocodeRequestId) return;
      emit(
        state.copyWith(
          resolvedAddress: null,
          isResolvingAddress: false,
          hasGeocodeError: true,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _geocodeCancelToken?.cancel();
    return super.close();
  }
}
