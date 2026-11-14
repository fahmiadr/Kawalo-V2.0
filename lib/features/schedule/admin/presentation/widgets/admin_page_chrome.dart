import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

// ponytail: shared by shift/schedule-admin/forecast only; move to core/widgets
// when another feature needs the same row.

/// Neutral list row of the redesign (`.it`): surface, hairline border,
/// 18 px radius.
class AdminListTile extends StatelessWidget {
  const AdminListTile({
    required this.leading,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final subtitle = this.subtitle;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: tones.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tones.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: tones.ink2, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
