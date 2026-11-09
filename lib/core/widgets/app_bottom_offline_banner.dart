import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Status visual internal banner offline.
enum _BannerMode {
  /// Banner tidak ditampilkan (tinggi 0 / kolaps).
  hidden,

  /// Mode offline aktif (warna errorContainer).
  offline,

  /// Transisi saat koneksi pulih kembali ke online (warna primaryContainer).
  onlineRestored,
}

/// Widget indikator status offline dengan animasi masuk dan keluar sesuai
/// Material 3 Expressive Motion.
///
/// Komponen ini murni bersifat presentasional (pure UI component). Status
/// konektivitas dikontrol secara deterministik melalui parameter [isOffline].
///
/// Mendukung transisi warna dan pesan dari kondisi offline ([message])
/// ke online ([onlineMessage]) dengan jeda keterbacaan ([onlineDwellDuration])
/// sebelum beranimasi keluar layar secara halus.
class AppBottomOfflineBanner extends StatefulWidget {
  /// Membuat instance [AppBottomOfflineBanner].
  const AppBottomOfflineBanner({
    super.key,
    this.message = 'Mode offline — Menampilkan data tersimpan',
    this.onlineMessage = 'Kembali online',
    this.isOffline = true,
    this.useSafeArea = true,
    this.keepSafeAreaWhenHidden = false,
    this.safeAreaColor,
    this.onlineDwellDuration = const Duration(milliseconds: 2500),
  });

  /// Pesan yang ditampilkan saat perangkat sedang offline.
  final String message;

  /// Pesan konfirmasi pemulihan saat konektivitas kembali online.
  final String onlineMessage;

  /// Status apakah perangkat sedang dalam kondisi offline.
  ///
  /// Standar default adalah `true` agar komponen dapat langsung digunakan
  /// sebagai banner offline statis atau dikontrol secara dinamis oleh parent.
  final bool isOffline;

  /// Apakah membungkus konten dengan [SafeArea] bawah (default true).
  ///
  /// Setel ke `false` jika banner ditempatkan di dalam kontainer yang telah
  /// menangani padding SafeArea (misal: di shell scaffold navigasi utama).
  final bool useSafeArea;

  /// Menjaga area safe area bawah tetap ada saat banner tersembunyi
  /// dengan warna latar belakang yang menyatu dengan bilah navigasi.
  /// Mencegah terjadinya lompatan tinggi saat diletakkan di bawah
  /// bilah navigasi bawah (Navigation Bar).
  final bool keepSafeAreaWhenHidden;

  /// Warna latar belakang untuk safe area spacer saat banner tersembunyi.
  ///
  /// Jika bernilai `null`, default menggunakan
  /// [ColorScheme.surfaceContainerHigh] agar selaras dengan warna default
  /// bilah navigasi bawah.
  final Color? safeAreaColor;

  /// Jeda durasi tampilan pesan [onlineMessage] sebelum banner meluncur keluar.
  final Duration onlineDwellDuration;

  @override
  State<AppBottomOfflineBanner> createState() => _AppBottomOfflineBannerState();
}

class _AppBottomOfflineBannerState extends State<AppBottomOfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _dwellTimer;
  late _BannerMode _mode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.medium4,
      reverseDuration: AppDuration.short4,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppEasing.emphasizedDecelerate,
      reverseCurve: AppEasing.emphasizedAccelerate,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppEasing.standard,
      reverseCurve: AppEasing.standardAccelerate,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {
          _mode = _BannerMode.hidden;
        });
      }
    });

    if (widget.isOffline) {
      _mode = _BannerMode.offline;
      _controller.value = 1.0;
    } else {
      _mode = _BannerMode.hidden;
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(AppBottomOfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOffline != oldWidget.isOffline) {
      _handleConnectivityChange(widget.isOffline);
    }
  }

  void _handleConnectivityChange(bool isOffline) {
    _dwellTimer?.cancel();
    _dwellTimer = null;

    final isReducedMotion = AppMotion.isReducedMotion(context);

    if (isOffline) {
      setState(() {
        _mode = _BannerMode.offline;
      });

      if (isReducedMotion) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    } else {
      // Hanya tampilkan transisi "Kembali online" jika sebelumnya sedang
      // offline.
      if (_mode == _BannerMode.offline) {
        setState(() {
          _mode = _BannerMode.onlineRestored;
        });

        _dwellTimer = Timer(widget.onlineDwellDuration, () {
          if (!mounted) return;
          if (_mode == _BannerMode.onlineRestored) {
            if (isReducedMotion) {
              _controller.value = 0.0;
              setState(() {
                _mode = _BannerMode.hidden;
              });
            } else {
              _controller.reverse();
            }
          }
        });
      } else if (_mode == _BannerMode.hidden) {
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final double physicalBottom;
    final viewPadding = mediaQuery?.viewPadding.bottom ?? 0.0;
    final padding = mediaQuery?.padding.bottom ?? 0.0;
    if (viewPadding > 0) {
      physicalBottom = viewPadding;
    } else if (padding > 0) {
      physicalBottom = padding;
    } else {
      final view = View.maybeOf(context);
      if (view != null) {
        final raw = MediaQueryData.fromView(view);
        physicalBottom = raw.viewPadding.bottom;
      } else {
        physicalBottom = 0.0;
      }
    }
    final bottomInset = widget.useSafeArea ? physicalBottom : 0.0;

    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveSafeAreaColor =
        widget.safeAreaColor ?? colorScheme.surfaceContainerHigh;

    if (_mode == _BannerMode.hidden && _controller.value == 0.0) {
      if (widget.keepSafeAreaWhenHidden && bottomInset > 0) {
        return SizedBox(
          width: double.infinity,
          height: bottomInset,
          child: ColoredBox(color: effectiveSafeAreaColor),
        );
      }
      return const SizedBox.shrink();
    }

    final emphasizedScale = theme.typography.emphasized;
    final isReducedMotion = AppMotion.isReducedMotion(context);

    final isOfflineState = _mode == _BannerMode.offline;

    final backgroundColor = isOfflineState
        ? colorScheme.errorContainer.withValues(alpha: 0.95)
        : (_mode == _BannerMode.onlineRestored
              ? colorScheme.primaryContainer.withValues(alpha: 0.95)
              : effectiveSafeAreaColor);

    final foregroundColor = isOfflineState
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    final text = isOfflineState ? widget.message : widget.onlineMessage;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space50,
          ),
          child: AnimatedSwitcher(
            duration: isReducedMotion ? Duration.zero : AppDuration.medium1,
            switchInCurve: AppEasing.emphasizedDecelerate,
            switchOutCurve: AppEasing.emphasizedAccelerate,
            child: Align(
              heightFactor: 1,
              key: ValueKey<bool>(isOfflineState),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: emphasizedScale.labelMedium.copyWith(
                  color: foregroundColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.keepSafeAreaWhenHidden) {
      return AnimatedContainer(
        duration: isReducedMotion ? Duration.zero : AppDuration.medium1,
        curve: AppEasing.standard,
        width: double.infinity,
        color: backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: SizeTransition(
                sizeFactor: _sizeAnimation,
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Semantics(liveRegion: true, child: content),
                ),
              ),
            ),
            if (bottomInset > 0) SizedBox(height: bottomInset),
          ],
        ),
      );
    }

    return ClipRect(
      child: SizeTransition(
        sizeFactor: _sizeAnimation,
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Semantics(
            liveRegion: true,
            child: AnimatedContainer(
              duration: isReducedMotion ? Duration.zero : AppDuration.medium1,
              curve: AppEasing.standard,
              width: double.infinity,
              color: backgroundColor,
              child: widget.useSafeArea
                  ? SafeArea(
                      top: false,
                      maintainBottomViewPadding: true,
                      child: content,
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}
