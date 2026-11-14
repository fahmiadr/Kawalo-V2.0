import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form_dialog.dart';

Future<void> navigateToGuestDetailScreen(
  BuildContext context, {
  required GuestItemEntity item,
  GuestCubit? cubit,
}) {
  final resolvedCubit =
      cubit ??
      (() {
        try {
          return context.read<GuestCubit>();
        } on Object catch (_) {
          return null;
        }
      })();

  final screen = GuestDetailScreen(item: item, cubit: resolvedCubit);

  return Navigator.of(context).push<void>(
    AppPageRoute.forwardBackward<void>(
      settings: const RouteSettings(name: AppRouteNames.guestDetail),
      builder: (_) => resolvedCubit != null
          ? BlocProvider.value(value: resolvedCubit, child: screen)
          : screen,
    ),
  );
}

/// One guest (redesign 2026): photo, presence pill, times and details, with
/// a single bottom action: "Konfirmasi Kedatangan" while unacknowledged (and
/// the user may acknowledge), otherwise "Check-out Tamu"; none once the guest
/// left. Edit and delete sit in the top bar.
class GuestDetailScreen extends StatefulWidget {
  const GuestDetailScreen({
    required this.item,
    this.onRefresh,
    this.cubit,
    super.key,
  });

  final GuestItemEntity item;
  final Future<void> Function()? onRefresh;
  final GuestCubit? cubit;

  @override
  State<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  bool _isDeleting = false;
  bool _isCheckingOut = false;
  bool _isAcknowledging = false;

  GuestCubit? _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit;
    try {
      return context.read<GuestCubit>();
    } on Object catch (_) {
      return null;
    }
  }

  AuthSessionEntity? _resolveSession(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      final sessionCubit = listen
          ? context.watch<UserSessionCubit?>()
          : context.read<UserSessionCubit?>();
      return sessionCubit?.state;
    } on Object catch (_) {
      return null;
    }
  }

  bool _resolveIsOffline(BuildContext context, {bool listen = false}) {
    try {
      final connectivityCubit = listen
          ? context.watch<ConnectivityCubit?>()
          : context.read<ConnectivityCubit?>();
      return connectivityCubit?.state == ConnectivityStatus.offline;
    } on Object catch (_) {
      return false;
    }
  }

  Future<void> _handleRefresh() async {
    final cubit = _resolveCubit(context);
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else if (cubit != null) {
      await cubit.refreshGuests();
    } else {
      return;
    }
    if (mounted) {
      AppSnackbar.show(context, message: 'Data tamu berhasil diperbarui.');
    }
  }

  Future<void> _onDeletePressed(GuestItemEntity item) async {
    if (_isDeleting) return;
    if (_resolveIsOffline(context)) {
      AppSnackbar.show(
        context,
        message: 'Tidak dapat menghapus data tamu saat offline.',
      );
      return;
    }

    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus data tamu?',
      message:
          'Data tamu "${item.displayGuestName}" akan dihapus '
          'secara permanen.',
    );
    if (!(confirmed ?? false) || !mounted) return;
    final cubit = _resolveCubit(context);
    if (cubit == null) return;

    setState(() => _isDeleting = true);
    final result = await cubit.deleteGuest(
      item,
      session: _resolveSession(context),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _isDeleting = false);
        AppSnackbar.show(context, message: failure.message);
      },
      (_) {
        AppSnackbar.show(context, message: 'Data tamu berhasil dihapus.');
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _onCheckoutPressed(GuestItemEntity item) async {
    if (_isCheckingOut) return;
    if (_resolveIsOffline(context)) {
      AppSnackbar.show(
        context,
        message: 'Tidak dapat melakukan check-out tamu saat offline.',
      );
      return;
    }

    final now = TimeOfDay.now();
    final clock =
        '${now.hour.toString().padLeft(2, '0')}.'
        '${now.minute.toString().padLeft(2, '0')}';
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Check-out ${item.displayGuestName}?',
      message: 'Jam keluar dicatat $clock.',
      confirmText: 'Check-out',
      confirmStyle: AppButtonColor.filled,
      isDestructive: false,
    );
    if (!(confirmed ?? false) || !mounted) return;
    final cubit = _resolveCubit(context);
    if (cubit == null) return;

    setState(() => _isCheckingOut = true);
    final result = await cubit.checkoutGuest(
      item,
      session: _resolveSession(context),
    );
    if (!mounted) return;
    setState(() => _isCheckingOut = false);
    result.fold(
      (failure) => AppSnackbar.show(context, message: failure.message),
      (updated) => AppSnackbar.show(
        context,
        message:
            'Tamu "${updated.displayGuestName}" check-out pukul '
            '${updated.exitClock}.',
      ),
    );
  }

  Future<void> _onAcknowledgePressed(GuestItemEntity item) async {
    if (_isAcknowledging) return;
    if (_resolveIsOffline(context)) {
      AppSnackbar.show(
        context,
        message: 'Tidak dapat mengonfirmasi tamu saat offline.',
      );
      return;
    }

    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Konfirmasi kedatangan?',
      message:
          'Kedatangan "${item.displayGuestName}" ditandai sudah '
          'dikonfirmasi.',
      confirmText: 'Konfirmasi',
      confirmStyle: AppButtonColor.filled,
      isDestructive: false,
    );
    if (!(confirmed ?? false) || !mounted) return;
    final cubit = _resolveCubit(context);
    if (cubit == null) return;

    setState(() => _isAcknowledging = true);
    final result = await cubit.acknowledgeGuest(
      item,
      session: _resolveSession(context),
    );
    if (!mounted) return;
    setState(() => _isAcknowledging = false);
    result.fold(
      (failure) => AppSnackbar.show(context, message: failure.message),
      (updated) => AppSnackbar.show(
        context,
        message:
            'Kedatangan "${updated.displayGuestName}" berhasil '
            'dikonfirmasi.',
      ),
    );
  }

  Future<void> _onEditPressed(GuestItemEntity item) async {
    await GuestFormDialog.showUpdate(
      context,
      item: item,
      guestCubit: _resolveCubit(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    if (cubit == null) return _buildScaffold(widget.item);
    return BlocSelector<GuestCubit, GuestState, GuestItemEntity>(
      bloc: cubit,
      selector: (state) => state is GuestLoaded
          ? state.guests.firstWhere(
              (i) => i.id == widget.item.id,
              orElse: () => widget.item,
            )
          : widget.item,
      builder: (context, item) => _buildScaffold(item),
    );
  }

  Widget _buildScaffold(GuestItemEntity item) {
    final tones = KawaloTones.of(context);
    final session = _resolveSession(context, listen: true);
    final isOffline = _resolveIsOffline(context, listen: true);
    final canUpdate = item.canBeUpdatedBySession(session);
    final canDelete = item.canBeDeletedBySession(session);

    final Widget? action;
    if (item.canBeAcknowledgedBySession(session)) {
      action = AppTaskButton(
        label: 'Konfirmasi Kedatangan',
        icon: Icons.check_rounded,
        tone: tones.gst,
        isLoading: _isAcknowledging,
        onPressed: isOffline ? null : () => _onAcknowledgePressed(item),
      );
    } else if (item.canBeCheckedOutBySession(session)) {
      action = AppTaskButton(
        label: 'Check-out Tamu',
        icon: Icons.logout_rounded,
        tone: tones.gst,
        isLoading: _isCheckingOut,
        onPressed: isOffline ? null : () => _onCheckoutPressed(item),
      );
    } else {
      action = null;
    }

    return AppLoadingOverlay(
      isLoading: _isDeleting,
      semanticLabel: 'Menghapus data tamu',
      message: 'Menghapus data tamu...',
      child: Scaffold(
        backgroundColor: tones.background,
        appBar: AppBar(
          backgroundColor: tones.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tones.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.displayGuestType != '-')
                Text(
                  item.displayGuestType,
                  style: TextStyle(
                    color: tones.ink2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          actions: [
            if (canUpdate)
              IconButton(
                tooltip: 'Ubah data tamu',
                icon: const Icon(Icons.edit_outlined),
                onPressed: isOffline ? null : () => _onEditPressed(item),
              ),
            if (canDelete)
              IconButton(
                tooltip: 'Hapus data tamu',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: isOffline || _isDeleting
                    ? null
                    : () => _onDeletePressed(item),
              ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action != null)
              SafeArea(
                top: false,
                bottom: !isOffline,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: action,
                ),
              ),
            AppBottomOfflineBanner(isOffline: isOffline),
          ],
        ),
        body: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang detail data tamu',
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth,
                ),
                child: _GuestDetailBody(item: item),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestDetailBody extends StatelessWidget {
  const _GuestDetailBody({required this.item});

  final GuestItemEntity item;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final photo = item.guestPhoto?.trim();
    final hasPhoto =
        photo != null &&
        (photo.startsWith('http://') || photo.startsWith('https://'));
    final qr = item.qrUid?.trim();
    final heroPrefix = 'guest_profile_${item.id}';

    final identity = item.displayIdentityType == '-'
        ? null
        : '${item.displayIdentityType} ${item.displayIdNumber == '-' ? '' : item.displayIdNumber}'
              .trim();
    final details = <(String, String?)>[
      ('Tujuan', item.displayDestination),
      ('Bertemu', _orNull(item.displayGuestToUserName)),
      ('Identitas', identity),
      ('Plat / No. tamu', _orNull(item.displayGuestNumber)),
      ('Keperluan', _orNull(item.displayPurpose)),
      ('Alamat', _orNull(item.displayAddress)),
      ('Dicatat oleh', _orNull(item.displayRecordedBy)),
      if (item.hasCheckout)
        ('Check-out oleh', _orNull(item.displayCheckoutByName)),
      ('Grup', _orNull(item.displayGroupName)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPhoto) ...[
          Semantics(
            button: true,
            label: 'Lihat foto tamu ${item.displayName} ukuran penuh',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => AppImageViewer.show(
                context,
                imageUrls: [photo],
                heroTagPrefix: heroPrefix,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Hero(
                  tag: '${heroPrefix}_0',
                  child: CachedNetworkImage(
                    imageUrl: photo,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(height: 150, color: tones.surface2),
                    errorWidget: (_, _, _) => Container(
                      height: 150,
                      color: tones.surface2,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: tones.ink3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            AppStatusPill(
              label: item.presenceLabel,
              kind: item.isExited
                  ? AppStatusKind.neutral
                  : item.isConfirmed
                  ? AppStatusKind.ok
                  : AppStatusKind.warn,
            ),
            const Spacer(),
            if (qr != null && qr.isNotEmpty)
              Flexible(
                child: Semantics(
                  button: true,
                  label: 'Salin kode akses QR $qr',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: qr));
                      if (context.mounted) {
                        AppSnackbar.show(
                          context,
                          message: 'Kode akses QR disalin.',
                        );
                      }
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              qr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.monoFigures.copyWith(
                                color: tones.ink2,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.copy_rounded, size: 16, color: tones.ink2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _KvBox(
          rows: [
            ('Masuk', item.entryClock),
            ('Dikonfirmasi', item.confirmationClock),
            ('Keluar', item.exitClock),
          ],
          mono: true,
        ),
        const SizedBox(height: 14),
        _KvBox(
          rows: [
            for (final (k, v) in details)
              if (v != null) (k, v),
          ],
        ),
      ],
    );
  }

  static String? _orNull(String value) => value == '-' ? null : value;
}

class _KvBox extends StatelessWidget {
  const _KvBox({required this.rows, this.mono = false});

  final List<(String, String)> rows;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final valueStyle = TextStyle(
      color: tones.ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tones.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rows[i].$1,
                  style: TextStyle(color: tones.ink2, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.right,
                    style: mono
                        ? AppTheme.monoFigures.merge(valueStyle)
                        : valueStyle,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
