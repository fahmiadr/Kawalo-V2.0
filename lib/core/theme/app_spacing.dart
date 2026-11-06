import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Spacing Tokens & Utilities
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Spacing & Dimension tokens directly
// from package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EDimensions, M3ESpacing;

/// Standardized Material 3 Expressive Spacing Tokens & Utilities.
///
/// Adheres strictly to the Material 3 Expressive 4dp/8dp baseline grid:
/// https://m3.material.io/styles/spacing/overview
abstract final class AppSpacing {
  const AppSpacing._();

  // -------------------------------------------------------------------------
  // M3 Expressive Semantic Spacing Scale (M3ESpacing)
  // -------------------------------------------------------------------------

  /// 4dp - Extra Small gap (`M3ESpacing.xs`).
  static const double xs = M3EDimensions.spaceXs;

  /// 8dp - Small gap (`M3ESpacing.sm`).
  static const double sm = M3EDimensions.spaceSm;

  /// 12dp - Medium gap (`M3ESpacing.md`).
  static const double md = M3EDimensions.spaceMd;

  /// 16dp - Large gap (`M3ESpacing.lg`).
  static const double lg = M3EDimensions.spaceLg;

  /// 24dp - Extra Large gap (`M3ESpacing.xl`).
  static const double xl = M3EDimensions.spaceXl;

  /// 32dp - Extra Extra Large gap (`M3ESpacing.xxl`).
  static const double xxl = M3EDimensions.spaceXxl;

  /// Default regular M3 Expressive spacing scale.
  static const M3ESpacing regularScale = M3ESpacing.regular();

  // -------------------------------------------------------------------------
  // 4dp / 8dp Grid Scalar Spacing Tokens (dp)
  // -------------------------------------------------------------------------

  /// 0.0 dp - `space0` (0x) Reset, edge-to-edge alignment.
  static const double space0 = M3EDimensions.space0;

  /// 2.0 dp - `space25` (0.25x) Micro-adjustments, tight icon alignment.
  static const double space25 = 2;

  /// 4.0 dp - `space50` (0.5x) Compact component gaps, chip elements.
  static const double space50 = M3EDimensions.space4;

  /// 6.0 dp - `space75` (0.75x) Dense list item spacing.
  static const double space75 = 6;

  /// 8.0 dp - `space100` (1x Baseline) Default gap, compact padding.
  static const double space100 = M3EDimensions.space8;

  /// 10.0 dp - `space125` (1.25x) Vertical text-to-container padding.
  static const double space125 = 10;

  /// 12.0 dp - `space150` (1.5x) Focused input margins, compact card padding.
  static const double space150 = M3EDimensions.space12;

  /// 14.0 dp - `space175` (1.75x) Intermediate container padding.
  static const double space175 = 14;

  /// 16.0 dp - `space200` (2x) Standard container horizontal/vertical padding.
  static const double space200 = M3EDimensions.space16;

  /// 20.0 dp - `space250` (2.5x) Form field padding, navigation drawer gaps.
  static const double space250 = M3EDimensions.space20;

  /// 24.0 dp - `space300` (3x) Standard screen margins, hero section gaps.
  static const double space300 = M3EDimensions.space24;

  /// 28.0 dp - `space350` (3.5x) Intermediate section spacing.
  static const double space350 = M3EDimensions.space28;

  /// 32.0 dp - `space400` (4x) Large card/container margins.
  static const double space400 = M3EDimensions.space32;

  /// 36.0 dp - `space450` (4.5x) Major layout section breaks.
  static const double space450 = 36;

  /// 40.0 dp - `space500` (5x) Extended drawer/sheet padding.
  static const double space500 = M3EDimensions.space40;

  /// 48.0 dp - `space600` (6x) Tablet and desktop pane gaps.
  static const double space600 = M3EDimensions.space48;

  /// 56.0 dp - `space700` (7x) Structural layout gaps.
  static const double space700 = 56;

  /// 64.0 dp - `space800` (8x) Desktop grid gutters.
  static const double space800 = 64;

  /// 72.0 dp - `space900` (9x) Maximum layout margins.
  static const double space900 = 72;

  // -------------------------------------------------------------------------
  // EdgeInsets Helpers - Uniform (All)
  // -------------------------------------------------------------------------

  /// Zero padding.
  static const EdgeInsets paddingAllNone = EdgeInsets.zero;

  /// Uniform 2.0 dp padding (`space25`).
  static const EdgeInsets paddingAll25 = EdgeInsets.all(space25);

  /// Uniform 4.0 dp padding (`space50` / `xs`).
  static const EdgeInsets paddingAll50 = EdgeInsets.all(space50);
  static const EdgeInsets paddingAllXs = paddingAll50;

  /// Uniform 6.0 dp padding (`space75`).
  static const EdgeInsets paddingAll75 = EdgeInsets.all(space75);

  /// Uniform 8.0 dp padding (`space100` / `sm`).
  static const EdgeInsets paddingAll100 = EdgeInsets.all(space100);
  static const EdgeInsets paddingAllSm = paddingAll100;

  /// Uniform 10.0 dp padding (`space125`).
  static const EdgeInsets paddingAll125 = EdgeInsets.all(space125);

  /// Uniform 12.0 dp padding (`space150` / `md`).
  static const EdgeInsets paddingAll150 = EdgeInsets.all(space150);
  static const EdgeInsets paddingAllMd = paddingAll150;

  /// Uniform 14.0 dp padding (`space175`).
  static const EdgeInsets paddingAll175 = EdgeInsets.all(space175);

  /// Uniform 16.0 dp padding (`space200` / `lg`).
  static const EdgeInsets paddingAll200 = EdgeInsets.all(space200);
  static const EdgeInsets paddingAllLg = paddingAll200;

  /// Uniform 20.0 dp padding (`space250`).
  static const EdgeInsets paddingAll250 = EdgeInsets.all(space250);

  /// Uniform 24.0 dp padding (`space300` / `xl`).
  static const EdgeInsets paddingAll300 = EdgeInsets.all(space300);
  static const EdgeInsets paddingAllXl = paddingAll300;

  /// Uniform 28.0 dp padding (`space350`).
  static const EdgeInsets paddingAll350 = EdgeInsets.all(space350);

  /// Uniform 32.0 dp padding (`space400` / `xxl`).
  static const EdgeInsets paddingAll400 = EdgeInsets.all(space400);
  static const EdgeInsets paddingAllXxl = paddingAll400;

  /// Uniform 36.0 dp padding (`space450`).
  static const EdgeInsets paddingAll450 = EdgeInsets.all(space450);

  /// Uniform 40.0 dp padding (`space500`).
  static const EdgeInsets paddingAll500 = EdgeInsets.all(space500);

  /// Uniform 48.0 dp padding (`space600`).
  static const EdgeInsets paddingAll600 = EdgeInsets.all(space600);

  /// Uniform 56.0 dp padding (`space700`).
  static const EdgeInsets paddingAll700 = EdgeInsets.all(space700);

  /// Uniform 64.0 dp padding (`space800`).
  static const EdgeInsets paddingAll800 = EdgeInsets.all(space800);

  /// Uniform 72.0 dp padding (`space900`).
  static const EdgeInsets paddingAll900 = EdgeInsets.all(space900);

  // -------------------------------------------------------------------------
  // EdgeInsets Helpers - Horizontal Symmetric
  // -------------------------------------------------------------------------

  /// Symmetric horizontal 2.0 dp padding (`space25`).
  static const EdgeInsets paddingHorizontal25 =
      EdgeInsets.symmetric(horizontal: space25);

  /// Symmetric horizontal 4.0 dp padding (`space50` / `xs`).
  static const EdgeInsets paddingHorizontal50 =
      EdgeInsets.symmetric(horizontal: space50);
  static const EdgeInsets paddingHorizontalXs = paddingHorizontal50;

  /// Symmetric horizontal 6.0 dp padding (`space75`).
  static const EdgeInsets paddingHorizontal75 =
      EdgeInsets.symmetric(horizontal: space75);

  /// Symmetric horizontal 8.0 dp padding (`space100` / `sm`).
  static const EdgeInsets paddingHorizontal100 =
      EdgeInsets.symmetric(horizontal: space100);
  static const EdgeInsets paddingHorizontalSm = paddingHorizontal100;

  /// Symmetric horizontal 10.0 dp padding (`space125`).
  static const EdgeInsets paddingHorizontal125 =
      EdgeInsets.symmetric(horizontal: space125);

  /// Symmetric horizontal 12.0 dp padding (`space150` / `md`).
  static const EdgeInsets paddingHorizontal150 =
      EdgeInsets.symmetric(horizontal: space150);
  static const EdgeInsets paddingHorizontalMd = paddingHorizontal150;

  /// Symmetric horizontal 14.0 dp padding (`space175`).
  static const EdgeInsets paddingHorizontal175 =
      EdgeInsets.symmetric(horizontal: space175);

  /// Symmetric horizontal 16.0 dp padding (`space200` / `lg`).
  static const EdgeInsets paddingHorizontal200 =
      EdgeInsets.symmetric(horizontal: space200);
  static const EdgeInsets paddingHorizontalLg = paddingHorizontal200;

  /// Symmetric horizontal 20.0 dp padding (`space250`).
  static const EdgeInsets paddingHorizontal250 =
      EdgeInsets.symmetric(horizontal: space250);

  /// Symmetric horizontal 24.0 dp padding (`space300` / `xl`).
  static const EdgeInsets paddingHorizontal300 =
      EdgeInsets.symmetric(horizontal: space300);
  static const EdgeInsets paddingHorizontalXl = paddingHorizontal300;

  /// Symmetric horizontal 28.0 dp padding (`space350`).
  static const EdgeInsets paddingHorizontal350 =
      EdgeInsets.symmetric(horizontal: space350);

  /// Symmetric horizontal 32.0 dp padding (`space400` / `xxl`).
  static const EdgeInsets paddingHorizontal400 =
      EdgeInsets.symmetric(horizontal: space400);
  static const EdgeInsets paddingHorizontalXxl = paddingHorizontal400;

  /// Symmetric horizontal 36.0 dp padding (`space450`).
  static const EdgeInsets paddingHorizontal450 =
      EdgeInsets.symmetric(horizontal: space450);

  /// Symmetric horizontal 40.0 dp padding (`space500`).
  static const EdgeInsets paddingHorizontal500 =
      EdgeInsets.symmetric(horizontal: space500);

  /// Symmetric horizontal 48.0 dp padding (`space600`).
  static const EdgeInsets paddingHorizontal600 =
      EdgeInsets.symmetric(horizontal: space600);

  /// Symmetric horizontal 56.0 dp padding (`space700`).
  static const EdgeInsets paddingHorizontal700 =
      EdgeInsets.symmetric(horizontal: space700);

  /// Symmetric horizontal 64.0 dp padding (`space800`).
  static const EdgeInsets paddingHorizontal800 =
      EdgeInsets.symmetric(horizontal: space800);

  /// Symmetric horizontal 72.0 dp padding (`space900`).
  static const EdgeInsets paddingHorizontal900 =
      EdgeInsets.symmetric(horizontal: space900);

  // -------------------------------------------------------------------------
  // EdgeInsets Helpers - Vertical Symmetric
  // -------------------------------------------------------------------------

  /// Symmetric vertical 2.0 dp padding (`space25`).
  static const EdgeInsets paddingVertical25 =
      EdgeInsets.symmetric(vertical: space25);

  /// Symmetric vertical 4.0 dp padding (`space50` / `xs`).
  static const EdgeInsets paddingVertical50 =
      EdgeInsets.symmetric(vertical: space50);
  static const EdgeInsets paddingVerticalXs = paddingVertical50;

  /// Symmetric vertical 6.0 dp padding (`space75`).
  static const EdgeInsets paddingVertical75 =
      EdgeInsets.symmetric(vertical: space75);

  /// Symmetric vertical 8.0 dp padding (`space100` / `sm`).
  static const EdgeInsets paddingVertical100 =
      EdgeInsets.symmetric(vertical: space100);
  static const EdgeInsets paddingVerticalSm = paddingVertical100;

  /// Symmetric vertical 10.0 dp padding (`space125`).
  static const EdgeInsets paddingVertical125 =
      EdgeInsets.symmetric(vertical: space125);

  /// Symmetric vertical 12.0 dp padding (`space150` / `md`).
  static const EdgeInsets paddingVertical150 =
      EdgeInsets.symmetric(vertical: space150);
  static const EdgeInsets paddingVerticalMd = paddingVertical150;

  /// Symmetric vertical 14.0 dp padding (`space175`).
  static const EdgeInsets paddingVertical175 =
      EdgeInsets.symmetric(vertical: space175);

  /// Symmetric vertical 16.0 dp padding (`space200` / `lg`).
  static const EdgeInsets paddingVertical200 =
      EdgeInsets.symmetric(vertical: space200);
  static const EdgeInsets paddingVerticalLg = paddingVertical200;

  /// Symmetric vertical 20.0 dp padding (`space250`).
  static const EdgeInsets paddingVertical250 =
      EdgeInsets.symmetric(vertical: space250);

  /// Symmetric vertical 24.0 dp padding (`space300` / `xl`).
  static const EdgeInsets paddingVertical300 =
      EdgeInsets.symmetric(vertical: space300);
  static const EdgeInsets paddingVerticalXl = paddingVertical300;

  /// Symmetric vertical 28.0 dp padding (`space350`).
  static const EdgeInsets paddingVertical350 =
      EdgeInsets.symmetric(vertical: space350);

  /// Symmetric vertical 32.0 dp padding (`space400` / `xxl`).
  static const EdgeInsets paddingVertical400 =
      EdgeInsets.symmetric(vertical: space400);
  static const EdgeInsets paddingVerticalXxl = paddingVertical400;

  /// Symmetric vertical 36.0 dp padding (`space450`).
  static const EdgeInsets paddingVertical450 =
      EdgeInsets.symmetric(vertical: space450);

  /// Symmetric vertical 40.0 dp padding (`space500`).
  static const EdgeInsets paddingVertical500 =
      EdgeInsets.symmetric(vertical: space500);

  /// Symmetric vertical 48.0 dp padding (`space600`).
  static const EdgeInsets paddingVertical600 =
      EdgeInsets.symmetric(vertical: space600);

  /// Symmetric vertical 56.0 dp padding (`space700`).
  static const EdgeInsets paddingVertical700 =
      EdgeInsets.symmetric(vertical: space700);

  /// Symmetric vertical 64.0 dp padding (`space800`).
  static const EdgeInsets paddingVertical800 =
      EdgeInsets.symmetric(vertical: space800);

  /// Symmetric vertical 72.0 dp padding (`space900`).
  static const EdgeInsets paddingVertical900 =
      EdgeInsets.symmetric(vertical: space900);

  // -------------------------------------------------------------------------
  // SizedBox Gap Helpers (Square)
  // -------------------------------------------------------------------------

  /// Square gap of 2.0 dp x 2.0 dp.
  static const SizedBox gap25 = SizedBox(width: space25, height: space25);

  /// Square gap of 4.0 dp x 4.0 dp.
  static const SizedBox gap50 = SizedBox(width: space50, height: space50);
  static const SizedBox gapXs = gap50;

  /// Square gap of 6.0 dp x 6.0 dp.
  static const SizedBox gap75 = SizedBox(width: space75, height: space75);

  /// Square gap of 8.0 dp x 8.0 dp.
  static const SizedBox gap100 = SizedBox(width: space100, height: space100);
  static const SizedBox gapSm = gap100;

  /// Square gap of 10.0 dp x 10.0 dp.
  static const SizedBox gap125 = SizedBox(width: space125, height: space125);

  /// Square gap of 12.0 dp x 12.0 dp.
  static const SizedBox gap150 = SizedBox(width: space150, height: space150);
  static const SizedBox gapMd = gap150;

  /// Square gap of 14.0 dp x 14.0 dp.
  static const SizedBox gap175 = SizedBox(width: space175, height: space175);

  /// Square gap of 16.0 dp x 16.0 dp.
  static const SizedBox gap200 = SizedBox(width: space200, height: space200);
  static const SizedBox gapLg = gap200;

  /// Square gap of 20.0 dp x 20.0 dp.
  static const SizedBox gap250 = SizedBox(width: space250, height: space250);

  /// Square gap of 24.0 dp x 24.0 dp.
  static const SizedBox gap300 = SizedBox(width: space300, height: space300);
  static const SizedBox gapXl = gap300;

  /// Square gap of 28.0 dp x 28.0 dp.
  static const SizedBox gap350 = SizedBox(width: space350, height: space350);

  /// Square gap of 32.0 dp x 32.0 dp.
  static const SizedBox gap400 = SizedBox(width: space400, height: space400);
  static const SizedBox gapXxl = gap400;

  /// Square gap of 36.0 dp x 36.0 dp.
  static const SizedBox gap450 = SizedBox(width: space450, height: space450);

  /// Square gap of 40.0 dp x 40.0 dp.
  static const SizedBox gap500 = SizedBox(width: space500, height: space500);

  /// Square gap of 48.0 dp x 48.0 dp.
  static const SizedBox gap600 = SizedBox(width: space600, height: space600);

  /// Square gap of 56.0 dp x 56.0 dp.
  static const SizedBox gap700 = SizedBox(width: space700, height: space700);

  /// Square gap of 64.0 dp x 64.0 dp.
  static const SizedBox gap800 = SizedBox(width: space800, height: space800);

  /// Square gap of 72.0 dp x 72.0 dp.
  static const SizedBox gap900 = SizedBox(width: space900, height: space900);

  // -------------------------------------------------------------------------
  // Vertical SizedBox Gap Helpers
  // -------------------------------------------------------------------------

  /// Vertical gap of 2.0 dp.
  static const SizedBox vGap25 = SizedBox(height: space25);

  /// Vertical gap of 4.0 dp.
  static const SizedBox vGap50 = SizedBox(height: space50);
  static const SizedBox vGapXs = vGap50;

  /// Vertical gap of 6.0 dp.
  static const SizedBox vGap75 = SizedBox(height: space75);

  /// Vertical gap of 8.0 dp.
  static const SizedBox vGap100 = SizedBox(height: space100);
  static const SizedBox vGapSm = vGap100;

  /// Vertical gap of 10.0 dp.
  static const SizedBox vGap125 = SizedBox(height: space125);

  /// Vertical gap of 12.0 dp.
  static const SizedBox vGap150 = SizedBox(height: space150);
  static const SizedBox vGapMd = vGap150;

  /// Vertical gap of 14.0 dp.
  static const SizedBox vGap175 = SizedBox(height: space175);

  /// Vertical gap of 16.0 dp.
  static const SizedBox vGap200 = SizedBox(height: space200);
  static const SizedBox vGapLg = vGap200;

  /// Vertical gap of 20.0 dp.
  static const SizedBox vGap250 = SizedBox(height: space250);

  /// Vertical gap of 24.0 dp.
  static const SizedBox vGap300 = SizedBox(height: space300);
  static const SizedBox vGapXl = vGap300;

  /// Vertical gap of 28.0 dp.
  static const SizedBox vGap350 = SizedBox(height: space350);

  /// Vertical gap of 32.0 dp.
  static const SizedBox vGap400 = SizedBox(height: space400);
  static const SizedBox vGapXxl = vGap400;

  /// Vertical gap of 36.0 dp.
  static const SizedBox vGap450 = SizedBox(height: space450);

  /// Vertical gap of 40.0 dp.
  static const SizedBox vGap500 = SizedBox(height: space500);

  /// Vertical gap of 48.0 dp.
  static const SizedBox vGap600 = SizedBox(height: space600);

  /// Vertical gap of 56.0 dp.
  static const SizedBox vGap700 = SizedBox(height: space700);

  /// Vertical gap of 64.0 dp.
  static const SizedBox vGap800 = SizedBox(height: space800);

  /// Vertical gap of 72.0 dp.
  static const SizedBox vGap900 = SizedBox(height: space900);

  // -------------------------------------------------------------------------
  // Horizontal SizedBox Gap Helpers
  // -------------------------------------------------------------------------

  /// Horizontal gap of 2.0 dp.
  static const SizedBox hGap25 = SizedBox(width: space25);

  /// Horizontal gap of 4.0 dp.
  static const SizedBox hGap50 = SizedBox(width: space50);
  static const SizedBox hGapXs = hGap50;

  /// Horizontal gap of 6.0 dp.
  static const SizedBox hGap75 = SizedBox(width: space75);

  /// Horizontal gap of 8.0 dp.
  static const SizedBox hGap100 = SizedBox(width: space100);
  static const SizedBox hGapSm = hGap100;

  /// Horizontal gap of 10.0 dp.
  static const SizedBox hGap125 = SizedBox(width: space125);

  /// Horizontal gap of 12.0 dp.
  static const SizedBox hGap150 = SizedBox(width: space150);
  static const SizedBox hGapMd = hGap150;

  /// Horizontal gap of 14.0 dp.
  static const SizedBox hGap175 = SizedBox(width: space175);

  /// Horizontal gap of 16.0 dp.
  static const SizedBox hGap200 = SizedBox(width: space200);
  static const SizedBox hGapLg = hGap200;

  /// Horizontal gap of 20.0 dp.
  static const SizedBox hGap250 = SizedBox(width: space250);

  /// Horizontal gap of 24.0 dp.
  static const SizedBox hGap300 = SizedBox(width: space300);
  static const SizedBox hGapXl = hGap300;

  /// Horizontal gap of 28.0 dp.
  static const SizedBox hGap350 = SizedBox(width: space350);

  /// Horizontal gap of 32.0 dp.
  static const SizedBox hGap400 = SizedBox(width: space400);
  static const SizedBox hGapXxl = hGap400;

  /// Horizontal gap of 36.0 dp.
  static const SizedBox hGap450 = SizedBox(width: space450);

  /// Horizontal gap of 40.0 dp.
  static const SizedBox hGap500 = SizedBox(width: space500);

  /// Horizontal gap of 48.0 dp.
  static const SizedBox hGap600 = SizedBox(width: space600);

  /// Horizontal gap of 56.0 dp.
  static const SizedBox hGap700 = SizedBox(width: space700);

  /// Horizontal gap of 64.0 dp.
  static const SizedBox hGap800 = SizedBox(width: space800);

  /// Horizontal gap of 72.0 dp.
  static const SizedBox hGap900 = SizedBox(width: space900);

  // -------------------------------------------------------------------------
  // Utility Formula
  // -------------------------------------------------------------------------

  /// Calculates custom token value based on standard baseline formula:
  /// `space{N} = 8dp * (N / 100)`.
  static double customToken(int tokenNumber) {
    return 8.0 * (tokenNumber / 100.0);
  }
}
