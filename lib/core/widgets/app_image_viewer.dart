import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/image_viewer/image_viewer_chrome.dart';
import 'package:kawalo_mobile/core/widgets/image_viewer/image_viewer_image_content.dart';
import 'package:kawalo_mobile/core/widgets/image_viewer/image_viewer_zoom.dart';

/// Komponen penampil gambar layar penuh multi-gambar (`AppImageViewer`)
/// yang mematuhi standar Material 3 Expressive Design dan WCAG 2.1/2.2 AA.
///
/// Fitur:
/// - Presentasi modal rute transparan fullscreen imersif
///   (`SystemUiMode.immersiveSticky`), menyembunyikan status bar dan system
///   navigation bar secara otomatis.
/// - Gestur *pinch-to-zoom* ($1\times - 4\times$) dan *double tap to zoom*.
/// - Pembatasan pan vertikal & horizontal agar foto tidak keluar dari layar.
/// - Gestur *swipe-to-dismiss* vertikal ke bawah saja dengan spring physics.
/// - Navigasi perpindahan halaman horizontal dengan page snapping.
/// - Mode imersif (*tap to toggle chrome*).
/// - Tombol tutup di kanan atas dan pill counter indeks di tengah atas.
/// - Navigasi keyboard (Escape / Arrow keys).
class AppImageViewer extends StatefulWidget {
  /// Membuat instance [AppImageViewer].
  const AppImageViewer({
    required this.imageUrls,
    super.key,
    this.initialIndex = 0,
    this.heroTagPrefix,
  }) : assert(imageUrls.length > 0, 'imageUrls tidak boleh kosong');

  /// Daftar URL gambar yang ditampilkan.
  final List<String> imageUrls;

  /// Indeks gambar awal yang ditampilkan.
  final int initialIndex;

  /// Prefiks opsional untuk Hero tag animasi transisi spasial.
  final String? heroTagPrefix;

  /// Menampilkan [AppImageViewer] melalui rute modal transparan.
  static Future<void> show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    if (imageUrls.isEmpty) return Future.value();

    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: AppDuration.medium3,
        reverseTransitionDuration: AppDuration.medium1,
        pageBuilder: (_, _, _) => AppImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex.clamp(0, imageUrls.length - 1),
          heroTagPrefix: heroTagPrefix,
        ),
        transitionsBuilder: (context, animation, _, child) {
          if (AppMotion.isReducedMotion(context)) {
            return FadeTransition(opacity: animation, child: child);
          }
          return FadeTransition(
            opacity: animation.drive(
              CurveTween(curve: AppEasing.emphasizedDecelerate),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<AppImageViewer> createState() => _AppImageViewerState();
}

class _AppImageViewerState extends State<AppImageViewer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _pageController;
  late final FocusNode _focusNode;
  late final Map<int, TransformationController> _transformControllers;
  final Map<int, Size> _imageSizes = {};

  static const SystemUiOverlayStyle _lightOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  bool _hasRestoredSystemUi = false;

  late int _currentIndex;
  bool _isCurrentPageZoomed = false;
  late final ValueNotifier<bool> _showChromeNotifier;
  Timer? _singleTapTimer;
  int _tapCount = 0;
  Offset? _lastTapPosition;

  double _dragOffsetY = 0;
  bool _isDragging = false;
  final Set<int> _activePointerIds = <int>{};
  bool _isMultiTouch = false;

  late final AnimationController _resetController;
  late final CurvedAnimation _resetCurve;
  Animation<double>? _resetAnimation;

  late final AnimationController _dismissController;
  late final CurvedAnimation _dismissCurve;
  bool _isDismissing = false;

  // ── Derived State (Uni-Directional Data Flow) ───────────────────────
  bool get _isPagingDisabled =>
      _isCurrentPageZoomed || _isMultiTouch || _isDismissing;

  double get _effectiveBackdropOpacity {
    final dragOpacity = 1.0 - (_dragOffsetY / 300).clamp(0.0, 1.0);
    if (_isDismissing) {
      return dragOpacity * (1.0 - _dismissCurve.value);
    }
    return dragOpacity;
  }

  double get _effectiveChromeOpacity {
    final dragOpacity = 1.0 - (_dragOffsetY / 30).clamp(0.0, 1.0);
    if (_isDismissing) {
      return dragOpacity * (1.0 - _dismissCurve.value);
    }
    return dragOpacity;
  }

  double get _effectiveDragOffsetY {
    if (_isDismissing) {
      return _dragOffsetY + (36.0 * _dismissCurve.value);
    }
    return _dragOffsetY;
  }

  double get _effectiveScaleFraction {
    final baseScale = (1.0 - _effectiveDragOffsetY / 1200).clamp(0.85, 1.0);
    if (_isDismissing) {
      return baseScale * (1.0 - 0.05 * _dismissCurve.value);
    }
    return baseScale;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hideSystemUI();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformControllers = {};
    _focusNode = FocusNode()..requestFocus();
    _showChromeNotifier = ValueNotifier<bool>(true);

    _resetController = AnimationController(
      vsync: this,
      duration: AppDuration.medium2,
    )..addListener(_handleResetAnimation);

    _resetCurve = CurvedAnimation(
      parent: _resetController,
      curve: AppEasing.emphasizedDecelerate,
    );

    _dismissController =
        AnimationController(vsync: this, duration: AppDuration.short3)
          ..addListener(_handleDismissAnimation)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              _restoreSystemUI();
              Navigator.of(context).pop();
            }
          });

    _dismissCurve = CurvedAnimation(
      parent: _dismissController,
      curve: AppEasing.emphasizedAccelerate,
    );

    // Umumkan halaman pertama kepada screen reader
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announcePage(_currentIndex);
    });
  }

  void _handleResetAnimation() {
    if (_resetAnimation != null) {
      setState(() {
        _dragOffsetY = _resetAnimation!.value;
      });
    }
  }

  void _handleDismissAnimation() {
    setState(() {});
  }

  void _handleProgrammaticDismiss() {
    if (_isDismissing) return;
    if (!mounted) return;

    if (AppMotion.isReducedMotion(context) || _dragOffsetY > 80) {
      _restoreSystemUI();
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isDismissing = true;
    });
    _dismissController.forward();
  }

  void _hideSystemUI() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  void _restoreSystemUI() {
    if (_hasRestoredSystemUi) return;
    _hasRestoredSystemUi = true;
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hasRestoredSystemUi = false;
      _hideSystemUI();
    }
  }

  @override
  void dispose() {
    _restoreSystemUI();
    WidgetsBinding.instance.removeObserver(this);
    _dismissCurve.dispose();
    _dismissController.dispose();
    _singleTapTimer?.cancel();
    _showChromeNotifier.dispose();
    _focusNode.dispose();
    _resetCurve.dispose();
    _resetController.dispose();
    _pageController.dispose();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    if (_activePointerIds.length >= 2) {
      final wasDragging = _isDragging;
      _isDragging = false;
      _dragOffsetY = 0;
      if (!_isMultiTouch || wasDragging) {
        setState(() {
          _isMultiTouch = true;
        });
      }
    }
  }

  void _handlePointerRemove(int pointerId) {
    _activePointerIds.remove(pointerId);
    if (_activePointerIds.length < 2 && _isMultiTouch) {
      setState(() {
        _isMultiTouch = false;
      });
    }
  }

  TransformationController _getTransformController(int index) {
    return _transformControllers.putIfAbsent(
      index,
      TransformationController.new,
    );
  }

  bool _isZoomed(int index) {
    final controller = _transformControllers[index];
    if (controller == null) return false;
    return controller.value.getMaxScaleOnAxis() > 1.05;
  }

  void _syncZoomState(int index) {
    if (index != _currentIndex) return;
    final isZoomedNow = _isZoomed(index);
    if (isZoomedNow != _isCurrentPageZoomed) {
      setState(() {
        _isCurrentPageZoomed = isZoomedNow;
      });
    }
  }

  void _handleImageTap(int index, Offset position, Size viewportSize) {
    _tapCount++;
    if (_tapCount == 1) {
      _lastTapPosition = position;
      _singleTapTimer = Timer(const Duration(milliseconds: 200), () {
        _tapCount = 0;
        _toggleChrome();
        _singleTapTimer = null;
      });
    } else {
      final isNear =
          _lastTapPosition != null &&
          (position - _lastTapPosition!).distance < 40;
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
      _tapCount = 0;
      if (isNear) {
        _handleDoubleTap(index, position, viewportSize);
      } else {
        _toggleChrome();
      }
    }
  }

  void _handleDoubleTap(int index, Offset position, Size viewportSize) {
    final controller = _getTransformController(index);
    if (_isZoomed(index)) {
      controller.value = Matrix4.identity();
    } else {
      final tx = -position.dx * 1.5;
      final ty = -position.dy * 1.5;
      final matrix = Matrix4.identity()
        ..translateByDouble(tx, ty, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
      controller.value = clampImageViewerMatrix(
        matrix,
        _imageSizes[index],
        viewportSize,
      );
    }
    _syncZoomState(index);
  }

  void _handleInteractionUpdate(int index, Size viewportSize) {
    final controller = _getTransformController(index);
    final clamped = clampImageViewerMatrix(
      controller.value,
      _imageSizes[index],
      viewportSize,
    );
    if (controller.value != clamped) {
      controller.value = clamped;
    }
    _syncZoomState(index);
  }

  void _handleInteractionEnd(int index, Size viewportSize) {
    final controller = _getTransformController(index);
    final clamped = clampImageViewerMatrix(
      controller.value,
      _imageSizes[index],
      viewportSize,
    );
    controller.value = clamped;
    _syncZoomState(index);
  }

  void _toggleChrome() {
    _showChromeNotifier.value = !_showChromeNotifier.value;
  }

  void _announcePage(int index) {
    if (!mounted) return;
    final total = widget.imageUrls.length;
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Foto ${index + 1} dari $total',
      TextDirection.ltr,
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isPagingDisabled) return;
    _isDragging = true;
    _resetController.stop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isPagingDisabled) return;
    final newOffset = _dragOffsetY + details.delta.dy;
    // Hanya izinkan tarikan vertikal ke bawah (>= 0)
    setState(() {
      _dragOffsetY = math.max(0, newOffset);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    // Ambang batas dismiss: tarikan > 80dp atau fling cepat ke bawah (> 400px/s)
    if (_dragOffsetY > 80 || (velocity > 400 && _dragOffsetY > 20)) {
      _restoreSystemUI();
      Navigator.of(context).pop();
    } else if (_dragOffsetY > 0) {
      _startResetAnimation();
    }
  }

  void _onVerticalDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    if (_dragOffsetY > 0) {
      _startResetAnimation();
    }
  }

  void _startResetAnimation() {
    _resetAnimation = Tween<double>(
      begin: _dragOffsetY,
      end: 0,
    ).animate(_resetCurve);
    _resetController
      ..reset()
      ..forward();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_isDismissing) return;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _handleProgrammaticDismiss();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_currentIndex > 0) {
          _pageController.previousPage(
            duration: AppDuration.short4,
            curve: AppMotion.standard,
          );
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_currentIndex < widget.imageUrls.length - 1) {
          _pageController.nextPage(
            duration: AppDuration.short4,
            curve: AppMotion.standard,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final totalImages = widget.imageUrls.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lightOverlayStyle,
      child: PopScope(
        canPop: _isDismissing || _dragOffsetY > 80,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleProgrammaticDismiss();
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final viewportSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── 1. Backdrop Scrim Dinamis ───────────────────────────
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _toggleChrome,
                        child: ColoredBox(
                          color: colorScheme.scrim.withValues(
                            alpha: 0.96 * _effectiveBackdropOpacity,
                          ),
                        ),
                      ),
                    ),

                    // ── 2. Kanvas Gambar Utama (PageView + InteractiveViewer) ──
                    Positioned.fill(
                      child: Listener(
                        onPointerDown: _handlePointerDown,
                        onPointerUp: (e) => _handlePointerRemove(e.pointer),
                        onPointerCancel: (e) => _handlePointerRemove(e.pointer),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: _isPagingDisabled
                              ? null
                              : _onVerticalDragStart,
                          onVerticalDragUpdate: _isPagingDisabled
                              ? null
                              : _onVerticalDragUpdate,
                          onVerticalDragEnd: _isPagingDisabled
                              ? null
                              : _onVerticalDragEnd,
                          onVerticalDragCancel: _isPagingDisabled
                              ? null
                              : _onVerticalDragCancel,
                          child: Transform.translate(
                            offset: Offset(0, _effectiveDragOffsetY),
                            child: Transform.scale(
                              scale: _effectiveScaleFraction,
                              child: PageView.builder(
                                controller: _pageController,
                                physics: _isPagingDisabled
                                    ? const NeverScrollableScrollPhysics()
                                    : const BouncingScrollPhysics(),
                                itemCount: totalImages,
                                onPageChanged: (index) {
                                  final prevController =
                                      _transformControllers[_currentIndex];
                                  if (prevController != null &&
                                      prevController.value !=
                                          Matrix4.identity()) {
                                    prevController.value = Matrix4.identity();
                                  }
                                  setState(() {
                                    _currentIndex = index;
                                    _isCurrentPageZoomed = _isZoomed(index);
                                  });
                                  _announcePage(index);
                                },
                                itemBuilder: (context, index) =>
                                    _buildImageItem(
                                      context,
                                      index,
                                      viewportSize,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── 3. Chrome Atas (Floating Counter & Close Button) ────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ImageViewerTopChrome(
                        opacity: _effectiveChromeOpacity,
                        showChrome: _showChromeNotifier,
                        isDragging: _dragOffsetY > 0,
                        currentIndex: _currentIndex,
                        total: totalImages,
                        onClose: _handleProgrammaticDismiss,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, int index, Size viewportSize) {
    final imageUrl = widget.imageUrls[index];
    final heroTag = widget.heroTagPrefix != null
        ? '${widget.heroTagPrefix}_$index'
        : 'app_image_viewer_${imageUrl}_$index';

    final controller = _getTransformController(index);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) =>
          _handleImageTap(index, details.localPosition, viewportSize),
      child: InteractiveViewer(
        transformationController: controller,
        minScale: 1,
        maxScale: 4,
        clipBehavior: Clip.none,
        panEnabled: _isZoomed(index) || _isMultiTouch,
        onInteractionStart: (details) {
          _resetController.stop();
        },
        onInteractionUpdate: (details) =>
            _handleInteractionUpdate(index, viewportSize),
        onInteractionEnd: (details) =>
            _handleInteractionEnd(index, viewportSize),
        child: SizedBox.expand(
          child: ColoredBox(
            color: Colors.transparent,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: ImageViewerImageContent(
                  imageUrl: imageUrl,
                  onImageResolved: (provider) =>
                      _registerImageSize(index, provider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _registerImageSize(int index, ImageProvider imageProvider) {
    if (_imageSizes.containsKey(index)) return;
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (mounted) {
        _imageSizes[index] = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      }
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }
}
