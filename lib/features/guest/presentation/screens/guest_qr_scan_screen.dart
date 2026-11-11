import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
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
    // Keeps the camera error (and its actions) full-screen: nothing of the scan
    // overlay may cover it.
    final denied = fault == GuestQrScannerFault.permissionDenied;
    return AppActionableError.view(
      data: AppActionableErrorData(
        icon: KawaloVectors.cameraOff01Filled,
        title: denied ? 'Izin kamera dinonaktifkan' : 'Kamera tidak tersedia',
        message: denied
            ? 'Izin kamera diperlukan untuk memindai kode QR tamu.'
            : 'Kamera tidak dapat dibuka. Tutup aplikasi lain yang memakai '
                  'kamera, lalu coba lagi.',
        troubleshootingTips: denied
            ? const [
                'Ketuk Buka pengaturan di bawah.',
                'Pilih menu Izin aplikasi.',
                'Aktifkan izin Kamera.',
                'Kembali ke aplikasi dan ketuk Coba lagi.',
              ]
            : const [],
        primaryActionLabel: denied ? 'Buka pengaturan' : 'Coba lagi',
        onPrimaryAction: () => unawaited(
          denied
              ? widget.launcherService.openAppSettings()
              : _scanner.restart(),
        ),
        secondaryActionLabel: denied ? 'Coba lagi' : 'Kembali',
        onSecondaryAction: () => denied
            ? unawaited(_scanner.restart())
            : Navigator.of(context).maybePop(),
        themeMode: AppActionableErrorThemeMode.dark,
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
        child: Scaffold(
          backgroundColor: Colors.black,
          body: ListenableBuilder(
            listenable: _scanner.changes,
            builder: (context, _) {
              final fault = _scanner.fault;
              return fault == null
                  ? _buildScanner(context)
                  : _buildFault(context, fault);
            },
          ),
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
            padding: const EdgeInsets.all(AppSpacing.space200),
            child: Row(
              children: [
                AppIconButton(
                  semanticLabel: 'Tutup pemindai QR',
                  onPressed: () => Navigator.of(context).maybePop(),
                  decoration: _overlayButton(context),
                  icon: const AppSvgIcon(
                    KawaloVectors.cancel01,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                AppIconButton(
                  semanticLabel: _scanner.torch == GuestQrTorch.on
                      ? 'Matikan lampu senter'
                      : 'Nyalakan lampu senter',
                  onPressed: _scanner.torch == GuestQrTorch.unavailable
                      ? null
                      : _scanner.toggleTorch,
                  decoration: _overlayButton(context),
                  icon: AppSvgIcon(
                    _scanner.torch == GuestQrTorch.on
                        ? KawaloVectors.flashTorchFilled
                        : KawaloVectors.flashTorch,
                    color: Colors.white,
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

  M3EIconButtonDecoration _overlayButton(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    return M3EIconButtonDecoration(
      backgroundColor: WidgetStatePropertyAll(
        colorScheme.scrim.withValues(alpha: 0.60),
      ),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
    );
  }
}

class _Reticle extends StatelessWidget {
  const _Reticle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.65,
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GuestQrScanCubit>();
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final colorScheme = AppTheme.colorSchemeOf(context);

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
          GuestQrResolving() => ('Mencari tamu...', null, const <Widget>[]),
          GuestQrInvalid() => (
            'Kode QR tidak dikenali',
            'Kode ini bukan kode QR tamu Kawalo.',
            [_action('Pindai lagi', cubit.resumeScanning)],
          ),
          GuestQrNotFound() => (
            'Tamu tidak ditemukan',
            'Kode QR tidak terdaftar pada grup yang sedang aktif. '
                'Pastikan Anda berada di grup yang benar.',
            [_action('Pindai lagi', cubit.resumeScanning)],
          ),
          GuestQrForbidden(:final message) => (
            'Tidak punya akses',
            message,
            [_action('Kembali', onClose)],
          ),
          GuestQrFailed(:final message) => (
            'Gagal memuat data tamu',
            message,
            [
              _action('Coba lagi', cubit.retry),
              _action('Pindai lagi', cubit.resumeScanning, outlined: true),
            ],
          ),
        };

        return Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.space300,
              AppSpacing.space250,
              AppSpacing.space300,
              AppSpacing.space300 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.scrim.withValues(alpha: 0.72),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.large),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state is GuestQrResolving) ...[
                  const AppLoadingIndicator(
                    size: AppLoadingIndicatorSize.small,
                  ),
                  AppSpacing.vGap100,
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: emphasized.titleMedium.copyWith(color: Colors.white),
                ),
                if (message != null) ...[
                  AppSpacing.vGap50,
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: typeScale.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  AppSpacing.vGap200,
                  Wrap(
                    spacing: AppSpacing.space100,
                    runSpacing: AppSpacing.space100,
                    alignment: WrapAlignment.center,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // The themed outlined button is primary green, which disappears against the
  // near-black scrim panel, so the secondary action is drawn in white.
  static final _outlinedOnDark = AppButtonDecoration(
    foregroundColor: const WidgetStatePropertyAll(Colors.white),
    side: WidgetStatePropertyAll(
      BorderSide(color: Colors.white.withValues(alpha: 0.72)),
    ),
  );

  Widget _action(
    String label,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    return AppButton(
      style: outlined ? AppButtonColor.outlined : AppButtonColor.filled,
      decoration: outlined ? _outlinedOnDark : null,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
