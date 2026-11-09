import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Gaya tampilan penanda (marker) pada [AppStaticMap].
enum AppStaticMapMarkerStyle {
  /// Pin bulat dengan ikon di tengahnya (default).
  pin,

  /// Indikator titik (dot) minimalis tanpa ikon.
  dot,
}

/// Widget peta statis OpenStreetMap resmi kawalo (`AppStaticMap`).
///
/// Menyediakan visualisasi titik lokasi GPS yang konsisten di seluruh aplikasi:
/// - Peta OSM statis non-geser (`InteractiveFlag.none` & `IgnorePointer`).
/// - Pin lokasi berstandar M3 Expressive dengan bayangan kontras tinggi.
/// - Atribusi legal & resmi OpenStreetMap (`© OpenStreetMap contributors`).
/// - Indikator teks koordinat garis lintang dan bujur.
/// - Reverse geocoding alamat jalan dengan animasi shimmer dan tombol retry.
/// - Tombol aksi untuk membuka titik lokasi ke aplikasi peta eksternal.
/// - Dukungan alamat pra-resolusi untuk meniadakan permintaan HTTP redundan.
/// - Tampilan fallback informatif ketika koordinat GPS tidak valid/tersedia.
/// - Kepatuhan penuh terhadap Unidirectional Data Flow (UDF) & WCAG AA.
class AppStaticMap extends StatelessWidget {
  /// Membuat instance [AppStaticMap].
  const AppStaticMap({
    required this.latitude,
    required this.longitude,
    super.key,
    this.address,
    this.locationSemanticLabel,
    this.mapHeight = 180,
    this.zoom = 18,
    this.showCoordinates = true,
    this.showAddress = true,
    this.showOpenExternalButton = true,
    this.openExternalButtonLabel = 'Buka di Maps',
    this.launcherService = const DefaultAppLauncherService(),
    this.onOpenExternalMap,
    this.openExternalButtonBuilder,
    this.reverseGeocodeService,
    this.onAddressResolved,
    this.noGpsTitle = 'Koordinat tidak tercatat',
    this.noGpsDescription = 'Informasi ini dicatat tanpa rekaman posisi GPS.',
    this.markerStyle = AppStaticMapMarkerStyle.pin,
    this.markerWidget,
    this.markerBuilder,
    this.markerSize,
    this.pinIcon = KawaloVectors.locationUser03,
    this.pinColor,
    this.pinIconColor,
    this.fallbackWidget,
    this.fallbackBuilder,
    this.showAura = true,
    this.auraColor,
  });

  /// Garis lintang GPS (Latitude).
  final double? latitude;

  /// Garis bujur GPS (Longitude).
  final double? longitude;

  /// Alamat fisik opsional yang sudah diketahui sebelumnya.
  ///
  /// Jika diisi, widget langsung menampilkan teks alamat ini tanpa melakukan
  /// reverse geocoding tambahan ke jaringan, mencegah redundansi panggilan API.
  final String? address;

  /// Label aksesibilitas untuk titik pin penanda lokasi.
  final String? locationSemanticLabel;

  /// Tinggi visual kanvas peta OSM (default: 180dp).
  final double mapHeight;

  /// Tingkat zoom awal peta statis (default: 18).
  final double zoom;

  /// Apakah teks baris koordinat `Koordinat: $lat, $lng` ditampilkan.
  final bool showCoordinates;

  /// Apakah alamat fisik hasil reverse geocoding ditampilkan di bawah peta.
  final bool showAddress;

  /// Apakah tombol aksi untuk membuka ke aplikasi peta eksternal ditampilkan.
  final bool showOpenExternalButton;

  /// Label teks tombol aksi buka peta eksternal (default: 'Buka di Maps').
  final String openExternalButtonLabel;

  /// Layanan untuk meluncurkan peta eksternal.
  final AppLauncherService launcherService;

  /// Callback opsional ketika tombol buka peta eksternal ditekan.
  final VoidCallback? onOpenExternalMap;

  /// Builder kustom opsional untuk tombol aksi buka peta eksternal.
  final Widget Function(BuildContext context, double lat, double lng)?
  openExternalButtonBuilder;

  /// Layanan reverse geocoding opsional untuk resolusi alamat fisik.
  final ReverseGeocodeService? reverseGeocodeService;

  /// Callback opsional yang dipanggil saat alamat selesai diresolusi
  /// (atau bernilai null saat gagal), mematuhi prinsip UDF.
  final ValueChanged<String?>? onAddressResolved;

  /// Judul pada kartu fallback saat koordinat GPS tidak tersedia.
  final String noGpsTitle;

  /// Deskripsi pada kartu fallback saat koordinat GPS tidak tersedia.
  final String noGpsDescription;

  /// Gaya tampilan marker (pin atau dot).
  final AppStaticMapMarkerStyle markerStyle;

  /// Widget kustom untuk menggantikan seluruh tampilan marker.
  final Widget? markerWidget;

  /// Builder kustom untuk membuat widget marker berdasarkan koordinat.
  final Widget Function(BuildContext context, double lat, double lng)?
  markerBuilder;

  /// Ukuran visual marker (lebar dan tinggi dalam dp).
  ///
  /// Secara default bernilai 28 untuk [AppStaticMapMarkerStyle.pin] dan
  /// 14 untuk [AppStaticMapMarkerStyle.dot].
  final double? markerSize;

  /// Ikon vektor di dalam pin lokasi (hanya berlaku pada
  /// [AppStaticMapMarkerStyle.pin]).
  final String? pinIcon;

  /// Warna latar pin lokasi (default: `colorScheme.primary`).
  final Color? pinColor;

  /// Warna ikon di dalam pin lokasi (default: `colorScheme.onPrimary`).
  final Color? pinIconColor;

  /// Widget fallback kustom opsional ketika koordinat GPS tidak valid.
  final Widget? fallbackWidget;

  /// Builder fallback kustom opsional ketika koordinat GPS tidak valid.
  final WidgetBuilder? fallbackBuilder;

  /// Apakah penanda lokasi menampilkan animasi aura idle
  /// (*pulsing radar beacon*) untuk membedakannya secara visual dari
  /// elemen raster statis penyedia peta.
  ///
  /// Bernilai `true` secara default.
  final bool showAura;

  /// Warna kustom untuk pancaran animasi aura idle (default: sama dengan
  /// [pinColor] atau `colorScheme.primary`).
  final Color? auraColor;

  /// Flag khusus pengujian untuk mengaktifkan animasi aura berulang
  /// di lingkungan widget test tanpa mengganggu `tester.pumpAndSettle()`.
  @visibleForTesting
  static bool debugEnableAuraAnimationInTests = false;

  static final ReverseGeocodeService _defaultGeocodeService =
      ReverseGeocodeService.instance;

  /// Menandakan apakah koordinat GPS tersedia dan valid untuk dirender.
  bool get hasValidCoordinates {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    return !lat.isNaN && !lng.isNaN && !lat.isInfinite && !lng.isInfinite;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasValidCoordinates) {
      if (fallbackWidget != null) return fallbackWidget!;
      if (fallbackBuilder != null) return fallbackBuilder!(context);
      return _buildNoGpsFallback(context);
    }
    return _buildMapContent(context);
  }

  /// Tampilan fallback ketika koordinat GPS tidak tersedia.
  Widget _buildNoGpsFallback(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: AppSpacing.paddingAll200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppSvgIcon.color(KawaloColorVectors.location3, size: 40),
          AppSpacing.vGapSm,
          Text(
            noGpsTitle,
            style: emphasizedTypeScale.labelMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGap25,
          Text(
            noGpsDescription,
            style: typeScale.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Tampilan utama peta statis dengan pin, koordinat, dan alamat geocoding.
  Widget _buildMapContent(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final isDark = colorScheme.brightness == Brightness.dark;

    final lat = latitude!;
    final lng = longitude!;
    final center = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Kanvas Peta Statis OSM ──────────────────────────────────
        RepaintBoundary(
          child: Container(
            height: mapHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.borderMedium,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Stack(
              children: [
                IgnorePointer(
                  child: FlutterMap(
                    // Key eksplisit memastikan peta langsung merender ulang
                    // saat koordinat / zoom / tema berubah pada rebuild widget.
                    key: ValueKey<String>('osm_${lat}_${lng}_${zoom}_$isDark'),
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: zoom,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kawalo.app',
                        tileBuilder: isDark ? darkModeTileBuilder : null,
                        errorTileCallback: (tile, error, stackTrace) {
                          // Handled gracefully saat jaringan offline
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width:
                                markerSize ??
                                (markerStyle == AppStaticMapMarkerStyle.dot
                                    ? 14.0
                                    : 28.0),
                            height:
                                markerSize ??
                                (markerStyle == AppStaticMapMarkerStyle.dot
                                    ? 14.0
                                    : 28.0),
                            child: Semantics(
                              label:
                                  locationSemanticLabel ??
                                  'Titik lokasi $lat, $lng',
                              child: _AppStaticMapPulseAuraMarker(
                                color:
                                    auraColor ??
                                    pinColor ??
                                    colorScheme.primary,
                                coreSize:
                                    markerSize ??
                                    (markerStyle == AppStaticMapMarkerStyle.dot
                                        ? 14.0
                                        : 28.0),
                                showAura: showAura,
                                child: _buildMarker(context, lat, lng),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol Aksi Buka Peta Eksternal
                if (showOpenExternalButton)
                  Positioned(
                    top: AppSpacing.space100,
                    right: AppSpacing.space100,
                    child: openExternalButtonBuilder != null
                        ? openExternalButtonBuilder!(context, lat, lng)
                        : _buildDefaultOpenExternalButton(context, lat, lng),
                  ),

                // Atribusi OpenStreetMap Resmi & Legal
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: AppRadius.borderExtraSmall,
                    ),
                    child: Text(
                      '© OpenStreetMap contributors',
                      style: typeScale.labelSmall.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Teks Baris Koordinat ────────────────────────────────────
        if (showCoordinates) ...[
          AppSpacing.vGap50,
          Padding(
            padding: AppSpacing.paddingHorizontalXs,
            child: Text(
              'Koordinat: $lat, $lng',
              style: typeScale.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],

        // ── Baris Alamat Hasil Reverse Geocoding ────────────────────
        if (showAddress) ...[
          AppSpacing.vGap50,
          _AppStaticMapAddress(
            latitude: lat,
            longitude: lng,
            address: address,
            service: reverseGeocodeService ?? _defaultGeocodeService,
            onAddressResolved: onAddressResolved,
          ),
        ],
      ],
    );
  }

  /// Tombol bawaan untuk membuka koordinat di aplikasi peta eksternal.
  Widget _buildDefaultOpenExternalButton(
    BuildContext context,
    double lat,
    double lng,
  ) {
    return Semantics(
      label: 'Buka lokasi $lat, $lng di aplikasi peta eksternal',
      button: true,
      child: AppButton(
        style: AppButtonColor.elevated,
        onPressed: () => _handleOpenExternalMap(context, lat, lng),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSvgIcon(KawaloVectors.linkSquare02, size: 14),
            AppSpacing.hGapXs,
            Text(openExternalButtonLabel),
          ],
        ),
      ),
    );
  }

  /// Menangani aksi pembukaan aplikasi peta eksternal dengan fallback graceful.
  Future<void> _handleOpenExternalMap(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    if (onOpenExternalMap != null) {
      onOpenExternalMap!();
      return;
    }

    final success = await launcherService.openMap(
      latitude: lat,
      longitude: lng,
      title: locationSemanticLabel,
    );

    if (!success && context.mounted) {
      AppSnackbar.show(
        context,
        message: 'Tidak dapat membuka aplikasi peta di perangkat ini.',
      );
    }
  }

  /// Membangun marker sesuai konfigurasi (kustom builder, kustom widget,
  /// dot, atau pin).
  Widget _buildMarker(BuildContext context, double lat, double lng) {
    if (markerWidget != null) return markerWidget!;
    if (markerBuilder != null) return markerBuilder!(context, lat, lng);

    switch (markerStyle) {
      case AppStaticMapMarkerStyle.dot:
        return _buildDotMarker(context);
      case AppStaticMapMarkerStyle.pin:
        return _buildMapPin(context);
    }
  }

  /// Indikator titik (dot) bulat minimalis dengan bayangan halus.
  Widget _buildDotMarker(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = pinColor ?? colorScheme.primary;
    final size = markerSize ?? 14.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
    );
  }

  /// Pin lokasi bulat dengan bayangan halus khas M3 Expressive.
  Widget _buildMapPin(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    final effectivePinColor = pinColor ?? colorScheme.primary;
    final effectiveIconColor = pinIconColor ?? colorScheme.onPrimary;
    final size = markerSize ?? 28.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectivePinColor,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: pinIcon != null
          ? Center(
              child: AppSvgIcon(
                pinIcon!,
                size: size * 0.5,
                color: effectiveIconColor,
              ),
            )
          : null,
    );
  }
}

/// Widget pembungkus penanda dengan animasi aura idle (pulsing radar beacon)
/// untuk membedakan penanda kustom aplikasi dari elemen kartografi
/// raster statis OpenStreetMap.
///
/// Mematuhi standar aksesibilitas WCAG AA dan [AppMotion.isReducedMotion].
class _AppStaticMapPulseAuraMarker extends StatefulWidget {
  const _AppStaticMapPulseAuraMarker({
    required this.child,
    required this.color,
    required this.coreSize,
    required this.showAura,
  });

  final Widget child;
  final Color color;
  final double coreSize;
  final bool showAura;

  @override
  State<_AppStaticMapPulseAuraMarker> createState() =>
      _AppStaticMapPulseAuraMarkerState();
}

class _AppStaticMapPulseAuraMarkerState
    extends State<_AppStaticMapPulseAuraMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startOrStopAnimation();
  }

  @override
  void didUpdateWidget(covariant _AppStaticMapPulseAuraMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAura != widget.showAura) {
      _startOrStopAnimation();
    }
  }

  void _startOrStopAnimation() {
    if (!widget.showAura) {
      _controller.stop();
      return;
    }

    if (AppMotion.isReducedMotion(context)) {
      _controller
        ..stop()
        ..value = 0.5;
      return;
    }

    // Di lingkungan widget test (di mana tester.pumpAndSettle() sering
    // dipanggil), animasi berulang tanpa henti dicegah agar tidak memicu
    // timeout, kecuali jika diizinkan secara eksplisit oleh pengujian.
    final isRunningInTest =
        WidgetsBinding.instance is! WidgetsFlutterBinding &&
        !AppStaticMap.debugEnableAuraAnimationInTests;

    if (isRunningInTest) {
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
    if (!widget.showAura) {
      return widget.child;
    }

    final isReduced = AppMotion.isReducedMotion(context);
    final auraColor = widget.color;
    final coreSize = widget.coreSize;
    final maxExpansion = (coreSize * 0.85).clamp(10.0, 20.0);

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isReduced)
            // Mode hemat gerak (Reduced Motion): Halo statis beropasitas lembut
            Positioned(
              left: -maxExpansion * 0.5,
              top: -maxExpansion * 0.5,
              right: -maxExpansion * 0.5,
              bottom: -maxExpansion * 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: auraColor.withValues(alpha: 0.18),
                  border: Border.all(
                    color: auraColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            )
          else
            // Mode normal: Animasi denyut aura idle terus menerus
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                // Gelombang luar yang membesar dan memudar
                final outerProgress = Curves.easeOutCubic.transform(t);
                final outerOffset = maxExpansion * outerProgress;
                final outerOpacity = (1.0 - outerProgress) * 0.45;

                // Gelombang dalam (breathing halo) yang berdenyut lembut
                final innerProgress = t < 0.5 ? t * 2 : (1.0 - t) * 2;
                final innerOffset = maxExpansion * 0.35 * innerProgress;
                final innerOpacity = 0.14 + (0.12 * innerProgress);

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Cincin radar terluar
                    Positioned(
                      left: -outerOffset,
                      top: -outerOffset,
                      right: -outerOffset,
                      bottom: -outerOffset,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: auraColor.withValues(
                            alpha: outerOpacity * 0.4,
                          ),
                          border: Border.all(
                            color: auraColor.withValues(alpha: outerOpacity),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // Halo lembut di dekat inti marker
                    Positioned(
                      left: -innerOffset,
                      top: -innerOffset,
                      right: -innerOffset,
                      bottom: -innerOffset,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: auraColor.withValues(alpha: innerOpacity),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          // Penanda inti (Pin / Dot) tepat di tengah (0, 0)
          widget.child,
        ],
      ),
    );
  }
}

/// Widget penyaji alamat hasil reverse geocoding dengan loading shimmer
/// dan tombol retry.
class _AppStaticMapAddress extends StatefulWidget {
  const _AppStaticMapAddress({
    required this.latitude,
    required this.longitude,
    required this.service,
    this.address,
    this.onAddressResolved,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final ReverseGeocodeService service;
  final ValueChanged<String?>? onAddressResolved;

  @override
  State<_AppStaticMapAddress> createState() => _AppStaticMapAddressState();
}

class _AppStaticMapAddressState extends State<_AppStaticMapAddress>
    with SingleTickerProviderStateMixin {
  String? _address;
  bool _isLoading = false;
  int _requestId = 0;
  AppCancellationToken? _cancelToken;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: AppDuration.extraLong4,
    );

    if (widget.address != null) {
      _address = widget.address;
      _isLoading = false;
    } else {
      _fetchAddress();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _startShimmerAnimation();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AppStaticMapAddress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.address != null) {
      _cancelToken?.cancel();
      if (oldWidget.address != widget.address) {
        setState(() {
          _address = widget.address;
          _isLoading = false;
        });
        _shimmerController.stop();
      }
      return;
    }

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.service != widget.service ||
        oldWidget.address != null) {
      _startShimmerAnimation();
      _fetchAddress();
    }
  }

  void _startShimmerAnimation() {
    if (AppMotion.isReducedMotion(context)) {
      _shimmerController
        ..stop()
        ..value = 0.5;
    } else if (!_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }
  }

  void _retry() {
    if (_isLoading) return;
    _startShimmerAnimation();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    _cancelToken?.cancel();
    final cancelToken = DioCancellationToken();
    _cancelToken = cancelToken;
    final currentRequestId = ++_requestId;

    setState(() {
      _isLoading = true;
    });

    final result = await widget.service.reverseGeocode(
      latitude: widget.latitude,
      longitude: widget.longitude,
      cancelToken: cancelToken,
    );

    if (!mounted || currentRequestId != _requestId) return;
    if (result.isCancelled) return;

    setState(() {
      _address = result.address;
      _isLoading = false;
    });
    _shimmerController.stop();
    widget.onAddressResolved?.call(result.address);
  }

  Widget _buildShimmerSkeleton(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isReduced = AppMotion.isReducedMotion(context);

    final baseColor = colorScheme.surfaceContainerHigh;
    final highlightColor = colorScheme.surfaceContainerHighest;

    return RepaintBoundary(
      child: Semantics(
        label: 'Memuat alamat lokasi',
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final gradient = isReduced
                ? null
                : LinearGradient(
                    begin: Alignment(
                      -2.0 + 4.0 * _shimmerController.value,
                      -0.3,
                    ),
                    end: Alignment(-1.0 + 4.0 * _shimmerController.value, 0.3),
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

  Widget _buildErrorWithRetry(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;
    final linkColor = colorScheme.primary;

    return Text.rich(
      TextSpan(
        style: typeScale.labelSmall.copyWith(
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
                onTap: _retry,
                builder: (context, state) {
                  final contentColor = state.pressed
                      ? linkColor.withValues(alpha: 0.7)
                      : linkColor;

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderExtraSmall,
                      border: state.focused
                          ? Border.all(color: linkColor)
                          : null,
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
                            style: emphasizedTypeScale.labelSmall.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final hasAddress = _address != null && _address!.trim().isNotEmpty;

    return Padding(
      padding: AppSpacing.paddingHorizontalXs,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: AppSvgIcon.color(KawaloColorVectors.location1, size: 16),
            ),
          ),
          AppSpacing.hGapXs,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppStateLayer.minTouchTarget,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _isLoading
                      ? _buildShimmerSkeleton(context)
                      : (hasAddress
                            ? Text(
                                _address!,
                                style: emphasizedTypeScale.labelSmall.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            : _buildErrorWithRetry(context)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
