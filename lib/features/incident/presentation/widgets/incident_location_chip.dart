import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// "-6.20880, 106.84560": five decimals is about one metre.
String formatIncidentCoordinates(double latitude, double longitude) =>
    '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

/// Location chip of the report form (`.chip` in `rd.css`): searching, the GPS
/// point (tap x to drop it) or unavailable (tap to retry). The report can
/// always be sent without a location.
class IncidentLocationChip extends StatelessWidget {
  const IncidentLocationChip({
    required this.latitude,
    required this.longitude,
    required this.isResolving,
    required this.onRetry,
    required this.onClear,
    super.key,
    this.error,
    this.enabled = true,
  });

  final double? latitude;
  final double? longitude;
  final bool isResolving;
  final String? error;
  final bool enabled;
  final VoidCallback onRetry;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final lat = latitude;
    final long = longitude;

    final Widget leading;
    final String label;
    VoidCallback? onTap;
    var showClear = false;
    if (isResolving) {
      leading = SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: tones.ink2),
      );
      label = 'Mencari lokasi…';
    } else if (lat != null && long != null) {
      leading = Icon(Icons.place_outlined, size: 18, color: tones.inc.color);
      label = formatIncidentCoordinates(lat, long);
      showClear = enabled;
    } else {
      leading = Icon(Icons.location_off_outlined, size: 18, color: tones.ink2);
      label = error != null
          ? 'Lokasi tidak tersedia · Coba lagi'
          : 'Tanpa lokasi · Ambil lokasi';
      onTap = enabled ? onRetry : null;
    }

    return Semantics(
      button: onTap != null,
      label: error != null && !isResolving && lat == null
          ? 'Lokasi tidak tersedia. $error Ketuk untuk mencoba lagi.'
          : 'Lokasi: $label',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: tones.line, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: EdgeInsets.only(left: 14, right: showClear ? 4 : 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading,
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.monoFigures.copyWith(
                        color: tones.ink2,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (showClear)
                    IconButton(
                      tooltip: 'Hapus lokasi',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: tones.ink2,
                      ),
                      onPressed: onClear,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
