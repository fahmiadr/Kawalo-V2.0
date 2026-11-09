import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:kawalo_mobile/core/theme/app_elevation.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Bottom Sheet
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Bottom Sheet tokens and theme,
// with an enhanced interactive follow-the-finger drag gesture and coordinated
// scroll boundary handling.

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EBottomSheetTheme;

/// Alias for [M3EBottomSheetTheme] to maintain standard project naming.
typedef AppBottomSheetTheme = M3EBottomSheetTheme;

/// A Material 3 Expressive bottom sheet with enhanced interactive drag
/// gestures.
///
/// Features:
/// 1. **Interactive follow-the-finger drag**: Sheet translates smoothly in
///    real time as the user drags.
/// 2. **Spring physics snap-back**: Snaps back on small drags, or dismisses
///    when dragged past the [dismissThreshold] or flicked downwards.
/// 3. **Single route transition**: Pure M3E entrance/exit transitions with
///    zero double-sheet flash or race conditions.
/// 4. **Scroll boundary coordination**: Content can be dragged down when at the
///    top boundary without accidental dismissals during continuous scrolling.
class AppBottomSheet extends StatefulWidget {
  /// Creates an [AppBottomSheet].
  const AppBottomSheet({
    required this.child,
    this.showDragHandle = true,
    this.enableDrag = true,
    this.dismissThreshold = 0.35,
    this.onDismissed,
    this.maxHeight,
    this.maxHeightFactor = 0.85,
    super.key,
  }) : assert(
         maxHeightFactor > 0 && maxHeightFactor <= 0.90,
         'maxHeightFactor must be between 0.0 and 0.90 (per Material 3, '
         'bottom sheets must not cover the full screen)',
       );

  /// The primary content inside the bottom sheet.
  final Widget child;

  /// Whether to display the visual drag handle indicator at the top.
  final bool showDragHandle;

  /// Whether drag-to-dismiss gesture is enabled.
  final bool enableDrag;

  /// Fraction of sheet height required to trigger dismiss on drag release.
  final double dismissThreshold;

  /// Optional callback invoked when the sheet finishes dismissing.
  /// If null, [Navigator.maybePop] is called.
  final VoidCallback? onDismissed;

  /// Explicit maximum height in logical pixels. If provided, overrides
  /// [maxHeightFactor].
  final double? maxHeight;

  /// Maximum fraction of screen height that the sheet may occupy.
  /// Defaults to 0.85 per Material 3 Expressive guidelines (maximum allowed
  /// is 0.90 so scrim and context remain visible).
  final double maxHeightFactor;

  @override
  State<AppBottomSheet> createState() => _AppBottomSheetState();
}

class _AppBottomSheetState extends State<AppBottomSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey _sheetKey = GlobalKey();
  late final AnimationController _snapController;
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _scrollStartedAtTop = false;

  double get _sheetHeight {
    final context = _sheetKey.currentContext;
    final renderBox = context?.findRenderObject() as RenderBox?;
    return renderBox?.size.height ?? 300.0;
  }

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _dragOffset = _snapController.value;
        });
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enableDrag || _isDismissing) return;
    _snapController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag || _isDismissing) return;
    final delta = details.primaryDelta ?? 0.0;
    setState(() {
      if (_dragOffset + delta < 0) {
        // Rubber-band resistance when pulling above resting position
        _dragOffset += delta * 0.15;
      } else {
        _dragOffset += delta;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enableDrag || _isDismissing) return;
    final velocity = details.primaryVelocity ?? 0.0;
    final height = _sheetHeight;

    final shouldDismiss =
        _dragOffset > height * widget.dismissThreshold || velocity > 300;

    if (shouldDismiss) {
      _dismiss();
    } else {
      _snapBack(velocity);
    }
  }

  void _snapBack(double velocity) {
    final isReducedMotion = AppMotion.isReducedMotion(context);
    if (isReducedMotion) {
      setState(() {
        _dragOffset = 0.0;
      });
      return;
    }

    _snapController.value = _dragOffset;
    final simulation = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 700, damping: 25),
      _dragOffset,
      0,
      velocity,
    );
    _snapController.animateWith(simulation);
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    if (widget.onDismissed != null) {
      widget.onDismissed!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.enableDrag || _isDismissing) return false;

    if (notification is ScrollStartNotification) {
      _scrollStartedAtTop = notification.metrics.pixels <= 0.0;
      if (_scrollStartedAtTop) {
        _snapController.stop();
      }
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if (_scrollStartedAtTop &&
          notification.metrics.pixels <= 0.0 &&
          delta < 0) {
        setState(() {
          _dragOffset += -delta;
        });
      }
    } else if (notification is OverscrollNotification) {
      if (_scrollStartedAtTop && notification.overscroll < 0) {
        setState(() {
          _dragOffset += -notification.overscroll;
        });
      }
    } else if (notification is ScrollEndNotification ||
        notification is UserScrollNotification) {
      if (_scrollStartedAtTop && _dragOffset > 0) {
        final height = _sheetHeight;
        if (_dragOffset > height * widget.dismissThreshold) {
          _dismiss();
        } else {
          _snapBack(0);
        }
      }
      if (notification is ScrollEndNotification) {
        _scrollStartedAtTop = false;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final sheetTheme = M3ETheme.of(context).bottomSheetTheme;
    final scheme = theme.colorScheme;

    final visualOffset = _dragOffset.clamp(0.0, double.infinity);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final effectiveMaxHeight =
        widget.maxHeight ??
        (screenHeight > 0
            ? screenHeight * widget.maxHeightFactor
            : double.infinity);

    Widget sheetContent = Container(
      key: _sheetKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: sheetTheme.containerColor(scheme),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(sheetTheme.topCornerRadius),
        ),
        boxShadow: AppElevation.shadows(
          AppElevation.level1,
          shadowColor: scheme.shadow,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showDragHandle)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: _buildHandle(scheme, sheetTheme),
                ),
              Flexible(child: widget.child),
            ],
          ),
        ),
      ),
    );

    if (widget.enableDrag) {
      sheetContent = _AppBottomSheetGestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: sheetContent,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: Offset(0, visualOffset),
          child: ConstrainedBox(
            key: const ValueKey('app_bottom_sheet_constrained_box'),
            constraints: BoxConstraints(
              maxWidth: sheetTheme.maxWidth,
              maxHeight: effectiveMaxHeight,
            ),
            child: sheetContent,
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(M3EColorScheme scheme, M3EBottomSheetTheme sheetTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sheetTheme.handleVerticalPadding),
      child: Center(
        child: Container(
          width: sheetTheme.handleWidth,
          height: sheetTheme.handleHeight,
          decoration: BoxDecoration(
            color: sheetTheme.handleColor(scheme),
            borderRadius: M3EShapes.resolve(sheetTheme.handleCornerRadius),
          ),
        ),
      ),
    );
  }
}

bool _isAppBottomSheetActive = false;

/// Mengembalikan status apakah terdapat [AppBottomSheet] yang sedang aktif.
bool get isAppBottomSheetActive => _isAppBottomSheetActive;

/// Mereset status aktif bottom sheet (untuk kebutuhan pengujian otomatis).
@visibleForTesting
void resetAppBottomSheetActiveForTesting() {
  _isAppBottomSheetActive = false;
}

/// Presents an [AppBottomSheet] modally across screens with interactive drag.
///
/// Ensures single-instance guardrail: only one bottom sheet can be opened
/// at any given time across the entire application, preventing rapid
/// double-tap or overlapping stacked bottom sheets.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool showDragHandle = true,
  bool enableDrag = true,
  bool barrierDismissible = true,
  double? maxHeight,
  double maxHeightFactor = 0.85,
  M3EThemeData? m3eTheme,
  ThemeData? themeData,
}) async {
  if (_isAppBottomSheetActive) {
    return null;
  }
  _isAppBottomSheetActive = true;

  try {
    final effectiveM3eTheme = m3eTheme ?? M3ETheme.of(context);
    final sheetTheme = effectiveM3eTheme.bottomSheetTheme;

    return await Navigator.of(context).push<T>(
      _AppBottomSheetRoute<T>(
        builder: (context) => child,
        sheetTheme: sheetTheme,
        colorScheme: effectiveM3eTheme.colorScheme,
        m3eTheme: m3eTheme,
        themeData: themeData,
        showDragHandle: showDragHandle,
        enableDrag: enableDrag,
        barrierDismissible: barrierDismissible,
        maxHeight: maxHeight,
        maxHeightFactor: maxHeightFactor,
      ),
    );
  } finally {
    _isAppBottomSheetActive = false;
  }
}

/// Custom [PopupRoute] for modal bottom sheet that provides single-source
/// slide-up transition, smooth scrim fade, and clean dismiss.
class _AppBottomSheetRoute<T> extends PopupRoute<T> {
  _AppBottomSheetRoute({
    required this.builder,
    required this.sheetTheme,
    required this.colorScheme,
    this.m3eTheme,
    this.themeData,
    this.showDragHandle = true,
    this.enableDrag = true,
    this.dismissThreshold = 0.35,
    this.barrierDismissible = true,
    this.barrierLabel = 'Dismiss',
    this.maxHeight,
    this.maxHeightFactor = 0.85,
    super.settings,
  }) : assert(
         maxHeightFactor > 0 && maxHeightFactor <= 0.90,
         'maxHeightFactor must be between 0.0 and 0.90 (per Material 3, '
         'bottom sheets must not cover the full screen)',
       );

  final WidgetBuilder builder;
  final M3EBottomSheetTheme sheetTheme;
  final M3EColorScheme colorScheme;
  final M3EThemeData? m3eTheme;
  final ThemeData? themeData;
  final bool showDragHandle;
  final bool enableDrag;
  final double dismissThreshold;
  final double? maxHeight;
  final double maxHeightFactor;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  Color? get barrierColor => sheetTheme.scrimColor(colorScheme);

  @override
  Duration get transitionDuration => AppMotion.long1;

  @override
  Duration get reverseTransitionDuration => AppMotion.short3;

  @override
  void dispose() {
    _isAppBottomSheetActive = false;
    super.dispose();
  }

  void _handleDismiss() {
    final context = navigator?.context;
    final insets = context != null ? MediaQuery.viewInsetsOf(context) : null;
    if (insets != null && insets.bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    navigator?.maybePop();
  }

  @override
  Widget buildModalBarrier() {
    if (barrierColor != null && barrierColor!.a != 0) {
      final color = animation!.drive(
        ColorTween(
          begin: barrierColor!.withValues(alpha: 0),
          end: barrierColor,
        ).chain(CurveTween(curve: barrierCurve)),
      );
      return AnimatedModalBarrier(
        color: color,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
        onDismiss: _handleDismiss,
      );
    }
    return ModalBarrier(
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
      onDismiss: _handleDismiss,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var content = M3EScrimSystemUi.wrapBottomSheet(
      Align(
        alignment: Alignment.bottomCenter,
        child: AppBottomSheet(
          showDragHandle: showDragHandle,
          enableDrag: enableDrag,
          dismissThreshold: dismissThreshold,
          maxHeight: maxHeight,
          maxHeightFactor: maxHeightFactor,
          child: Builder(builder: builder),
        ),
      ),
    );

    if (m3eTheme != null) {
      content = M3ETheme(data: m3eTheme!, child: content);
    }
    if (themeData != null) {
      content = Theme(data: themeData!, child: content);
    }

    return content;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasizedDecelerate,
      reverseCurve: AppMotion.standardAccelerate,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }
}

class _AppBottomSheetGestureDetector extends StatelessWidget {
  const _AppBottomSheetGestureDetector({
    required this.child,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  final Widget child;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      excludeFromSemantics: true,
      gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(debugOwner: this),
              (instance) {
                instance
                  ..onStart = onVerticalDragStart
                  ..onUpdate = onVerticalDragUpdate
                  ..onEnd = onVerticalDragEnd
                  ..onlyAcceptDragOnThreshold = true;
              },
            ),
      },
      child: child,
    );
  }
}
