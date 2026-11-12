import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Profile photo of a person, or their initial(s) when there is no usable
/// photo (no URL, not http(s), still loading, or failed to load).
///
/// Use it everywhere a person is shown so photo and fallback look the same.
class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.maxInitials = 1,
    this.circle = false,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// 1 shows the first letter only; 2 shows the first letters of two words.
  final int maxInitials;

  /// Circle instead of the default rounded square.
  final bool circle;

  static String initialsOf(String name, {int max = 1}) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words
        .take(max)
        .map((w) => String.fromCharCode(w.runes.first).toUpperCase())
        .join();
  }

  static bool _isUsable(String? url) {
    final u = url?.trim();
    return u != null && (u.startsWith('http://') || u.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colors = theme.colorScheme;
    final radius = circle
        ? BorderRadius.circular(size / 2)
        : AppRadius.borderMedium;

    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: radius,
      ),
      child: Text(
        initialsOf(name, max: maxInitials),
        style:
            (size >= 56
                    ? theme.typeScale.titleLarge
                    : theme.typography.emphasized.titleMedium)
                .copyWith(color: colors.onSecondaryContainer),
      ),
    );

    return Semantics(
      label: 'Foto profil $name',
      excludeSemantics: true,
      child: _isUsable(imageUrl)
          ? ClipRRect(
              borderRadius: radius,
              child: CachedNetworkImage(
                imageUrl: imageUrl!.trim(),
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, _) => initials,
                errorWidget: (_, _, _) => initials,
              ),
            )
          : initials,
    );
  }
}
