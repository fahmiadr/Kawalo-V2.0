import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Date Picker Wrapper
// ---------------------------------------------------------------------------
// Wraps Flutter's official DatePicker with custom Material 3 Expressive
// styling: Kawalo Brand colors, Hanken Grotesk typography, input field
// decoration, pressed state layers, and rounded container shape, while
// maintaining 100% complete localization support across 180+ languages
// via Flutter's GlobalMaterialLocalizations.

/// Alias for [DatePickerDialog] to maintain standard project naming.
typedef AppDatePickerDialog = DatePickerDialog;

/// Alias for [DateRangePickerDialog] to maintain standard project naming.
typedef AppDateRangePickerDialog = DateRangePickerDialog;

/// Alias for [CalendarDatePicker] to maintain standard project naming.
typedef AppCalendarDatePicker = CalendarDatePicker;

/// Alias for [DatePickerThemeData] to maintain standard project naming.
typedef AppDatePickerTheme = DatePickerThemeData;

/// Alias for [DatePickerEntryMode] to maintain standard project naming.
typedef AppDatePickerEntryMode = DatePickerEntryMode;

/// Alias for [DatePickerMode] to maintain standard project naming.
typedef AppDatePickerMode = DatePickerMode;

/// Alias for [DateTimeRange] to maintain standard project naming.
typedef AppDateRange = DateTimeRange;

/// Alias for [InputDatePickerFormField] to maintain standard project naming.
typedef AppInputDatePickerFormField = InputDatePickerFormField;

/// Builds an expressive [DatePickerThemeData] matching Kawalo's design tokens,
/// including day/year pressed state layers and range selection overlays.
DatePickerThemeData buildExpressiveDatePickerTheme(BuildContext context) {
  final m3eTheme = AppTheme.of(context);
  final colorScheme = m3eTheme.colorScheme;

  return DatePickerThemeData(
    backgroundColor: colorScheme.surfaceContainerHigh,
    elevation: 6,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    headerBackgroundColor: colorScheme.primary,
    headerForegroundColor: colorScheme.onPrimary,
    headerHeadlineStyle: m3eTheme.typography.emphasized.headlineSmall,
    headerHelpStyle: m3eTheme.typeScale.labelMedium.copyWith(
      color: colorScheme.onPrimary.withValues(alpha: 0.85),
    ),
    subHeaderForegroundColor: colorScheme.onSurface,
    dividerColor: colorScheme.outlineVariant,
    weekdayStyle: m3eTheme.typography.emphasized.bodySmall.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    dayStyle: m3eTheme.typeScale.bodyMedium,
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.onPrimary;
      }
      if (states.contains(WidgetState.disabled)) {
        return colorScheme.onSurface.withValues(alpha: 0.38);
      }
      return colorScheme.onSurface;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary;
      }
      return null;
    }),
    // Pressed, hover, and focus state layers for calendar days
    dayOverlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimary.withValues(alpha: 0.12)
            : colorScheme.primary.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimary.withValues(alpha: 0.08)
            : colorScheme.primary.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimary.withValues(alpha: 0.12)
            : colorScheme.primary.withValues(alpha: 0.12);
      }
      return null;
    }),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.onPrimary;
      }
      return colorScheme.primary;
    }),
    todayBorder: BorderSide(
      color: colorScheme.primary,
      width: 1.5,
    ),
    yearStyle: m3eTheme.typeScale.bodyMedium,
    yearForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.onPrimary;
      }
      return colorScheme.onSurface;
    }),
    yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary;
      }
      return null;
    }),
    // Pressed, hover, and focus state layers for year picker items
    yearOverlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimary.withValues(alpha: 0.12)
            : colorScheme.primary.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimary.withValues(alpha: 0.08)
            : colorScheme.primary.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimary.withValues(alpha: 0.12)
            : colorScheme.primary.withValues(alpha: 0.12);
      }
      return null;
    }),
    // Range picker styling
    rangePickerBackgroundColor: colorScheme.surfaceContainerHigh,
    rangePickerElevation: 6,
    rangePickerShadowColor: Colors.black26,
    rangePickerSurfaceTintColor: Colors.transparent,
    rangePickerShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    rangePickerHeaderBackgroundColor: colorScheme.primary,
    rangePickerHeaderForegroundColor: colorScheme.onPrimary,
    rangePickerHeaderHeadlineStyle:
        m3eTheme.typography.emphasized.headlineSmall,
    rangePickerHeaderHelpStyle: m3eTheme.typeScale.labelMedium.copyWith(
      color: colorScheme.onPrimary.withValues(alpha: 0.85),
    ),
    rangeSelectionBackgroundColor:
        colorScheme.primary.withValues(alpha: 0.15),
    rangeSelectionOverlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return colorScheme.primary.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return colorScheme.primary.withValues(alpha: 0.08);
      }
      return null;
    }),
    // Action button styles with Kawalo Brand Green and pressed ripples
    confirmButtonStyle: ButtonStyle(
      textStyle: WidgetStatePropertyAll(
        m3eTheme.typography.emphasized.labelLarge,
      ),
      foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        return null;
      }),
    ),
    cancelButtonStyle: ButtonStyle(
      textStyle: WidgetStatePropertyAll(
        m3eTheme.typography.emphasized.labelLarge,
      ),
      foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        return null;
      }),
    ),
  );
}

/// Builds a comprehensive [ThemeData] for the Date Picker dialog
/// that styles the calendar surface, the text input mode fields
/// (InputDatePickerFormField), the cursor, selection handles, and icons.
ThemeData buildExpressiveDatePickerDialogTheme(BuildContext context) {
  final m3eTheme = AppTheme.of(context);
  final baseTheme = Theme.of(context);
  final isDark = baseTheme.brightness == Brightness.dark;
  final colorScheme =
      isDark ? AppTheme.darkColorScheme() : AppTheme.lightColorScheme();

  return baseTheme.copyWith(
    colorScheme: colorScheme,
    datePickerTheme: buildExpressiveDatePickerTheme(context),
    // Input Mode Theme: Styles the text field when switching
    // to manual typing mode
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: m3eTheme.typeScale.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      floatingLabelStyle: m3eTheme.typography.emphasized.bodySmall.copyWith(
        color: colorScheme.primary,
      ),
      hintStyle: m3eTheme.typeScale.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      helperStyle: m3eTheme.typeScale.bodySmall.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      errorStyle: m3eTheme.typeScale.bodySmall.copyWith(
        color: colorScheme.error,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    ),
    // Cursor, selection highlight, and handle colors
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primary.withValues(alpha: 0.25),
      selectionHandleColor: colorScheme.primary,
    ),
    // Ripple and state layer colors for all dialog InkWells
    splashColor: colorScheme.primary.withValues(alpha: 0.12),
    highlightColor: Colors.transparent,
    hoverColor: colorScheme.primary.withValues(alpha: 0.08),
    focusColor: colorScheme.primary.withValues(alpha: 0.12),
    iconTheme: IconThemeData(
      color: colorScheme.onSurfaceVariant,
    ),
    // Icon button styles for month chevrons and mode toggle
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.onSurfaceVariant;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
    ),
    // Action button fallback styling
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          m3eTheme.typography.emphasized.labelLarge,
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.primary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          return null;
        }),
      ),
    ),
  );
}

/// Shows a Material 3 Expressive single date picker dialog.
///
/// Automatically clamps [initialDate] within [[firstDate], [lastDate]]
/// and normalizes all dates with [DateUtils.dateOnly] to prevent
/// runtime boundary assertion exceptions.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
  DateTime? currentDate,
  AppDatePickerEntryMode initialEntryMode = AppDatePickerEntryMode.calendar,
  SelectableDayPredicate? selectableDayPredicate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  AppDatePickerMode initialCalendarMode = AppDatePickerMode.day,
  String? errorFormatText,
  String? errorInvalidText,
  String? fieldHintText,
  String? fieldLabelText,
  TextInputType? keyboardType,
  bool barrierDismissible = true,
  String? restorationId,
  ValueChanged<AppDatePickerEntryMode>? onDatePickerModeChange,
  bool useRootNavigator = true,
}) {
  final normalizedFirstDate = DateUtils.dateOnly(firstDate);
  final normalizedLastDate = DateUtils.dateOnly(lastDate);
  final targetInitial = initialDate ?? DateTime.now();
  final normalizedInitial = DateUtils.dateOnly(targetInitial);

  final safeInitialDate = normalizedInitial.isBefore(normalizedFirstDate)
      ? normalizedFirstDate
      : (normalizedInitial.isAfter(normalizedLastDate)
          ? normalizedLastDate
          : normalizedInitial);

  return showDatePicker(
    context: context,
    firstDate: normalizedFirstDate,
    lastDate: normalizedLastDate,
    initialDate: safeInitialDate,
    currentDate: currentDate != null ? DateUtils.dateOnly(currentDate) : null,
    initialEntryMode: initialEntryMode,
    selectableDayPredicate: selectableDayPredicate,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    initialDatePickerMode: initialCalendarMode,
    errorFormatText: errorFormatText,
    errorInvalidText: errorInvalidText,
    fieldHintText: fieldHintText,
    fieldLabelText: fieldLabelText,
    keyboardType: keyboardType,
    barrierDismissible: barrierDismissible,
    routeSettings:
        restorationId != null ? RouteSettings(name: restorationId) : null,
    onDatePickerModeChange: onDatePickerModeChange,
    useRootNavigator: useRootNavigator,
    builder: (context, child) {
      final dialogTheme = buildExpressiveDatePickerDialogTheme(context);
      return Theme(
        data: dialogTheme,
        child: child!,
      );
    },
  );
}

/// Shows a Material 3 Expressive date range picker dialog.
///
/// Automatically clamps and normalizes all dates with [DateUtils.dateOnly]
/// to prevent runtime boundary assertion exceptions.
Future<AppDateRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  DateTime? currentDate,
  AppDatePickerEntryMode initialEntryMode = AppDatePickerEntryMode.calendar,
  String? helpText,
  String? cancelText,
  String? confirmText,
  String? saveText,
  String? errorFormatText,
  String? errorInvalidText,
  String? fieldStartHintText,
  String? fieldEndHintText,
  String? fieldStartLabelText,
  String? fieldEndLabelText,
  bool barrierDismissible = true,
  String? restorationId,
  bool useRootNavigator = true,
}) {
  final normalizedFirstDate = DateUtils.dateOnly(firstDate);
  final normalizedLastDate = DateUtils.dateOnly(lastDate);

  DateTimeRange? initialRange;
  if (initialStartDate != null && initialEndDate != null) {
    final start = DateUtils.dateOnly(initialStartDate);
    final end = DateUtils.dateOnly(initialEndDate);
    if (!start.isAfter(end) &&
        !start.isBefore(normalizedFirstDate) &&
        !end.isAfter(normalizedLastDate)) {
      initialRange = DateTimeRange(start: start, end: end);
    }
  }

  return showDateRangePicker(
    context: context,
    firstDate: normalizedFirstDate,
    lastDate: normalizedLastDate,
    initialDateRange: initialRange,
    currentDate: currentDate != null ? DateUtils.dateOnly(currentDate) : null,
    initialEntryMode: initialEntryMode,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    saveText: saveText,
    errorFormatText: errorFormatText,
    errorInvalidText: errorInvalidText,
    fieldStartHintText: fieldStartHintText,
    fieldEndHintText: fieldEndHintText,
    fieldStartLabelText: fieldStartLabelText,
    fieldEndLabelText: fieldEndLabelText,
    barrierDismissible: barrierDismissible,
    routeSettings:
        restorationId != null ? RouteSettings(name: restorationId) : null,
    useRootNavigator: useRootNavigator,
    builder: (context, child) {
      final dialogTheme = buildExpressiveDatePickerDialogTheme(context);
      return Theme(
        data: dialogTheme,
        child: child!,
      );
    },
  );
}
