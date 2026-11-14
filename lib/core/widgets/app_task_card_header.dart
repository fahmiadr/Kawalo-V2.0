import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// Header of a task card (redesign 2026): [icon] on a soft [tone] square,
/// [title] with an optional [tag] ("Segera hadir", "Rancangan") and one
/// [subtitle] line. With [onSubtitleTap] the subtitle becomes a 44 px tap
/// target (e.g. "6 rekan online ›" opens the member list).
class AppTaskCardHeader extends StatelessWidget {
  const AppTaskCardHeader({
    required this.icon,
    required this.title,
    required this.tone,
    super.key,
    this.subtitle,
    this.tag,
    this.onSubtitleTap,
  });

  final IconData icon;
  final String title;
  final KawaloTone tone;
  final String? subtitle;
  final String? tag;
  final VoidCallback? onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final subtitle = this.subtitle;

    Widget? sub;
    if (subtitle != null) {
      sub = Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: tones.ink2, fontSize: 14),
      );
      if (onSubtitleTap != null) {
        sub = Semantics(
          button: true,
          child: InkWell(
            onTap: onSubtitleTap,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Align(alignment: Alignment.centerLeft, child: sub),
            ),
          ),
        );
      }
    }

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: tone.soft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 24, color: tone.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  text: title,
                  children: [
                    if (tag != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _Tag(tag!, tones),
                        ),
                      ),
                  ],
                ),
                maxLines: 2,
                style: TextStyle(
                  color: tones.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              ?sub,
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.tones);

  final String label;
  final KawaloTones tones;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: tones.surface2,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: tones.ink2,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.66,
      ),
    ),
  );
}
