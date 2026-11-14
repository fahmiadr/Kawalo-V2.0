import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

enum AppStatusKind { ok, warn, bad, neutral }

/// Small rounded status label (redesign 2026), e.g. "Di lokasi" (ok),
/// "Terlambat 14 mnt" (warn), "Ditolak" (bad), "Rancangan" (neutral).
class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    required this.label,
    super.key,
    this.kind = AppStatusKind.neutral,
    this.icon,
  });

  final String label;
  final AppStatusKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final (bg, fg) = switch (kind) {
      AppStatusKind.ok => (tones.okSoft, tones.ok),
      AppStatusKind.warn => (tones.warnSoft, tones.warn),
      AppStatusKind.bad => (tones.sos.soft, tones.sos.color),
      AppStatusKind.neutral => (tones.surface2, tones.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
