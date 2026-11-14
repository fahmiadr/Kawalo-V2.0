import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/splash/presentation/cubit/splash_cubit.dart';

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
  late final Animation<double> _fade;

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
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.emphasizedDecelerate,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.isReducedMotion(context)) {
        _controller.value = 1;
      } else {
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
    final tones = KawaloTones.of(context);

    return BlocListener<SplashCubit, SplashState>(
      bloc: _splashCubit,
      listenWhen: (_, current) => current.isReady,
      listener: (_, _) => _checkAndNavigate(),
      child: Scaffold(
        backgroundColor: tones.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fade,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: tones.ptt.soft,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              size: 52,
                              color: tones.ptt.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kawalo',
                            style: TextStyle(
                              color: tones.ink,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Operasional keamanan dalam satu genggaman',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: tones.ink2, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed-height slot so the caption does not jump when the
                    // slow-load spinner appears.
                    SizedBox(
                      height: 40,
                      child: _showSlowLoadingIndicator
                          ? AppLoadingIndicator(
                              color: tones.ptt.color,
                              semanticLabel: 'Memuat aplikasi...',
                            )
                          : null,
                    ),
                    Text(
                      'Memuat…',
                      style: TextStyle(color: tones.ink2, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
