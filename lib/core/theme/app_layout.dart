import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';

/// Enum representing Material Design 3 Window Size Classes.
///
/// Ref: https://m3.material.io/foundations/layout/breakpoints/overview
enum AppWindowSizeClass {
  /// Compact window: < 600dp (phones in portrait, folded foldables).
  compact,

  /// Medium window: 600dp – 839dp (tablets in portrait, unfolded foldables).
  medium,

  /// Expanded window: 840dp – 1199dp (landscape tablets/foldables, desktop).
  expanded;

  /// Returns the corresponding [AppWindowSizeClass] for a given [width] in dp.
  ///
  /// For viewports >= 1200dp, caps/falls back to [expanded].
  static AppWindowSizeClass fromWidth(double width) {
    if (width < AppLayout.compactBreakpoint) {
      return AppWindowSizeClass.compact;
    } else if (width < AppLayout.mediumBreakpoint) {
      return AppWindowSizeClass.medium;
    }
    return AppWindowSizeClass.expanded;
  }
}

/// Global responsive layout constants and utilities following Material 3
/// Window Size Classes.
///
/// Provides consistent maximum content widths, pane dimensions, and
/// responsive margins across all screens in the application adhering to
/// standard breakpoints (0dp – 1199dp).
///
/// Reference: https://m3.material.io/foundations/layout/applying-layout
abstract class AppLayout {
  // -----------------------------------------------------------------------
  // M3 Window Size Class Breakpoints (dp)
  // -----------------------------------------------------------------------

  /// Upper bound threshold for Compact window class (< 600dp).
  static const double compactBreakpoint = 600;

  /// Upper bound threshold for Medium window class (600dp – 839dp).
  static const double mediumBreakpoint = 840;

  /// Upper bound threshold for Expanded window class (840dp – 1199dp).
  static const double expandedBreakpoint = 1200;

  // -----------------------------------------------------------------------
  // Content & Pane Constraints (dp)
  // -----------------------------------------------------------------------

  /// Maximum container width cap for viewports ≥ 1200dp (centered
  /// horizontally).
  static const double maxContainerWidth = 1199;

  /// Maximum width for single-column form/card content (login, settings, etc.).
  ///
  /// M3 recommends ≤ 600dp to maintain comfortable reading width and
  /// touch-target density on larger screens (tablets, foldables).
  static const double contentMaxWidth = 600;

  /// Standard fixed width for primary/secondary pane in Fixed-and-Flexible
  /// 2-pane Expanded layout.
  static const double fixedPaneWidth = 360;

  /// Inter-pane spacer width for 2-pane layouts in Medium and Expanded.
  static const double paneSpacer = AppSpacing.space300; // 24dp

  // -----------------------------------------------------------------------
  // Responsive Margins (dp)
  // -----------------------------------------------------------------------

  /// Compact outer horizontal margin (16dp).
  static const double marginCompact = AppSpacing.space200; // 16dp

  /// Medium & Expanded outer horizontal margin (24dp).
  static const double marginMediumExpanded = AppSpacing.space300; // 24dp

  /// Returns the M3-recommended horizontal margin for the given
  /// [screenWidth].
  ///
  /// | Window Class | Width Range | Margin |
  /// |--------------|-------------|--------|
  /// | Compact      | < 600dp     | 16dp   |
  /// | Medium       | 600–839dp   | 24dp   |
  /// | Expanded     | ≥ 840dp     | 24dp   |
  static double horizontalMargin(double screenWidth) {
    if (screenWidth < compactBreakpoint) return marginCompact;
    return marginMediumExpanded;
  }

  // -----------------------------------------------------------------------
  // Scroll Clearance & Floating Elements Insets (dp)
  // -----------------------------------------------------------------------

  /// Jarak tepi standar bawah untuk layar tanpa elemen melayang (16dp).
  static const double standardBottomPadding = AppSpacing.space200;

  /// Scroll clearance vertikal untuk layar yang memiliki Extended FAB (120dp).
  ///
  /// Memastikan kartu terbawah dapat digulir bebas di atas FAB
  /// (Tinggi FAB 56dp + margin 16dp + ruang nafas baca 48dp).
  static const double fabScrollClearance = 120;

  /// Nilai dasar scroll clearance untuk floating toolbar (96dp).
  ///
  /// Toolbar 64dp + margin melayang 16dp + gap nafas kartu 16dp = 96dp.
  static const double toolbarScrollClearanceBase = 96;

  /// Menghitung scroll clearance adaptif untuk layar dengan floating toolbar,
  /// memperhitungkan safe area bawah perangkat.
  static double toolbarScrollClearance(BuildContext context) {
    return toolbarScrollClearanceBase + MediaQuery.paddingOf(context).bottom;
  }

  // -----------------------------------------------------------------------
  // Device Orientation System (4 Sides)
  // -----------------------------------------------------------------------

  /// Supported device orientations across all 4 directions adhering to
  /// Material 3 adaptive responsive layout standards.
  static const List<DeviceOrientation> supportedOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  /// Sets the preferred device orientations for the Flutter engine.
  static Future<void> applyPreferredOrientations() async {
    await SystemChrome.setPreferredOrientations(supportedOrientations);
  }

  /// True if current screen is in landscape orientation.
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// True if current screen is in portrait orientation.
  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  // -----------------------------------------------------------------------
  // Window Class Helper Utilities
  // -----------------------------------------------------------------------

  /// Resolves the current [AppWindowSizeClass] for [screenWidth].
  static AppWindowSizeClass getWindowSizeClass(double screenWidth) {
    return AppWindowSizeClass.fromWidth(screenWidth);
  }

  /// True if the layout is in Compact size class (< 600dp).
  static bool isCompact(double screenWidth) => screenWidth < compactBreakpoint;

  /// True if the layout is in Medium size class (600dp – 839dp).
  static bool isMedium(double screenWidth) =>
      screenWidth >= compactBreakpoint && screenWidth < mediumBreakpoint;

  /// True if the layout is in Expanded size class (≥ 840dp).
  static bool isExpanded(double screenWidth) => screenWidth >= mediumBreakpoint;
}
