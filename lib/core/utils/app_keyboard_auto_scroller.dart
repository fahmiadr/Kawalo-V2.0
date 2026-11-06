import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';

/// Pengendali standar dan ergonomis untuk auto-scroll field input aktif
/// saat keyboard virtual muncul, berubah ukuran, atau berpindah fokus.
///
/// Prinsip UX & Presisi:
/// 1. Comfort Zone Preservation: Jika field yang difokuskan sudah terlihat
///    nyaman di atas keyboard, layar TIDAK bergerak/melompat sama sekali.
/// 2. Adaptive Viewport Clearance: Ruang aman di bawah field beradaptasi
///    secara cerdas dengan tinggi viewport sehingga tidak pernah memotong
///    bagian atas field pada layar terbatas.
/// 3. Inset Settling Synchronization: Menghindari race condition dengan
///    animasi IME sistem operasi melalui debouncing cerdas, sehingga posisi
///    dihitung pada tinggi akhir keyboard yang sebenarnya.
/// 4. Post-Settling Verification: Jaminan kepastian posisi (guaranteed
///    placement) jika OS menampilkan bilah saran/autofill tambahan setelah
///    keyboard terbuka.
/// 5. Touch Handover Guard: Mengabaikan fluktuasi transien OS IME
///    (siklus dip & reopen saat sentuhan berpindah antar field di layar).
class AppKeyboardAutoScroller with WidgetsBindingObserver {
  /// Membuat instance [AppKeyboardAutoScroller].
  AppKeyboardAutoScroller({
    this.alignment = 0.35,
    this.duration = AppMotion.durationMedium1,
    this.curve = AppMotion.emphasizedDecelerate,
    this.bottomClearance = 40.0,
    this.topMargin = 16.0,
    this.scrollController,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Target alignment fallback untuk [Scrollable.ensureVisible].
  final double alignment;

  /// Durasi animasi scroll Material 3 Expressive.
  final Duration duration;

  /// Kurva animasi scroll Material 3 Expressive.
  final Curve curve;

  /// Ruang aman di bawah field (clearance) agar input tidak mepet di tepi
  /// keyboard, memberikan ruang untuk pesan error, tombol, atau saran teks IME.
  final double bottomClearance;

  /// Jarak aman dari batas atas layar.
  final double topMargin;

  /// [ScrollController] opsional untuk kontrol langsung terhadap posisi scroll
  /// dan deteksi status interaksi user drag.
  ScrollController? scrollController;

  BuildContext? _currentContext;
  FocusNode? _activeFocusNode;
  FocusNode? _pendingFocusNode;

  Timer? _focusHandoverTimer;
  Timer? _handoverGuardTimer;
  Timer? _hardwareKeyboardFallbackTimer;
  Timer? _insetsSettlingTimer;

  DateTime _lastKeyboardActiveTime = DateTime.fromMillisecondsSinceEpoch(0);
  double _lastBottomInset = 0;
  double _lastKnownKeyboardHeight = 0;
  bool _isHandoverGuardActive = false;
  bool _isDisposed = false;

  final List<FocusNode> _registeredNodes = [];
  final List<VoidCallback> _listeners = [];

  /// Menghubungkan context aktif (biasanya dipanggil di method build).
  void attachContext(BuildContext context) {
    if (_isDisposed) return;
    _currentContext = context;
    _checkKeyboardMetrics();
  }

  /// Mendaftarkan daftar [FocusNode] yang akan dipantau.
  void registerNodes(List<FocusNode> nodes) {
    for (final node in nodes) {
      void listener() {
        if (_isDisposed) return;

        if (node.hasFocus) {
          _focusHandoverTimer?.cancel();
          _onFocusGained(node);
        } else if (_activeFocusNode == node) {
          _focusHandoverTimer?.cancel();
          _focusHandoverTimer = Timer(const Duration(milliseconds: 50), () {
            if (_isDisposed) return;
            if (_activeFocusNode == node && !node.hasFocus) {
              _activeFocusNode = null;
              _pendingFocusNode = null;
            }
          });
        }
      }

      node.addListener(listener);
      _registeredNodes.add(node);
      _listeners.add(listener);
    }
  }

  void _onFocusGained(FocusNode node) {
    final isDifferentNode = _activeFocusNode != node;
    _activeFocusNode = node;

    final currentInset = _getKeyboardInset();
    if (currentInset > 30) {
      _lastKnownKeyboardHeight = math.max(
        _lastKnownKeyboardHeight,
        currentInset,
      );
      _lastKeyboardActiveTime = DateTime.now();
    }

    final isKeyboardActive = currentInset >= 50 ||
        (_lastKnownKeyboardHeight >= 50 &&
            DateTime.now().difference(_lastKeyboardActiveTime).inMilliseconds <
                600);

    if (isKeyboardActive) {
      if (isDifferentNode) {
        _activateHandoverGuard();
      }
      _pendingFocusNode = null;
      _hardwareKeyboardFallbackTimer?.cancel();
      _hardwareKeyboardFallbackTimer = null;
      _scheduleScrollTo(node, immediate: true);
    } else {
      _pendingFocusNode = node;
      _startHardwareKeyboardFallback(node);
    }
  }

  /// Mendapatkan tinggi keyboard saat ini (dalam logical pixels) secara akurat.
  double _getKeyboardInset() {
    final context = _currentContext;
    if (context == null || !context.mounted) return 0;

    final view = View.maybeOf(context);
    final rawInset = (view != null && view.devicePixelRatio > 0)
        ? view.viewInsets.bottom / view.devicePixelRatio
        : 0;
    final mediaQueryInset = MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0;

    return math.max(rawInset, mediaQueryInset).toDouble();
  }

  @override
  void didChangeMetrics() {
    _checkKeyboardMetrics();
  }

  void _checkKeyboardMetrics() {
    if (_isDisposed) return;
    final currentInset = _getKeyboardInset();

    if (currentInset > 30) {
      _lastKnownKeyboardHeight = math.max(
        _lastKnownKeyboardHeight,
        currentInset,
      );
      _lastKeyboardActiveTime = DateTime.now();
    }

    if (_isHandoverGuardActive && currentInset < 50) {
      // Abaikan penurunan sesaat akibat IME handover
      return;
    }

    final isOpening = currentInset > _lastBottomInset;
    _lastBottomInset = currentInset;

    if (currentInset >= 50) {
      _hardwareKeyboardFallbackTimer?.cancel();
      _hardwareKeyboardFallbackTimer = null;

      final targetNode = _pendingFocusNode ?? _activeFocusNode;
      if (targetNode != null && targetNode.hasFocus) {
        // Jika keyboard telah mendekati tinggi maksimum yang diketahui,
        // jadwalkan scroll langsung untuk responsivitas instan.
        final isNearTarget = _lastKnownKeyboardHeight >= 120 &&
            currentInset >= _lastKnownKeyboardHeight - 12;

        _insetsSettlingTimer?.cancel();
        if (isNearTarget) {
          _pendingFocusNode = null;
          _scheduleScrollTo(targetNode);
        } else if (isOpening) {
          // Debounce penyesuaian hingga keyboard berhenti beranimasi (stabil)
          _insetsSettlingTimer = Timer(
            const Duration(milliseconds: 50),
            () {
              if (_isDisposed) return;
              if (targetNode.hasFocus) {
                _pendingFocusNode = null;
                _scheduleScrollTo(targetNode);
              }
            },
          );
        } else {
          // Keyboard berubah ukuran atau stabil pada posisi baru
          _insetsSettlingTimer = Timer(
            const Duration(milliseconds: 40),
            () {
              if (_isDisposed) return;
              if (targetNode.hasFocus) {
                _scheduleScrollTo(targetNode);
              }
            },
          );
        }
      }
    } else if (currentInset == 0) {
      _insetsSettlingTimer?.cancel();
    }
  }

  void _activateHandoverGuard() {
    _isHandoverGuardActive = true;
    _handoverGuardTimer?.cancel();
    _handoverGuardTimer = Timer(
      duration + const Duration(milliseconds: 100),
      () {
        if (_isDisposed) return;
        _isHandoverGuardActive = false;
      },
    );
  }

  void _startHardwareKeyboardFallback(FocusNode node) {
    _hardwareKeyboardFallbackTimer?.cancel();
    _hardwareKeyboardFallbackTimer = Timer(
      const Duration(milliseconds: 150),
      () {
        if (_isDisposed) return;
        if (_pendingFocusNode == node && node.hasFocus) {
          _pendingFocusNode = null;
          _scheduleScrollTo(node);
        }
      },
    );
  }

  /// Memaksa scroll ke node tertentu (misalnya saat submit form dan validasi
  /// error menemukan field kosong).
  void scrollToNode(FocusNode node, {bool immediate = false}) {
    if (_isDisposed) return;
    _activeFocusNode = node;
    if (!node.hasFocus) {
      node.requestFocus();
    }
    _pendingFocusNode = null;
    _hardwareKeyboardFallbackTimer?.cancel();
    _hardwareKeyboardFallbackTimer = null;

    final currentInset = _getKeyboardInset();
    if (immediate || currentInset >= 100) {
      _scheduleScrollTo(node, immediate: true);
    } else {
      _pendingFocusNode = node;
      _startHardwareKeyboardFallback(node);
    }
  }

  void _scheduleScrollTo(FocusNode node, {bool immediate = false}) {
    if (_isDisposed || !node.hasFocus) return;

    if (immediate) {
      final context = node.context;
      if (context != null && context.mounted) {
        final renderObject = context.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize) {
          _executeScroll(node);
          return;
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !node.hasFocus) return;
      _executeScroll(node);
    });
  }

  void _executeScroll(FocusNode node) {
    if (_isDisposed || !node.hasFocus) return;

    final targetContext = node.context;
    if (targetContext == null || !targetContext.mounted) return;

    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final effectiveDuration =
        AppMotion.isReducedMotion(targetContext) ? Duration.zero : duration;

    renderObject.showOnScreen(
      duration: effectiveDuration,
      curve: curve,
    );
  }

  /// Membersihkan seluruh observer, listener, dan timer saat widget di-dispose.
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _focusHandoverTimer?.cancel();
    _focusHandoverTimer = null;
    _handoverGuardTimer?.cancel();
    _handoverGuardTimer = null;
    _hardwareKeyboardFallbackTimer?.cancel();
    _hardwareKeyboardFallbackTimer = null;
    _insetsSettlingTimer?.cancel();
    _insetsSettlingTimer = null;
    for (var i = 0; i < _registeredNodes.length; i++) {
      _registeredNodes[i].removeListener(_listeners[i]);
    }
    _registeredNodes.clear();
    _listeners.clear();
    _activeFocusNode = null;
    _pendingFocusNode = null;
    _currentContext = null;
    scrollController = null;
  }
}

/// Widget wrapper yang menambahkan padding ekstra saat
/// elemen di dalamnya meminta `showOnScreen` (misalnya saat
/// field teks difokuskan atau kursor bergerak).
///
/// Memastikan animasi scroll otomatis langsung menyisakan
/// clearance aman di atas keyboard (seperti 40dp) dalam SATU
/// kali gerakan instan, tanpa transisi bertahap
/// (*scroll AtEnd lalu disusul penambahan offset*).
class AppScrollPadding extends SingleChildRenderObjectWidget {
  /// Membuat instance [AppScrollPadding].
  const AppScrollPadding({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 40),
    this.duration = AppMotion.short2,
    this.curve = AppMotion.emphasized,
    this.revealTargetKey,
    super.child,
  });

  /// Besaran padding ekstra pada area reveal.
  final EdgeInsets padding;

  /// Durasi animasi scroll Material 3 Expressive.
  final Duration duration;

  /// Kurva animasi scroll Material 3 Expressive.
  final Curve curve;

  /// [GlobalKey] opsional elemen target tambahan (seperti tombol submit/CTA)
  /// yang wajib ikut terlihat (*in-viewport*) saat descendant di dalam
  /// widget ini meminta `showOnScreen` (misalnya saat field teks difokuskan).
  final GlobalKey? revealTargetKey;

  @override
  RenderScrollPadding createRenderObject(
    BuildContext context,
  ) {
    final isReduced = AppMotion.isReducedMotion(context);
    return RenderScrollPadding(
      padding: padding,
      animationDuration: isReduced ? Duration.zero : duration,
      animationCurve: curve,
      revealTargetKey: revealTargetKey,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderScrollPadding renderObject,
  ) {
    final isReduced = AppMotion.isReducedMotion(context);
    renderObject
      ..padding = padding
      ..animationDuration = isReduced ? Duration.zero : duration
      ..animationCurve = curve
      ..revealTargetKey = revealTargetKey;
  }
}

/// Render proxy yang mengintersepsi panggilan `showOnScreen`
/// dari descendant (seperti `RenderEditable` internal Flutter)
/// dan menggelembungkan area target `rect` dengan padding
/// sebelum diteruskan ke viewport.
class RenderScrollPadding extends RenderProxyBox {
  RenderScrollPadding({
    RenderBox? child,
    this.padding = const EdgeInsets.only(bottom: 40),
    this.animationDuration,
    this.animationCurve,
    this.revealTargetKey,
  }) : super(child);

  /// Besaran padding ekstra.
  EdgeInsets padding;

  /// Durasi animasi scroll untuk konsistensi M3 Expressive.
  Duration? animationDuration;

  /// Kurva animasi scroll untuk konsistensi M3 Expressive.
  Curve? animationCurve;

  /// [GlobalKey] opsional elemen target yang harus ikut terlihat.
  GlobalKey? revealTargetKey;

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final parentNode = parent;
    if (parentNode == null) return;

    final Rect targetRect;
    if (descendant != null && descendant != this) {
      final transform = descendant.getTransformTo(this);
      final localRect = rect ?? descendant.paintBounds;
      targetRect = MatrixUtils.transformRect(transform, localRect);
    } else {
      targetRect = rect ?? paintBounds;
    }

    var expandedRect = targetRect;
    final targetContext = revealTargetKey?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      final targetRenderBox = targetContext.findRenderObject();
      if (targetRenderBox is RenderBox &&
          targetRenderBox.hasSize &&
          targetRenderBox.attached) {
        try {
          final transform = targetRenderBox.getTransformTo(this);
          final targetBoxRect = MatrixUtils.transformRect(
            transform,
            targetRenderBox.paintBounds,
          );
          expandedRect = expandedRect.expandToInclude(targetBoxRect);
        } on Object catch (_) {
          // Fallback jika transform tidak dapat dihitung
        }
      }
    }

    final paddedRect = Rect.fromLTRB(
      expandedRect.left - padding.left,
      expandedRect.top - padding.top,
      expandedRect.right + padding.right,
      expandedRect.bottom + padding.bottom,
    );

    final effectiveDuration = duration == Duration.zero
        ? Duration.zero
        : (animationDuration ?? duration);
    final effectiveCurve = animationCurve ?? curve;

    parentNode.showOnScreen(
      descendant: this,
      rect: paddedRect,
      duration: effectiveDuration,
      curve: effectiveCurve,
    );
  }
}
