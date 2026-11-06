import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Time Picker
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Time Picker components, dialogs,
// tokens, and models directly from package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EDayPeriodControl,
        M3EDialTimePicker,
        M3EHourMinuteTextField,
        M3EInputTimePickerFormField,
        M3ETime,
        M3ETimePicker,
        M3ETimePickerActions,
        M3ETimePickerConstants,
        M3ETimePickerDialog,
        M3ETimePickerDialogContent,
        M3ETimePickerEntryMode,
        M3ETimePickerHeader,
        M3ETimePickerTheme,
        M3ETimePickerUtils;

/// Alias for [M3ETimePicker] to maintain standard project naming.
typedef AppTimePicker = M3ETimePicker;

/// Alias for [M3ETimePickerDialog] to maintain standard project naming.
typedef AppTimePickerDialog = M3ETimePickerDialog;

/// Alias for [M3EDialTimePicker] to maintain standard project naming.
typedef AppDialTimePicker = M3EDialTimePicker;

/// Alias for [M3EInputTimePickerFormField] to maintain standard project naming.
typedef AppInputTimePickerFormField = M3EInputTimePickerFormField;

/// Alias for [M3ETime] to maintain standard project naming.
typedef AppTime = M3ETime;

/// Alias for [M3ETimePickerEntryMode] to maintain standard project naming.
typedef AppTimePickerEntryMode = M3ETimePickerEntryMode;

/// Alias for [M3ETimePickerTheme] to maintain standard project naming.
typedef AppTimePickerTheme = M3ETimePickerTheme;

/// Shows a Material 3 Expressive time picker dialog.
Future<AppTime?> showAppTimePicker({
  required BuildContext context,
  required AppTime initialTime,
  AppTimePickerEntryMode initialEntryMode = AppTimePickerEntryMode.dial,
  String? helpText,
  String? cancelText,
  String? confirmText,
  String? errorInvalidText,
  String? hourLabelText,
  String? minuteLabelText,
  Orientation? orientation,
  bool? alwaysUse24HourFormat,
  bool emptyInitialInput = false,
  bool barrierDismissible = true,
  String? restorationId,
  ValueChanged<AppTimePickerEntryMode>? onTimePickerModeChange,
  EdgeInsets insetPadding = M3ETimePickerConstants.defaultInsetPadding,
  bool? resizeToAvoidBottomInset,
}) {
  return M3ETimePicker.show(
    context,
    initialTime: initialTime,
    initialEntryMode: initialEntryMode,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    errorInvalidText: errorInvalidText,
    hourLabelText: hourLabelText,
    minuteLabelText: minuteLabelText,
    orientation: orientation,
    alwaysUse24HourFormat: alwaysUse24HourFormat,
    emptyInitialInput: emptyInitialInput,
    barrierDismissible: barrierDismissible,
    restorationId: restorationId,
    onTimePickerModeChange: onTimePickerModeChange,
    insetPadding: insetPadding,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
  );
}
