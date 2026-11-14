import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';

/// Three intro slides (redesign 2026 "Pengenalan"): PTT, reporting with a
/// photo, attendance with a face. The slides only lead to login; onboarding is
/// marked complete by the auth layer after the first successful login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

typedef _Slide = (
  IconData icon,
  KawaloTone Function(KawaloTones) tone,
  String title,
  String body,
);

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final List<_Slide> _slides = [
    (
      Icons.mic_none_rounded,
      (t) => t.ptt,
      'Bicara dengan satu tombol',
      'Tahan tombol besar untuk bicara ke semua rekan, seperti HT.',
    ),
    (
      Icons.report_outlined,
      (t) => t.inc,
      'Lapor dengan foto',
      'Kamera langsung terbuka. Tulis satu kalimat, kirim.',
    ),
    (
      Icons.face_retouching_natural_outlined,
      (t) => t.abs,
      'Absen dengan wajah',
      'Check-in dan check-out cukup menghadap kamera di titik absen.',
    ),
  ];

  final PageController _pageController = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  void _next() => _pageController.nextPage(
    duration: AppMotion.isReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 400),
    curve: AppMotion.emphasized,
  );

  void _finish() => unawaited(AppRouter.of(context).toLogin());

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final tone = _slides[_page].$2(tones);

    return Scaffold(
      backgroundColor: tones.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isLast
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AppTaskButton(
                          label: 'Lewati',
                          variant: AppTaskButtonVariant.secondary,
                          size: AppTaskButtonSize.small,
                          onPressed: _finish,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(_slides[i], tones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                children: [
                  Semantics(
                    label: 'Halaman ${_page + 1} dari ${_slides.length}',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? tone.color : tones.line,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTaskButton(
                    label: _isLast ? 'Mulai Sekarang' : 'Selanjutnya',
                    tone: tone,
                    onPressed: _isLast ? _finish : _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide, this.tones);

  final _Slide slide;
  final KawaloTones tones;

  @override
  Widget build(BuildContext context) {
    final (icon, toneOf, title, body) = slide;
    final tone = toneOf(tones);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: tone.soft,
                borderRadius: BorderRadius.circular(48),
              ),
              child: Icon(icon, size: 80, color: tone.color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tones.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(color: tones.ink2, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
