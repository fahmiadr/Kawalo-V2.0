import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// Action dock under a redesigned screen (`.ft` in `rd.css`): the 64 px
/// primary button first, then secondary ones, on the page background. Safe
/// area aware, so it works as `Scaffold.bottomNavigationBar`.
class AppTaskFooter extends StatelessWidget {
  const AppTaskFooter({required this.children, super.key, this.asRow = false});

  final List<Widget> children;

  /// Equal buttons side by side (Tolak | Setujui).
  final bool asRow;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KawaloTones.of(context).background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: asRow
              ? Row(
                  children: [
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: child),
                    ],
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0) const SizedBox(height: 8),
                      child,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
