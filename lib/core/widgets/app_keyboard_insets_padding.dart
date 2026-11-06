import 'package:flutter/material.dart';

/// Widget pembungkus yang mengisolasi pembaruan padding insets keyboard
/// ([MediaQuery.viewInsetsOf]) agar perubahan posisi keyboard (IME)
/// tidak memicu rebuild menyeluruh (*whole-tree rebuild*) pada layar induk.
///
/// Konten [child] dipertahankan sehingga Flutter hanya memperbarui
/// RenderPadding di level rendering tanpa merekonstruksi widget atau elemen
/// di dalamnya selama 50-60 frame animasi keyboard Android berlangsung.
class AppKeyboardInsetsPadding extends StatelessWidget {
  /// Membuat instance [AppKeyboardInsetsPadding].
  const AppKeyboardInsetsPadding({
    required this.child,
    super.key,
    this.hasBottomNavigationBar = false,
    this.isOffline = false,
  });

  /// Widget konten yang akan diangkat di atas keyboard.
  final Widget child;

  /// Menandakan apakah terdapat bilah navigasi bawah (misalnya di dalam
  /// MainNavigationScreen) di bawah konten ini.
  final bool hasBottomNavigationBar;

  /// Status apakah perangkat sedang dalam kondisi offline (menampilkan
  /// offline banner di atas bilah navigasi bawah).
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final double effectiveBottomPadding;

    if (viewInsetsBottom > 0) {
      final viewPaddingBottom =
          MediaQuery.maybeViewPaddingOf(context)?.bottom ?? 0.0;
      final paddingBottom = MediaQuery.maybePaddingOf(context)?.bottom ?? 0.0;
      final double physicalBottom;
      if (viewPaddingBottom > 0) {
        physicalBottom = viewPaddingBottom;
      } else if (paddingBottom > 0) {
        physicalBottom = paddingBottom;
      } else {
        final view = View.maybeOf(context);
        physicalBottom = view != null
            ? MediaQueryData.fromView(view).viewPadding.bottom
            : 0.0;
      }

      final navBarHeight = hasBottomNavigationBar ? 80.0 : 0.0;
      final offlineBannerHeight = isOffline ? 36.0 : 0.0;
      final safeAreaHeight =
          (hasBottomNavigationBar || isOffline) ? physicalBottom : 0.0;
      final bottomBarHeight =
          navBarHeight + offlineBannerHeight + safeAreaHeight;

      final keyboardOverlap = viewInsetsBottom - bottomBarHeight;
      effectiveBottomPadding = keyboardOverlap > 0 ? keyboardOverlap : 0.0;
    } else {
      effectiveBottomPadding = 0.0;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: effectiveBottomPadding),
      child: child,
    );
  }
}
