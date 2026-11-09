import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';

/// Class utilitas terpusat untuk transisi antar screen aplikasi.
/// Memastikan konsistensi animasi, kurva Bezier M3, durasi, dan pola M3.
abstract final class AppPageRoute {
  const AppPageRoute._();

  /// Kurva kustom Bezier M3 standar aplikasi (Emphasized Easing)
  static const Curve defaultCurve = AppMotion.emphasized;

  /// Durasi transisi layar standar aplikasi (500ms - Long 2)
  static const Duration defaultDuration = AppMotion.durationLong2;

  /// Transisi **Fade / Dissolve** (Halus & Mulus)
  /// Cocok untuk perpindahan Splash -> Onboarding -> Auth/Login.
  static PageRouteBuilder<T> fade<T>({
    required WidgetBuilder builder,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppMotion.isReducedMotion(context)) {
          return FadeTransition(opacity: animation, child: child);
        }

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );
        return FadeTransition(opacity: curvedAnimation, child: child);
      },
    );
  }

  /// Pola Transisi **Top Level** (Navigasi Utama: BottomNav, NavRail, Drawer).
  ///
  /// Menggunakan Cross-Fade cepat tanpa animasi sliding lateral.
  static PageRouteBuilder<T> topLevel<T>({
    required WidgetBuilder builder,
    Duration duration = AppDuration.medium2,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppMotion.isReducedMotion(context)) {
          return FadeTransition(opacity: animation, child: child);
        }

        final fadeInAnimation = CurvedAnimation(
          parent: animation,
          curve: AppEasing.emphasizedDecelerate,
        );

        return FadeTransition(opacity: fadeInAnimation, child: child);
      },
    );
  }

  /// Pola Transisi **Forward & Backward** (Hirarki Bertingkat: List -> Detail).
  ///
  /// Android: Shared horizontal slide + cross fade.
  /// iOS: Parallax horizontal slide.
  static PageRouteBuilder<T> forwardBackward<T>({
    required WidgetBuilder builder,
    AxisDirection direction = AxisDirection.right,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppMotion.isReducedMotion(context)) {
          return FadeTransition(opacity: animation, child: child);
        }

        final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        final Offset beginOffset;
        if (isIOS) {
          beginOffset = direction == AxisDirection.right
              ? const Offset(1, 0)
              : const Offset(-1, 0);
        } else {
          beginOffset = direction == AxisDirection.right
              ? const Offset(0.1, 0)
              : const Offset(-0.1, 0);
        }

        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curvedAnimation);

        if (isIOS) {
          return SlideTransition(position: slideAnimation, child: child);
        }

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
      },
    );
  }

  /// Pola Transisi **Lateral** (Konten Sejajar: Tabs, Carousels, Photo Albums).
  ///
  /// Sliding horizontal murni tanpa fade atau paralaks.
  static PageRouteBuilder<T> lateral<T>({
    required WidgetBuilder builder,
    bool forward = true,
    Duration duration = AppDuration.medium3,
    Curve curve = AppEasing.standard,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppMotion.isReducedMotion(context)) {
          return FadeTransition(opacity: animation, child: child);
        }

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        final slideAnimation = Tween<Offset>(
          begin: forward ? const Offset(1, 0) : const Offset(-1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        return SlideTransition(position: slideAnimation, child: child);
      },
    );
  }

  /// Pola Transisi **Container Transform** (Card / List Item / FAB -> Screen Detail).
  ///
  /// Mengaplikasikan transformasi ekspansi elemen hero dari kontainer awal
  /// ke layar tujuan penuh dengan skala & kurva Emphasized.
  static PageRouteBuilder<T> containerTransform<T>({
    required WidgetBuilder builder,
    Duration duration = defaultDuration,
    Curve curve = AppEasing.emphasized,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppMotion.isReducedMotion(context)) {
          return FadeTransition(opacity: animation, child: child);
        }

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        final scaleAnimation = Tween<double>(
          begin: 0.92,
          end: 1,
        ).animate(curvedAnimation);

        final fadeAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(curvedAnimation);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  /// Pola Transisi **Enter & Exit** (Dialog, Modal Bottom Sheet, Overlay).
  ///
  /// Menampilkan atau menyembunyikan komponen temporer terhadap konteks utama.
  static PageRouteBuilder<T> enterExit<T>({
    required WidgetBuilder builder,
    AxisDirection slideDirection = AxisDirection.up,
    Duration duration = AppDuration.medium4,
    Curve curve = AppEasing.emphasizedDecelerate,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: AppDuration.short4,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppMotion.isReducedMotion(context)) {
          return FadeTransition(opacity: animation, child: child);
        }

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: AppEasing.emphasizedAccelerate,
        );

        final Offset beginOffset;
        switch (slideDirection) {
          case AxisDirection.up:
            beginOffset = const Offset(0, 0.15);
          case AxisDirection.down:
            beginOffset = const Offset(0, -0.15);
          case AxisDirection.left:
            beginOffset = const Offset(-0.15, 0);
          case AxisDirection.right:
            beginOffset = const Offset(0.15, 0);
        }

        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
      },
    );
  }

  /// Transisi **Slide + Fade** (Bergaya M3 / Smooth Navigation).
  static PageRouteBuilder<T> slideFade<T>({
    required WidgetBuilder builder,
    AxisDirection direction = AxisDirection.right,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    RouteSettings? settings,
  }) {
    return forwardBackward<T>(
      builder: builder,
      direction: direction,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }
}
