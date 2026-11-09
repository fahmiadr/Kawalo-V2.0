import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:kawalo_mobile/features/splash/presentation/widgets/background_glow_widget.dart';
import 'package:kawalo_mobile/features/splash/presentation/widgets/brand_logo_widget.dart';
import 'package:kawalo_mobile/features/splash/presentation/widgets/subtitle_widget.dart';

/// Screen utama Splash yang ditampilkan saat aplikasi pertama kali dimuat.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 3000),
    this.slowLoadingThreshold = const Duration(milliseconds: 2000),
    this.onInitialize,
    this.onInitializationComplete,
    this.storageService,
    this.enableOnboardingPersistence,
  });

  /// Durasi minimum tampilan splash screen (default: 3000ms).
  final Duration minDuration;

  /// Ambang batas waktu sebelum loading indicator dimunculkan
  /// (default: 2000ms).
  final Duration slowLoadingThreshold;

  /// Fungsi async inisialisasi awal (misal: auth check, database load).
  final Future<void> Function()? onInitialize;

  /// Callback opsional yang dipanggil saat launching splash selesai.
  final VoidCallback? onInitializationComplete;

  /// Service penyimpanan aman untuk memeriksa status onboarding.
  final SecureStorageService? storageService;

  /// Toggle konfigurasi apakah persistensi onboarding diaktifkan.
  /// Bila bernilai false (misal saat review/debug), OnboardingScreen akan
  /// selalu dimunculkan.
  final bool? enableOnboardingPersistence;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _brandOpacityAnimation;
  late final Animation<double> _subtitleOpacityAnimation;
  late final Animation<Color?> _glowColorAnimation;

  Timer? _slowLoadingTimer;
  Timer? _splashMinDurationTimer;
  bool _showSlowLoadingIndicator = false;
  bool _isMinDurationElapsed = false;
  bool _hasNavigated = false;
  late final SplashCubit _splashCubit;

  @override
  void initState() {
    super.initState();

    _splashCubit = SplashCubit(
      storage: widget.storageService ?? context.read<SecureStorageService?>(),
      authBloc: context.read<AuthBloc?>(),
      onInitialize: widget.onInitialize,
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Keyframe 0ms -> 2000ms, Opacity 0% -> 100% (0 -> 1)
    _brandOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0,
        2000 / 3000,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    // Keyframe 300ms -> 2000ms, Opacity 0% -> 100% (0 -> 1)
    _subtitleOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        300 / 3000,
        2000 / 3000,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    // Keyframe 300ms -> 3000ms, Warna light inversePrimary Opacity 0% -> 32%
    final glowBaseColor = AppTheme.lightThemeData().colorScheme.inversePrimary;
    _glowColorAnimation =
        ColorTween(
          begin: glowBaseColor.withValues(alpha: 0),
          end: glowBaseColor.withValues(alpha: 0.32),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(
              300 / 3000,
              1,
              curve: AppMotion.emphasizedDecelerate,
            ),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AppMotion.isReducedMotion(context)) {
        _controller.forward();
      }

      _slowLoadingTimer = Timer(widget.slowLoadingThreshold, () {
        if (mounted && !_hasNavigated) {
          setState(() {
            _showSlowLoadingIndicator = true;
          });
        }
      });

      _splashMinDurationTimer = Timer(widget.minDuration, () {
        _isMinDurationElapsed = true;
        _checkAndNavigate();
      });

      unawaited(_splashCubit.initialize());
    });
  }

  void _checkAndNavigate() {
    if (_isMinDurationElapsed &&
        _splashCubit.state.isReady &&
        mounted &&
        !_hasNavigated) {
      _hasNavigated = true;
      _slowLoadingTimer?.cancel();
      _splashMinDurationTimer?.cancel();
      widget.onInitializationComplete?.call();

      var persistenceEnabled = true;
      try {
        persistenceEnabled =
            widget.enableOnboardingPersistence ??
            EnvConfig.enableOnboardingPersistence;
      } on Object catch (_) {
        persistenceEnabled = widget.enableOnboardingPersistence ?? true;
      }

      final splash = _splashCubit.state;
      final user = splash.user;
      final router = AppRouter.of(context);
      if (!persistenceEnabled || !splash.isOnboardingCompleted) {
        unawaited(router.toOnboarding());
      } else if (splash.isGroupSelectionRequired && user != null) {
        unawaited(router.toGroupSelection(user));
      } else if (splash.isAuthenticated) {
        unawaited(router.toMain());
      } else {
        unawaited(router.toLogin());
      }
    }
  }

  @override
  void dispose() {
    _slowLoadingTimer?.cancel();
    _splashMinDurationTimer?.cancel();
    unawaited(_splashCubit.close());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppLayout.horizontalMargin(screenWidth);
    final isReducedMotion = AppMotion.isReducedMotion(context);
    final m3eTheme = AppTheme.m3eLight();
    final lightTheme = AppTheme.lightThemeData();

    final brandChild = isReducedMotion
        ? const BrandLogoWidget()
        : FadeTransition(
            opacity: _brandOpacityAnimation,
            child: const BrandLogoWidget(),
          );

    final subtitleChild = isReducedMotion
        ? const SubtitleWidget()
        : FadeTransition(
            opacity: _subtitleOpacityAnimation,
            child: const SubtitleWidget(),
          );

    final loadingIndicatorChild = AnimatedOpacity(
      duration: isReducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: AppMotion.emphasizedDecelerate,
      opacity: _showSlowLoadingIndicator ? 1.0 : 0.0,
      child: AppLoadingIndicator(
        color: lightTheme.colorScheme.primary,
        semanticLabel: 'Memuat aplikasi...',
      ),
    );

    return BlocListener<SplashCubit, SplashState>(
      bloc: _splashCubit,
      listenWhen: (_, current) => current.isReady,
      listener: (_, _) => _checkAndNavigate(),
      child: M3ETheme(
        data: m3eTheme,
        child: Theme(
          data: lightTheme,
          child: Scaffold(
            backgroundColor: lightTheme.colorScheme.surface,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.space300,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.contentMaxWidth,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Glow
                        // Layer Blur 170, Warna Opacity 0% -> 32%
                        if (isReducedMotion)
                          const BackgroundGlowWidget()
                        else
                          AnimatedBuilder(
                            animation: _glowColorAnimation,
                            builder: (context, child) {
                              return BackgroundGlowWidget(
                                color: _glowColorAnimation.value,
                              );
                            },
                          ),

                        // Foreground Content Column
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Brand Logo
                            brandChild,

                            AppSpacing.vGap200,

                            // Subtitle
                            subtitleChild,

                            AppSpacing.vGap400,

                            // Indikator visual loading resmi dengan slot tinggi
                            // stabil
                            SizedBox(
                              height: AppSpacing.space600,
                              child: Center(child: loadingIndicatorChild),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
