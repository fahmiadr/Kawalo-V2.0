import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_qr_scan_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_qr_scan_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/qr_scan/guest_qr_scanner.dart';
import 'package:kawalo_mobile/features/guest/presentation/qr_scan/mobile_scanner_guest_qr_scanner.dart';

/// Full-screen QR scanner that resolves a guest and pops with it.
///
/// The caller opens the existing guest detail, where check-out and
/// acknowledge (with their role checks) already live.
class GuestQrScanScreen extends StatefulWidget {
  const GuestQrScanScreen({
    required this.repository,
    super.key,
    this.scannerFactory,
    this.launcherService = const DefaultAppLauncherService(),
  });

  final GuestRepository repository;

  /// Replaced by a fake in tests; defaults to the `mobile_scanner` camera.
  final GuestQrScanner Function()? scannerFactory;

  final AppLauncherService launcherService;

  static Route<GuestItemEntity?> route({
    required GuestRepository repository,
    GuestQrScanner Function()? scannerFactory,
  }) => AppPageRoute.forwardBackward<GuestItemEntity?>(
    settings: const RouteSettings(name: AppRouteNames.guestQrScan),
    builder: (_) => GuestQrScanScreen(
      repository: repository,
      scannerFactory: scannerFactory,
    ),
  );

  @override
  State<GuestQrScanScreen> createState() => _GuestQrScanScreenState();
}

class _GuestQrScanScreenState extends State<GuestQrScanScreen> {
  late final GuestQrScanner _scanner;
  late final GuestQrScanCubit _cubit;
  StreamSubscription<String>? _codes;

  @override
  void initState() {
    super.initState();
    _scanner = (widget.scannerFactory ?? MobileScannerGuestQrScanner.new)();
    _cubit = GuestQrScanCubit(repository: widget.repository);
    _codes = _scanner.codes.listen(_cubit.onCode);
  }

  @override
  void dispose() {
    unawaited(_codes?.cancel());
    unawaited(_scanner.dispose());
    unawaited(_cubit.close());
    super.dispose();
  }

  Widget _buildFault(BuildContext context, GuestQrScannerFault fault) {
    final tones = KawaloTones.of(context);
    final denied = fault == GuestQrScannerFault.permissionDenied;
    void retry() => unawaited(_scanner.restart());
    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppBar(
        backgroundColor: tones.background,
        title: const Text('Pindai QR Tamu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: tones.surface2,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  Icons.no_photography_outlined,
                  size: 40,
                  color: tones.ink2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                denied ? 'Izin kamera dibutuhkan' : 'Kamera tidak tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tones.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                denied
                    ? 'Izinkan kamera untuk memindai QR tamu. Buka '
                          'Pengaturan, pilih Izin aplikasi, lalu aktifkan '
                          'Kamera.'
                    : 'Kamera tidak dapat dibuka. Tutup aplikasi lain yang '
                          'memakai kamera, lalu coba lagi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tones.ink2, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTaskButton(
                label: denied ? 'Buka Pengaturan' : 'Coba lagi',
                tone: tones.gst,
                onPressed: denied
                    ? () => unawaited(widget.launcherService.openAppSettings())
                    : retry,
              ),
              const SizedBox(height: 8),
              AppTaskButton(
                label: denied ? 'Coba lagi' : 'Kembali',
                variant: AppTaskButtonVariant.secondary,
                size: AppTaskButtonSize.medium,
                onPressed: denied
                    ? retry
                    : () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<GuestQrScanCubit, GuestQrScanState>(
        listenWhen: (_, current) => current is GuestQrResolved,
        listener: (context, state) {
          Navigator.of(context).pop((state as GuestQrResolved).item);
        },
        child: ListenableBuilder(
          listenable: _scanner.changes,
          builder: (context, _) {
            final fault = _scanner.fault;
            return fault == null
                ? Scaffold(
                    backgroundColor: _camBackground,
                    body: _buildScanner(context),
                  )
                : _buildFault(context, fault);
          },
        ),
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _scanner.buildPreview(context),
        const IgnorePointer(child: _Reticle()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  color: _camInk,
                  iconSize: 26,
                  icon: const Icon(
                    Icons.close_rounded,
                    semanticLabel: 'Tutup pemindai QR',
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Pindai QR Tamu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _camInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _scanner.torch == GuestQrTorch.unavailable
                      ? null
                      : _scanner.toggleTorch,
                  color: _camInk,
                  disabledColor: _camInk.withValues(alpha: 0.38),
                  icon: Icon(
                    _scanner.torch == GuestQrTorch.on
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    semanticLabel: _scanner.torch == GuestQrTorch.on
                        ? 'Matikan lampu senter'
                        : 'Nyalakan lampu senter',
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _ResultPanel(onClose: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}

/// Camera screen colours of the redesign (`--cam-bg`, `--cam-ink`): the
/// viewfinder stays dark in both themes.
const _camBackground = Color(0xFF0B0F0C);
const _camInk = Color(0xFFF3F6F2);

class _Reticle extends StatelessWidget {
  const _Reticle();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _ReticlePainter(), size: Size.infinite);
  }
}

/// Dims everything outside a centred rounded square and outlines it.
class _ReticlePainter extends CustomPainter {
  const _ReticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.68;
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: side,
        height: side,
      ),
      const Radius.circular(22),
    );
    canvas
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRRect(frame),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      )
      ..drawRRect(
        frame,
        Paint()
          ..color = _camInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_ReticlePainter oldDelegate) => false;
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GuestQrScanCubit>();
    final tones = KawaloTones.of(context);

    return BlocBuilder<GuestQrScanCubit, GuestQrScanState>(
      builder: (context, state) {
        final (
          String title,
          String? message,
          List<Widget> actions,
        ) = switch (state) {
          GuestQrScanning() || GuestQrResolved() => (
            'Arahkan kamera ke kode QR tamu',
            null,
            const <Widget>[],
          ),
          GuestQrResolving() => ('Mencari tamu…', null, const <Widget>[]),
          GuestQrInvalid() => (
            'Kode QR tidak dikenali',
            'Kode ini bukan kode QR tamu Kawalo.',
            [_action(tones, 'Pindai lagi', cubit.resumeScanning)],
          ),
          GuestQrNotFound() => (
            'Tamu tidak ditemukan',
            'Kode QR tidak terdaftar pada grup yang sedang aktif. '
                'Pastikan Anda berada di grup yang benar.',
            [_action(tones, 'Pindai lagi', cubit.resumeScanning)],
          ),
          GuestQrForbidden(:final message) => (
            'Tidak punya akses',
            message,
            [_action(tones, 'Kembali', onClose)],
          ),
          GuestQrFailed(:final message) => (
            'Gagal memuat data tamu',
            message,
            [
              _action(tones, 'Coba lagi', cubit.retry),
              _action(
                tones,
                'Pindai lagi',
                cubit.resumeScanning,
                secondary: true,
              ),
            ],
          ),
        };

        return Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state is GuestQrResolving) ...[
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: _camInk,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ] else if (message != null) ...[
                      Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                        color: tones.sos.color,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _camInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (message != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _camInk.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    actions[i],
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _action(
    KawaloTones tones,
    String label,
    VoidCallback onPressed, {
    bool secondary = false,
  }) {
    return AppTaskButton(
      label: label,
      tone: tones.gst,
      size: AppTaskButtonSize.medium,
      variant: secondary
          ? AppTaskButtonVariant.secondary
          : AppTaskButtonVariant.primary,
      onPressed: onPressed,
    );
  }
}
