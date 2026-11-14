import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// Group logo, or a shield on a soft brand square when there is none.
class GroupLogo extends StatelessWidget {
  const GroupLogo({required this.logoUrl, super.key});

  final String? logoUrl;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final fallback = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: tones.ptt.soft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(Icons.shield_outlined, size: 20, color: tones.ptt.color),
    );
    final url = logoUrl;
    if (url == null ||
        !(url.startsWith('http://') || url.startsWith('https://'))) {
      return ExcludeSemantics(child: fallback);
    }
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          url,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : fallback,
        ),
      ),
    );
  }
}
