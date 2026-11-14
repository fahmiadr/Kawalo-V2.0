import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as mui;

export 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EButtonFontSize,
        M3EColorScheme,
        M3EInheritedTheme,
        M3EMaterialApp,
        M3EResolvedTheme,
        M3ETheme,
        M3EThemeController,
        M3EThemeData,
        M3EThemeScope,
        M3ETypeRole,
        M3ETypeScale,
        M3ETypeScaleMode,
        M3ETypeScaleVariant,
        M3ETypeStyleConversion,
        M3ETypeStyleTokens,
        M3ETypeVariations,
        M3ETypefaceConfig,
        M3ETypography,
        M3EVariableFontAxes,
        M3EVariableFontConfig;

/// Pure Material 3 Expressive Application Theme Configuration.
abstract final class AppTheme {
  const AppTheme._();

  /// Unified localization delegates supporting both Flutter SDK and
  /// Material 3 Expressive (material_ui).
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    ...GlobalMaterialLocalizations.delegates,
    ...mui.GlobalMaterialLocalizations.delegates,
  ];

  /// Supported locales for Kawalo Mobile.
  static const List<Locale> supportedLocales = [
    Locale('id', 'ID'),
    Locale('id'),
    Locale('en', 'US'),
    Locale('en'),
  ];

  /// Primary Brand Seed Color for Kawalo.
  static const Color brandPrimary = Color(0xFF316A42);

  /// Default Font Family for Material 3 Expressive typography.
  static const String defaultFontFamily = 'Hanken Grotesk';

  /// Accesses the nearest Material 3 Expressive [M3EThemeData] from [context].
  static M3EThemeData of(BuildContext context) => M3ETheme.of(context);

  /// Accesses the Material 3 Expressive [M3EColorScheme] from [context].
  static M3EColorScheme colorSchemeOf(BuildContext context) =>
      M3ETheme.of(context).colorScheme;

  /// Accesses the Material 3 Expressive [M3ETypeScale] from [context].
  static M3ETypeScale typeScaleOf(BuildContext context) =>
      M3ETheme.of(context).typeScale;

  /// Accesses the Material 3 Expressive [M3ETypography] from [context].
  static M3ETypography typographyOf(BuildContext context) =>
      M3ETheme.of(context).typography;

  /// Accesses the Expressive Emphasized [M3ETypeScale] from [context].
  static M3ETypeScale emphasizedTypeScaleOf(BuildContext context) =>
      M3ETheme.of(context).typography.emphasized;

  /// Expressive Light Theme.
  static M3EThemeData m3eLight({String? fontFamily = defaultFontFamily}) {
    final theme = M3EThemeData.light(seedColor: brandPrimary);
    return fontFamily != null ? theme.copyWith(fontFamily: fontFamily) : theme;
  }

  /// Expressive Dark Theme.
  static M3EThemeData m3eDark({String? fontFamily = defaultFontFamily}) {
    final theme = M3EThemeData.dark(seedColor: brandPrimary);
    return fontFamily != null ? theme.copyWith(fontFamily: fontFamily) : theme;
  }

  /// Expressive Light ColorScheme.
  static ColorScheme lightColorScheme() =>
      ColorScheme.fromSeed(seedColor: brandPrimary);

  /// Expressive Dark ColorScheme.
  static ColorScheme darkColorScheme() => ColorScheme.fromSeed(
    seedColor: brandPrimary,
    brightness: Brightness.dark,
  );

  /// Style for clock times, durations and counts. The redesign asks for IBM
  /// Plex Mono, which is not bundled (no font assets in pubspec), so it uses
  /// tabular figures of the app font: digits keep a fixed width as they tick.
  static const TextStyle monoFigures = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Standard light ThemeData helper converted with Material 3 Expressive
  /// tokens for screens and widgets requiring Flutter [ThemeData].
  static ThemeData lightThemeData({String? fontFamily = defaultFontFamily}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme(),
      fontFamily: fontFamily,
      extensions: const [KawaloTones.light],
    );
  }

  /// Standard dark ThemeData helper converted with Material 3 Expressive
  /// tokens for screens and widgets requiring Flutter [ThemeData].
  static ThemeData darkThemeData({String? fontFamily = defaultFontFamily}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme(),
      fontFamily: fontFamily,
      extensions: const [KawaloTones.dark],
    );
  }
}
