import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// Layout of a round-button task card: [header], an optional [top] line
/// (banner, progress), then [children] centred in the remaining height. On a
/// short screen the centred part scales down instead of overflowing.
class HomeCardBody extends StatelessWidget {
  const HomeCardBody({
    required this.header,
    required this.children,
    super.key,
    this.top,
  });

  final Widget header;
  final Widget? top;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (top != null) ...[const SizedBox(height: 12), top!],
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        children[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grey caption under a card's round button.
class HomeCardCaption extends StatelessWidget {
  const HomeCardCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: KawaloTones.of(context).ink2, fontSize: 14),
  );
}
