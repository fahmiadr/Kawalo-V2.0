import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/static_map/app_static_map_address.dart';
import 'package:kawalo_mobile/core/widgets/static_map/app_static_map_pulse_aura_marker.dart';
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
                              child: AppStaticMapPulseAuraMarker(
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
          AppStaticMapAddress(
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
