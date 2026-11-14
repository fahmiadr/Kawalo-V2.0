import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

enum AppInlineBannerKind { warn, error, info }

/// Inline notice of the redesign (`.bn` in `rd.css`): offline, upload failure,
/// reconnecting, resolved. Warning tint by default.
class AppInlineBanner extends StatelessWidget {
  const AppInlineBanner({
    required this.message,
    super.key,
    this.kind = AppInlineBannerKind.warn,
    this.icon,
    this.leading,
  });

  final String message;
  final AppInlineBannerKind kind;
  final IconData? icon;

  /// Replaces [icon], e.g. a small spinner.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final (bg, fg) = switch (kind) {
      AppInlineBannerKind.warn => (tones.warnSoft, tones.warn),
      AppInlineBannerKind.error => (tones.sos.soft, tones.sos.color),
      AppInlineBannerKind.info => (tones.surface2, tones.ink2),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            leading ??
                Icon(
                  icon ??
                      switch (kind) {
                        AppInlineBannerKind.warn => Icons.wifi_off_rounded,
                        AppInlineBannerKind.error =>
                          Icons.error_outline_rounded,
                        AppInlineBannerKind.info => Icons.info_outline_rounded,
                      },
                  size: 18,
                  color: fg,
                ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
