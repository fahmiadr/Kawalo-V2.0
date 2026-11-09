import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_toolbar.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_app_bar.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_profile_card.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_timeline_card.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_top_meta.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_visit_info_card.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form_dialog.dart';

/// Melakukan navigasi ke layar detail tamu menggunakan rute
/// standar Material 3 Expressive [AppPageRoute.forwardBackward].
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
      builder: (_) => resolvedCubit != null
          ? BlocProvider.value(value: resolvedCubit, child: screen)
          : screen,
    ),
  );
}

/// Tampilan layar penuh untuk informasi detail data tamu.
///
/// Mengonsolidasikan informasi menjadi 3 kartu terstruktur:
/// 1. Log aktivitas linimasa (Masuk, Konfirmasi, Keluar).
/// 2. Profil dan identitas tamu (Foto, nama, no. tamu, tags, alamat, QR code).
/// 3. Informasi kunjungan dan penanggung jawab (Detail kunjungan, host,
///    dan petugas).
///
/// Mendukung tarik untuk memuat ulang data ([AppRefreshIndicator]) yang
/// memperbarui waktu sinkronisasi klien secara reaktif.
class GuestDetailScreen extends StatefulWidget {
  /// Membuat instance [GuestDetailScreen].
  const GuestDetailScreen({
    required this.item,
    this.onRefresh,
    this.cubit,
    super.key,
  });

  /// Data tamu yang ditampilkan pada layar detail.
  final GuestItemEntity item;

  /// Callback opsional ketika pengguna menarik layar untuk memuat ulang data.
  final Future<void> Function()? onRefresh;

  /// Cubit opsional untuk manajemen data tamu.
  final GuestCubit? cubit;

  @override
  State<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  bool _isDeleting = false;
  bool _isCheckingOut = false;
  late final AppToolbarVisibilityController _toolbarVisibilityController;
  late final AppToolbarScrollBehavior _scrollBehavior;

  @override
  void initState() {
    super.initState();
    _toolbarVisibilityController = AppToolbarVisibilityController();
    _scrollBehavior = AppToolbarScrollBehavior.exitAlways(
      controller: _toolbarVisibilityController,
    );
  }

  @override
  void dispose() {
    _toolbarVisibilityController.dispose();
    super.dispose();
  }

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
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (mounted) {
      AppSnackbar.show(context, message: 'Data tamu berhasil diperbarui.');
    }
  }

  Future<void> _onDeletePressed(
    BuildContext context,
    GuestItemEntity currentItem,
  ) async {
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
          'Data tamu "${currentItem.displayGuestName}" akan dihapus '
          'secara permanen.',
    );

    if ((confirmed ?? false) && context.mounted) {
      final cubit = _resolveCubit(context);
      if (cubit != null) {
        setState(() {
          _isDeleting = true;
        });

        final result = await cubit.deleteGuest(
          currentItem,
          session: _resolveSession(context),
        );
        if (context.mounted) {
          result.fold(
            (failure) {
              setState(() {
                _isDeleting = false;
              });
              AppSnackbar.show(context, message: failure.message);
            },
            (_) {
              AppSnackbar.show(context, message: 'Data tamu berhasil dihapus.');
              Navigator.of(context).pop();
            },
          );
        }
      }
    }
  }

  Future<void> _onCheckoutPressed(
    BuildContext context,
    GuestItemEntity currentItem,
  ) async {
    if (_isCheckingOut) return;

    if (_resolveIsOffline(context)) {
      AppSnackbar.show(
        context,
        message: 'Tidak dapat melakukan check-out tamu saat offline.',
      );
      return;
    }

    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Check-out tamu?',
      message:
          'Tamu "${currentItem.displayGuestName}" '
          'akan ditandai telah keluar.',
      confirmText: 'Check-out',
      confirmStyle: AppButtonColor.filled,
      isDestructive: false,
    );

    if ((confirmed ?? false) && context.mounted) {
      final cubit = _resolveCubit(context);
      if (cubit != null) {
        setState(() {
          _isCheckingOut = true;
        });

        final result = await cubit.checkoutGuest(
          currentItem,
          session: _resolveSession(context),
        );

        if (context.mounted) {
          setState(() {
            _isCheckingOut = false;
          });
          result.fold(
            (failure) {
              AppSnackbar.show(context, message: failure.message);
            },
            (updatedItem) {
              AppSnackbar.show(
                context,
                message:
                    'Tamu "${updatedItem.displayGuestName}" '
                    'berhasil check-out.',
              );
            },
          );
        }
      }
    }
  }

  Future<void> _onCreatePressed(BuildContext context) async {
    final cubit = _resolveCubit(context);
    await GuestFormDialog.showCreate(context, guestCubit: cubit);
  }

  Future<void> _onEditPressed(
    BuildContext context,
    GuestItemEntity currentItem,
  ) async {
    final cubit = _resolveCubit(context);
    await GuestFormDialog.showUpdate(
      context,
      item: currentItem,
      guestCubit: cubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = _resolveCubit(context);
    final effectiveSession = _resolveSession(context, listen: true);

    Widget buildScaffold({
      required GuestItemEntity currentItem,
      required String greeting,
    }) {
      final canCreate = GuestItemEntity.canBeCreatedBySession(effectiveSession);
      final canDelete = currentItem.canBeDeletedBySession(effectiveSession);
      final canUpdate = currentItem.canBeUpdatedBySession(effectiveSession);
      final canCheckout = currentItem.canBeCheckedOutBySession(
        effectiveSession,
      );
      final hasAnyAction = canCreate || canUpdate || canDelete;
      final isOffline = _resolveIsOffline(context, listen: true);

      return AppLoadingOverlay(
        isLoading: _isDeleting || _isCheckingOut,
        semanticLabel: _isCheckingOut
            ? 'Memproses check-out tamu'
            : 'Menghapus data tamu',
        message: _isCheckingOut
            ? 'Memproses check-out tamu...'
            : 'Menghapus data tamu...',
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: GuestDetailAppBar(
            greeting: greeting,
            onCheckout: canCheckout
                ? () => _onCheckoutPressed(context, currentItem)
                : null,
            isCheckingOut: _isCheckingOut,
            enabled: !isOffline,
          ),
          bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppToolbarScrollWrapper(
                    behavior: _scrollBehavior,
                    child: AppRefreshIndicator.contained(
                      semanticsLabel: 'Memuat ulang detail data tamu',
                      onRefresh: _handleRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: AppSpacing.space200,
                          right: AppSpacing.space200,
                          top: AppSpacing.space150,
                          bottom: AppLayout.toolbarScrollClearance(context),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppLayout.contentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Meta Atas (Nama Grup) ───────────────────
                                GuestDetailTopMeta(item: currentItem),

                                AppSpacing.vGap200,

                                // ── Card 1: Log Aktivitas Tamu (Timeline) ───
                                GuestDetailTimelineCard(item: currentItem),

                                AppSpacing.vGap200,

                                // ── Card 2: Profil & Identitas Tamu ─────────
                                GuestDetailProfileCard(item: currentItem),

                                AppSpacing.vGap200,

                                // ── Card 3: Informasi Kunjungan ─────────────
                                GuestDetailVisitInfoCard(item: currentItem),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasAnyAction)
                  AppToolbar.floating(
                    alignment: Alignment.bottomCenter,
                    safeArea: true,
                    scrollBehavior: _scrollBehavior,
                    visibilityController: _toolbarVisibilityController,
                    actions: [
                      if (canDelete)
                        AppToolbarWidget(
                          child: AppIconButton(
                            onPressed: _isDeleting || isOffline
                                ? null
                                : () => _onDeletePressed(context, currentItem),
                            tooltip: 'Hapus data tamu',
                            semanticLabel:
                                'Hapus data tamu '
                                '${currentItem.displayGuestName}',
                            icon: AppSvgIcon(
                              KawaloVectors.delete01,
                              color: _isDeleting || isOffline
                                  ? colorScheme.onSurface.withValues(
                                      alpha: AppStateLayer.disabledOpacity,
                                    )
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      if (canCreate)
                        AppToolbarWidget(
                          child: AppIconButton(
                            onPressed: isOffline
                                ? null
                                : () => _onCreatePressed(context),
                            tooltip: 'Tambah tamu',
                            semanticLabel: 'Tambah data tamu',
                            variant: AppIconButtonColor.filled,
                            icon: AppSvgIcon(
                              KawaloVectors.add01,
                              color: isOffline
                                  ? colorScheme.onSurface.withValues(
                                      alpha: AppStateLayer.disabledOpacity,
                                    )
                                  : colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      if (canUpdate)
                        AppToolbarWidget(
                          child: AppIconButton(
                            onPressed: isOffline
                                ? null
                                : () => _onEditPressed(context, currentItem),
                            tooltip: 'Edit data tamu',
                            semanticLabel:
                                'Edit data tamu '
                                '${currentItem.displayGuestName}',
                            icon: AppSvgIcon(
                              KawaloVectors.edit03,
                              color: isOffline
                                  ? colorScheme.onSurface.withValues(
                                      alpha: AppStateLayer.disabledOpacity,
                                    )
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (cubit != null) {
      return BlocSelector<GuestCubit, GuestState, (GuestItemEntity, String)>(
        bloc: cubit,
        selector: (state) {
          final item = state is GuestLoaded
              ? state.guests.firstWhere(
                  (i) => i.id == widget.item.id,
                  orElse: () => widget.item,
                )
              : widget.item;
          final greeting = state.lastSync.isNotEmpty
              ? state.lastSync
              : (cubit.currentGreeting.isNotEmpty
                    ? cubit.currentGreeting
                    : AppDateFormat.formatGreeting(DateTime.now()));
          return (item, greeting);
        },
        builder: (context, data) {
          final (currentItem, effectiveGreeting) = data;
          return buildScaffold(
            currentItem: currentItem,
            greeting: effectiveGreeting,
          );
        },
      );
    }

    return buildScaffold(
      currentItem: widget.item,
      greeting: AppDateFormat.formatGreeting(DateTime.now()),
    );
  }
}
