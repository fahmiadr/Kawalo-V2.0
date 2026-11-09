import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/widgets/onboarding_content_text.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/widgets/onboarding_hero_image.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

/// Custom ScrollPhysics assertion-safe untuk memblokir swipe manual di Step 1
/// (ke belakang) dan di Step 5 (ke depan), mengizinkan auto-advance film roll.
class OnboardingScrollPhysics extends ClampingScrollPhysics {
  const OnboardingScrollPhysics({required this.itemCount, super.parent});

  final int itemCount;

  @override
  OnboardingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OnboardingScrollPhysics(
      itemCount: itemCount,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final viewport = position.viewportDimension;
    if (viewport <= 0) return super.applyBoundaryConditions(position, value);

    // 1. Pengecekan saat scroll MUNDUR (value < position.pixels)
    if (value < position.pixels) {
      final pageIndex = (position.pixels / viewport).floor();
      if (pageIndex % itemCount == 0) {
        final stepMinPixels = pageIndex * viewport;
        if (value < stepMinPixels) {
          final overscroll = value - stepMinPixels;
          return overscroll.clamp(value - position.pixels, 0.0);
        }
      }
    }

    // 2. Pengecekan saat scroll MAJU (value > position.pixels)
    final isManualUserGesture =
        position is ScrollPosition &&
        position.userScrollDirection != ScrollDirection.idle;

    if (value > position.pixels && isManualUserGesture) {
      final pageIndex = (position.pixels / viewport).floor();
      if (pageIndex % itemCount == itemCount - 1) {
        final stepMaxPixels = pageIndex * viewport;
        if (value > stepMaxPixels) {
          final overscroll = value - stepMaxPixels;
          return overscroll.clamp(0.0, value - position.pixels);
        }
      }
    }

    return super.applyBoundaryConditions(position, value);
  }
}

/// Data model untuk item slide onboarding
class OnboardingItem {
  const OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;
}

/// Screen Onboarding dengan Auto-Carousel Film Roll Effect,
/// Clamping Bounds presisi, Touch Hold Pause, dan App Lifecycle Management.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// 5 Step Onboarding Data
  static const List<OnboardingItem> _items = [
    OnboardingItem(
      imagePath: 'assets/illustrations/onboarding_welcome.png',
      title: 'Selamat Datang di Aplikasi Kawalo 2.0 Terbaru',
      description:
          'Pantau insiden secara real-time, kelola personil, dan '
          'otomatisasi laporan operasional dalam satu aplikasi.',
    ),
    OnboardingItem(
      imagePath: 'assets/illustrations/onboarding_product_1.png',
      title: 'Pantau Lapangan Secara Langsung',
      description:
          'Visibilitas real-time untuk setiap insiden, posisi personil, '
          'data tamu, hingga status absensi dan patroli detik ini juga.',
    ),
    OnboardingItem(
      imagePath: 'assets/illustrations/onboarding_product_2.png',
      title: 'Absensi & Kehadiran Personil',
      description:
          'Lakukan check-in dan check-out secara cepat berbasis lokasi (GPS) '
          'langsung dari smartphone.',
    ),
    OnboardingItem(
      imagePath: 'assets/illustrations/onboarding_product_3.png',
      title: 'Kendali Operasional di Tangan Anda',
      description:
          'Atur grup pengamanan, buat jadwal & shift, serta pantau '
          'eksekusi patroli harian tanpa repot.',
    ),
    OnboardingItem(
      imagePath: 'assets/illustrations/onboarding_product_4.png',
      title: 'Laporan Selesai dalam Satu Klik',
      description:
          'Otomatisasi seluruh rekap data lapangan menjadi laporan '
          'bulanan formal yang siap diekspor.',
    ),
  ];

  /// Standar interval waktu per step onboarding (4 detik)
  static const Duration _stepDuration = Duration(milliseconds: 4000);

  /// Durasi animasi transisi antar halaman (500ms)
  static const Duration _pageTransitionDuration = Duration(milliseconds: 500);

  late final PageController _pageController;
  late final AnimationController _animController;
  int _currentStep = 0;
  int _displayedProgressStep = 0;
  int? _pendingStep;
  bool _isUserHolding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Mulai dari virtual index 1000 agar auto-loop film roll 100% native
    final initialPage = 1000 * _items.length;
    _pageController = PageController(initialPage: initialPage);
    _currentStep = initialPage % _items.length;
    _displayedProgressStep = _currentStep;

    _animController = AnimationController(vsync: this, duration: _stepDuration);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onStepTimerCompleted();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startTimerWhenVisible();
    });
  }

  /// Memastikan timer & animasi progres baru dimulai saat transisi screen
  /// selesai dan sepenuhnya terlihat oleh pengguna.
  void _startTimerWhenVisible() {
    if (AppMotion.isReducedMotion(context)) return;

    final route = ModalRoute.of(context);
    final animation = route?.animation;

    if (animation != null && !animation.isCompleted) {
      void statusListener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          animation.removeStatusListener(statusListener);
          if (mounted && !AppMotion.isReducedMotion(context)) {
            _animController.forward(from: 0);
          }
        }
      }

      animation.addStatusListener(statusListener);
    } else {
      _animController.forward(from: 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted || AppMotion.isReducedMotion(context)) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Saat aplikasi masuk ke latar belakang:
        // Jeda animasi progres dan timer onboarding
        _animController.stop(canceled: false);
      case AppLifecycleState.resumed:
        // Saat aplikasi dibuka kembali dari latar belakang:
        // Lanjutkan timer jika pengguna tidak sedang memegang layar
        if (!_isUserHolding && !_animController.isAnimating) {
          if (_animController.value >= 1.0 ||
              _displayedProgressStep != _currentStep) {
            _animController.forward(from: 0);
          } else {
            _animController.forward();
          }
        }
    }
  }

  void _onStepTimerCompleted() {
    if (!mounted || _isUserHolding || AppMotion.isReducedMotion(context)) {
      return;
    }

    // Selalu gunakan nextPage native smooth transition dengan kurva M3
    _pageController.nextPage(
      duration: _pageTransitionDuration,
      curve: AppMotion.emphasized,
    );
  }

  void _onPageChanged(int index) {
    if (!mounted) return;

    final newStep = index % _items.length;
    setState(() {
      _currentStep = newStep;
      if (_isUserHolding) {
        _pendingStep = newStep;
      } else {
        _displayedProgressStep = newStep;
      }
    });

    // Jalankan timer baru hanya jika pengguna tidak sedang memegang layar
    // dan tidak dalam mode reduced motion
    if (!_isUserHolding && !AppMotion.isReducedMotion(context)) {
      _animController.forward(from: 0);
    }
  }

  void _onPointerDown() {
    _isUserHolding = true;
    _animController.stop(canceled: false);
  }

  void _onPointerUp() {
    if (!_isUserHolding && _pendingStep == null) return;

    _isUserHolding = false;

    if (!mounted || AppMotion.isReducedMotion(context)) return;

    if (_pendingStep != null) {
      final nextStep = _pendingStep!;
      _pendingStep = null;
      setState(() {
        _displayedProgressStep = nextStep;
      });
      _animController.forward(from: 0);
    } else {
      if (_animController.value >= 1.0 ||
          _displayedProgressStep != _currentStep) {
        setState(() {
          _displayedProgressStep = _currentStep;
        });
        _animController.forward(from: 0);
      } else {
        _animController.forward();
      }
    }
  }

  void _navigateToNextScreen(BuildContext context) {
    _animController.stop();
    Navigator.of(context).pushReplacement(
      AppPageRoute.fade<void>(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppLayout.horizontalMargin(screenWidth);
    final isReducedMotion = AppMotion.isReducedMotion(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final m3eTheme = AppTheme.m3eLight();
    final lightTheme = AppTheme.lightThemeData();

    return M3ETheme(
      data: m3eTheme,
      child: Theme(
        data: lightTheme,
        child: Scaffold(
          backgroundColor: lightTheme.colorScheme.surface,
          body: Listener(
            onPointerDown: (_) => _onPointerDown(),
            onPointerUp: (_) => _onPointerUp(),
            onPointerCancel: (_) => _onPointerUp(),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth,
                  ),
                  child: Column(
                    children: [
                      // 1. Header / Progress Indicator (Fixed di atas)
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppSpacing.space200,
                          left: horizontalPadding,
                          right: horizontalPadding,
                          bottom: AppSpacing.space200,
                        ),
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            return OnboardingProgressBar(
                              totalSteps: _items.length,
                              currentStep: _displayedProgressStep,
                              stepProgress: isReducedMotion
                                  ? 1.0
                                  : _animController.value,
                            );
                          },
                        ),
                      ),

                      // 2. Center Content (Native Infinite Film Roll Carousel)
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: OnboardingScrollPhysics(
                            itemCount: _items.length,
                          ),
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            final item = _items[index % _items.length];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Pada layar terbatas atau dynamic font scale
                                  // tinggi, aktifkan SingleChildScrollView.
                                  final isConstrained =
                                      textScale > 1.3 ||
                                      constraints.maxHeight < 460;

                                  if (isConstrained) {
                                    return SingleChildScrollView(
                                      padding: AppSpacing.paddingVerticalSm,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height:
                                                (constraints.maxHeight * 0.42)
                                                    .clamp(140.0, 220.0),
                                            child: OnboardingHeroImage(
                                              imagePath: item.imagePath,
                                            ),
                                          ),
                                          AppSpacing.vGap300,
                                          OnboardingContentText(
                                            title: item.title,
                                            description: item.description,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Komposisi ideal: gambar ilustrasi dan teks
                                  // menjadi satu kesatuan visual kohesif di
                                  // tengah, teks tepat di bawah gambar, dengan
                                  // jarak napas lega terhadap action button.
                                  return Column(
                                    children: [
                                      const Spacer(flex: 2),

                                      // Gambar ilustrasi responsif
                                      Flexible(
                                        flex: 7,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight:
                                                (constraints.maxHeight * 0.48)
                                                    .clamp(180.0, 320.0),
                                          ),
                                          child: OnboardingHeroImage(
                                            imagePath: item.imagePath,
                                          ),
                                        ),
                                      ),

                                      AppSpacing.vGap400,

                                      // Content Text tepat di bawah gambar
                                      OnboardingContentText(
                                        title: item.title,
                                        description: item.description,
                                      ),

                                      const Spacer(flex: 3),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      // 3. Action Button (Fixed di bawah)
                      Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          bottom: AppSpacing.space200,
                          top: AppSpacing.space100,
                        ),
                        child: _buildActionButton(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tombol utama untuk melanjutkan navigasi
  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        shape: AppButtonShape.square,
        size: AppButtonSize.md,
        semanticLabel: 'Mulai sekarang',
        onPressed: () => _navigateToNextScreen(context),
        child: Text(
          'Mulai sekarang',
          style: AppTheme.of(context).typeScale.titleMedium,
        ),
      ),
    );
  }
}

/// Alias class name memfasilitasi konvensi penamaan screen
typedef OnboardingSelamatDatangScreen = OnboardingScreen;
