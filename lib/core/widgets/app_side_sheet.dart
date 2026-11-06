import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Side Sheet
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Side Sheet components, dialogs,
// and themes directly from package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3ESideSheet, M3ESideSheetTheme;

/// Alias for [M3ESideSheet] to maintain standard project naming.
typedef AppSideSheet = M3ESideSheet;

/// Alias for [M3ESideSheetTheme] to maintain standard project naming.
typedef AppSideSheetTheme = M3ESideSheetTheme;

/// Presents a modal Material 3 Expressive side sheet sliding from the trailing
/// edge.
Future<T?> showAppSideSheet<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  List<Widget> actions = const <Widget>[],
}) {
  return M3ESideSheet.show<T>(
    context,
    title: title,
    body: body,
    actions: actions,
  );
}
