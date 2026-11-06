import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget pembungkus SVG yang mengikuti konvensi tema [IconTheme] Flutter.
///
/// Memungkinkan penggunaan ikon vektor SVG semudah menggunakan [Icon] standar,
/// dengan dukungan pewarnaan otomatis dari [IconTheme] atau warna eksplisit,
/// ukuran, serta label aksesibilitas semantik.
class AppSvgIcon extends StatelessWidget {
  /// Membuat instance [AppSvgIcon] untuk ikon monokrom yang mengikuti tema.
  const AppSvgIcon(
    this.assetPath, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.matchTextDirection = false,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : useIconThemeColor = true;

  /// Membuat instance [AppSvgIcon] untuk aset SVG berwarna (multi-color).
  ///
  /// Tidak menerapkan pewarnaan dari [IconTheme] induk, menjaga warna asli
  /// aset.
  const AppSvgIcon.color(
    this.assetPath, {
    super.key,
    this.size,
    this.semanticLabel,
    this.matchTextDirection = false,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  })  : color = null,
        useIconThemeColor = false;

  /// Path file aset SVG (misalnya diambil dari `KawaloVectors` atau
  /// `KawaloColorVectors`).
  final String assetPath;

  /// Ukuran lebar dan tinggi ikon dalam dp.
  /// Jika `null`, akan mengikuti ukuran dari [IconTheme] induk (default: 24.0).
  final double? size;

  /// Warna tint ikon.
  /// Jika `null` dan [useIconThemeColor] bernilai `true`, akan mengikuti
  /// warna dari [IconTheme] induk.
  final Color? color;

  /// Apakah ikon harus mewarisi warna dari [IconTheme] induk jika [color]
  /// bernilai `null`.
  final bool useIconThemeColor;

  /// Label semantik untuk pembaca layar (accessibility).
  final String? semanticLabel;

  /// Apakah orientasi ikon dibalik secara otomatis pada mode
  /// Right-to-Left (RTL).
  final bool matchTextDirection;

  /// Cara scaling aset SVG di dalam batas kotaknya.
  final BoxFit fit;

  /// Perataan SVG di dalam kotaknya.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconSize = size ?? iconTheme.size ?? 24.0;
    final iconColor = color ?? (useIconThemeColor ? iconTheme.color : null);

    // Auto-resolve ikon color jika masih berakhiran .svg ke .png
    final resolvedPath = (assetPath.startsWith('assets/icons/color/') &&
            assetPath.toLowerCase().endsWith('.svg'))
        ? assetPath.replaceAll(
            RegExp(r'\.svg$', caseSensitive: false),
            '.png',
          )
        : assetPath;

    final isRaster = resolvedPath.toLowerCase().endsWith('.png') ||
        resolvedPath.toLowerCase().endsWith('.webp');

    if (isRaster) {
      return Image.asset(
        resolvedPath,
        width: iconSize,
        height: iconSize,
        matchTextDirection: matchTextDirection,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        color: iconColor,
        errorBuilder: (_, __, ___) => SizedBox(
          width: iconSize,
          height: iconSize,
        ),
      );
    }

    return SvgPicture.asset(
      resolvedPath,
      width: iconSize,
      height: iconSize,
      matchTextDirection: matchTextDirection,
      fit: fit,
      alignment: alignment,
      semanticsLabel: semanticLabel,
      colorFilter: iconColor != null
          ? ColorFilter.mode(iconColor, BlendMode.srcIn)
          : null,
    );
  }
}
