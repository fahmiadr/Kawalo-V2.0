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
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_toolbar.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_file_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_location_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_post_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form_dialog.dart';

/// Melakukan navigasi ke layar detail informasi menggunakan rute
/// standar Material 3 Expressive [AppPageRoute.forwardBackward].
Future<void> navigateToInformationDetailScreen(
  BuildContext context, {
  required InformationItemEntity item,
  InformationCubit? cubit,
}) {
  final resolvedCubit =
      cubit ??
      (() {
        try {
          return context.read<InformationCubit>();
        } on Object catch (_) {
          return null;
        }
      })();

  final screen = InformationDetailScreen(item: item, cubit: resolvedCubit);

  return Navigator.of(context).push<void>(
    AppPageRoute.forwardBackward<void>(
      builder: (_) => resolvedCubit != null
          ? BlocProvider.value(value: resolvedCubit, child: screen)
          : screen,
    ),
  );
}

/// Tampilan layar penuh untuk informasi detail feed (`tkfeed`).
///
/// Konsisten dengan arsitektur layar detail `GuestDetailScreen` dan
/// `OperationalDetailScreen`.
class InformationDetailScreen extends StatefulWidget {
  /// Membuat instance [InformationDetailScreen].
  const InformationDetailScreen({
    required this.item,
    this.onRefresh,
    this.cubit,
    super.key,
  });

  /// Data informasi yang ditampilkan pada layar detail.
  final InformationItemEntity item;

  /// Callback opsional ketika pengguna menarik layar untuk memuat ulang data.
  final Future<void> Function()? onRefresh;

  /// Cubit opsional untuk manajemen data informasi.
  final InformationCubit? cubit;

  @override
  State<InformationDetailScreen> createState() =>
      _InformationDetailScreenState();
}

class _InformationDetailScreenState extends State<InformationDetailScreen> {
  bool _isDeleting = false;
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

  InformationCubit? _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit;
    try {
      return context.read<InformationCubit>();
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
      await cubit.refreshInformation();
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (mounted) {
      AppSnackbar.show(context, message: 'Data informasi berhasil diperbarui.');
    }
  }

  Future<void> _onPostPressed(BuildContext context) async {
    final cubit = _resolveCubit(context);
    await InformationFormDialog.showCreate(context, informationCubit: cubit);
  }

  Future<void> _onDeletePressed(
    BuildContext context,
    InformationItemEntity currentItem,
  ) async {
    if (_isDeleting) return;

    if (_resolveIsOffline(context)) {
      AppSnackbar.show(
        context,
        message: 'Tidak dapat menghapus informasi saat offline.',
      );
      return;
    }

    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus informasi?',
      message:
          'Informasi "${currentItem.displayTitle}" akan dihapus '
          'secara permanen.',
    );

    if ((confirmed ?? false) && context.mounted) {
      final cubit = _resolveCubit(context);
      if (cubit != null) {
        setState(() {
          _isDeleting = true;
        });

        final result = await cubit.deleteInformation(
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
              AppSnackbar.show(context, message: 'Informasi berhasil dihapus.');
              Navigator.of(context).pop();
            },
          );
        }
      }
    }
  }

  Future<void> _onEditPressed(
    BuildContext context,
    InformationItemEntity currentItem,
  ) async {
    final cubit = _resolveCubit(context);
    await InformationFormDialog.showUpdate(
      context,
      item: currentItem,
      informationCubit: cubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = _resolveCubit(context);
    final effectiveSession = _resolveSession(context, listen: true);

    Widget buildScaffold({
      required InformationItemEntity currentItem,
      required String greeting,
    }) {
      final canPost = InformationItemEntity.canBeCreatedBySession(
        effectiveSession,
      );
      final canDelete = currentItem.canBeDeletedBySession(effectiveSession);
      final canUpdate = currentItem.canBeUpdatedBySession(effectiveSession);
      final isOffline = _resolveIsOffline(context, listen: true);
      final hasAnyAction = canPost || canUpdate || canDelete;

      return AppLoadingOverlay(
        isLoading: _isDeleting,
        semanticLabel: 'Menghapus informasi',
        message: 'Menghapus informasi...',
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppHomeAppBar(
            greeting: greeting,
            title: 'Detail informasi',
            showBackButton: true,
            showTrailing: false,
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
                      semanticsLabel: 'Memuat ulang detail data informasi',
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Meta Atas (Nama Grup) ───────────────────
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: AppTag(
                                    label: currentItem.displayGroupName,
                                    variant: AppTagVariant.secondary,
                                  ),
                                ),

                                AppSpacing.vGap200,

                                // 1. Kartu Postingan Utama
                                InformationDetailPostCard(item: currentItem),

                                AppSpacing.vGap200,

                                // 2. Lokasi Kejadian & Visual Peta OSM
                                InformationDetailLocationCard(
                                  item: currentItem,
                                ),

                                // 3. Seksi Berkas Lampiran
                                if (currentItem.hasFileAttachment) ...[
                                  AppSpacing.vGap200,
                                  InformationDetailFileSection(
                                    item: currentItem,
                                  ),
                                ],
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
                            tooltip: 'Hapus informasi',
                            semanticLabel:
                                'Hapus informasi ${currentItem.displayTitle}',
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
                      if (canPost)
                        AppToolbarWidget(
                          child: AppIconButton(
                            onPressed: isOffline
                                ? null
                                : () => _onPostPressed(context),
                            tooltip: 'Posting informasi',
                            semanticLabel: 'Posting informasi',
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
                            tooltip: 'Edit informasi',
                            semanticLabel:
                                'Edit informasi ${currentItem.displayTitle}',
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
      return BlocSelector<
        InformationCubit,
        InformationState,
        (InformationItemEntity, String)
      >(
        bloc: cubit,
        selector: (state) {
          final item = state is InformationLoaded
              ? state.information.firstWhere(
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
