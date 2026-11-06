import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EHapticFeedback,
        M3EInteractionState,
        M3EMotion,
        M3ESpring,
        M3ETappable;

/// Alias untuk [M3EInteractionState] agar seragam dengan konvensi proyek.
typedef AppInteractionState = M3EInteractionState;

/// Alias untuk [M3EHapticFeedback] agar seragam dengan konvensi proyek.
typedef AppHapticFeedback = M3EHapticFeedback;

/// Komponen interaktif fondasi Material 3 Expressive untuk membungkus
/// elemen UI.
///
/// Menyediakan animasi penekanan fisik mikro berbasis spring physics,
/// pelacakan status interaksi (hover, focus, pressed), haptic feedback,
/// dan dukungan aksesibilitas secara terpadu.
///
/// Gunakan konstruktor standar [AppTappable] dengan parameter `child` untuk
/// permukaan statis, atau gunakan [AppTappable.builder] saat membutuhkan
/// akses ke [AppInteractionState] untuk mengubah dekorasi secara dinamis.
class AppTappable extends StatelessWidget {
  /// Membuat [AppTappable] dengan widget [child] langsung.
  const AppTappable({
    required Widget child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.semanticLabel,
    this.semanticButton = true,
    this.excludeSemantics = false,
    this.pressedScale = 0.96,
    this.spring = M3EMotion.expressiveSpatialPress,
    this.onStateChanged,
    this.materialInk = false,
    this.haptic = M3EHapticFeedback.light,
  })  : _child = child,
        _builder = null;

  /// Membuat [AppTappable] dengan [builder] yang peka terhadap interaksi
  /// status.
  const AppTappable.builder({
    required Widget Function(BuildContext context, AppInteractionState state)
        builder,
    super.key,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.semanticLabel,
    this.semanticButton = true,
    this.excludeSemantics = false,
    this.pressedScale = 0.96,
    this.spring = M3EMotion.expressiveSpatialPress,
    this.onStateChanged,
    this.materialInk = false,
    this.haptic = M3EHapticFeedback.light,
  })  : _builder = builder,
        _child = null;

  final Widget? _child;
  final Widget Function(BuildContext context, AppInteractionState state)?
      _builder;

  /// Callback ketika permukaan ditekan.
  final VoidCallback? onTap;

  /// Callback ketika permukaan ditekan lama.
  final VoidCallback? onLongPress;

  /// Menentukan apakah permukaan menerima interaksi.
  final bool enabled;

  /// Focus node kustom jika disediakan.
  final FocusNode? focusNode;

  /// Menentukan apakah permukaan langsung meminta fokus saat ditampilkan.
  final bool autofocus;

  /// Kursor mouse saat kursor berada di atas komponen.
  final MouseCursor? mouseCursor;

  /// Label aksesibilitas untuk screen reader.
  final String? semanticLabel;

  /// Menentukan apakah semantik memperlakukan komponen sebagai tombol.
  final bool semanticButton;

  /// Menentukan apakah semantik child diabaikan.
  final bool excludeSemantics;

  /// Skala animasi penekanan saat ditekan.
  final double pressedScale;

  /// Konfigurasi spring fisik untuk animasi penekanan.
  final M3ESpring spring;

  /// Callback yang dipanggil saat status interaksi berubah.
  final ValueChanged<AppInteractionState>? onStateChanged;

  /// Menentukan apakah menggunakan Material ink overlay.
  final bool materialInk;

  /// Tingkat intensitas haptic feedback saat ditekan.
  final M3EHapticFeedback haptic;

  @override
  Widget build(BuildContext context) {
    return M3ETappable(
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      mouseCursor: mouseCursor,
      semanticLabel: semanticLabel,
      semanticButton: semanticButton,
      excludeSemantics: excludeSemantics,
      pressedScale: pressedScale,
      spring: spring,
      onStateChanged: onStateChanged,
      materialInk: materialInk,
      haptic: haptic,
      builder: (context, state) {
        if (_builder != null) {
          return _builder!(context, state);
        }
        return _child!;
      },
    );
  }
}
