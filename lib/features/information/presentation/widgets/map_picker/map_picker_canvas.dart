import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:latlong2/latlong.dart' hide Path;

// ============================================================================
// ORGANISM: Interactive Map Canvas
// ============================================================================

/// Kanvas peta OpenStreetMap interaktif yang menangani rendering tile
/// dan penangkapan gestur interaksi pengguna.
class InteractiveMapCanvas extends StatelessWidget {
  const InteractiveMapCanvas({
    required this.mapController,
    required this.centerNotifier,
    required this.onMapReady,
    required this.onPositionChanged,
    this.onMapEvent,
    super.key,
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
