import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_image_collage.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_file_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_location_card.dart';
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
      settings: const RouteSettings(name: AppRouteNames.informationDetail),
      builder: (_) => resolvedCubit != null
          ? BlocProvider.value(value: resolvedCubit, child: screen)
          : screen,
    ),
  );
}

/// One announcement (redesign 2026): category, title, author and time, the
/// event schedule, text, photos, location and attachment. Edit and delete
/// sit in the top bar; there is no bottom action.
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
      return;
    }

    if (mounted) {
      AppSnackbar.show(context, message: 'Data informasi berhasil diperbarui.');
    }
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
    final cubit = _resolveCubit(context);
    if (cubit == null) return _buildScaffold(widget.item);
    return BlocSelector<
      InformationCubit,
      InformationState,
      InformationItemEntity
    >(
      bloc: cubit,
      selector: (state) => state is InformationLoaded
          ? state.information.firstWhere(
              (i) => i.id == widget.item.id,
              orElse: () => widget.item,
            )
          : widget.item,
      builder: (context, item) => _buildScaffold(item),
    );
  }

  Widget _buildScaffold(InformationItemEntity item) {
    final tones = KawaloTones.of(context);
    final session = _resolveSession(context, listen: true);
    final isOffline = _resolveIsOffline(context, listen: true);
    final canUpdate = item.canBeUpdatedBySession(session);
    final canDelete = item.canBeDeletedBySession(session);
    final schedule = item.eventScheduleLabel;
    final text = item.text?.trim() ?? '';
    final heroPrefix = 'info_detail_${item.id}';

    return AppLoadingOverlay(
      isLoading: _isDeleting,
      semanticLabel: 'Menghapus informasi',
      message: 'Menghapus informasi...',
      child: Scaffold(
        backgroundColor: tones.background,
        appBar: AppBar(
          backgroundColor: tones.background,
          title: const Text('Informasi'),
          actions: [
            if (canUpdate)
              IconButton(
                tooltip: 'Ubah informasi',
                icon: const Icon(Icons.edit_outlined),
                onPressed: isOffline
                    ? null
                    : () => _onEditPressed(context, item),
              ),
            if (canDelete)
              IconButton(
                tooltip: 'Hapus informasi',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: isOffline || _isDeleting
                    ? null
                    : () => _onDeletePressed(context, item),
              ),
          ],
        ),
        bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
        body: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang detail data informasi',
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppStatusPill(label: item.typeLabel),
                    const SizedBox(height: 10),
                    Text(
                      item.displayTitle,
                      style: TextStyle(
                        color: tones.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.displayUserName} · ${item.publishedAt}',
                      style: AppTheme.monoFigures.copyWith(
                        color: tones.ink2,
                        fontSize: 14,
                      ),
                    ),
                    if (schedule != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tones.surface2,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Jadwal acara',
                              style: TextStyle(color: tones.ink2, fontSize: 14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                schedule,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: tones.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        text,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (item.photos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      AppImageCollage(
                        imageUrls: item.photos,
                        heroTagPrefix: heroPrefix,
                        onImageTap: (index) => AppImageViewer.show(
                          context,
                          imageUrls: item.photos,
                          initialIndex: index,
                          heroTagPrefix: heroPrefix,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    InformationDetailLocationCard(item: item),
                    if (item.hasFileAttachment) ...[
                      const SizedBox(height: 14),
                      InformationDetailFileSection(item: item),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
