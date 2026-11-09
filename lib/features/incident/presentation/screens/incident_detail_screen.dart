import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/incident_module.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_composer_bar.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_resolved_banner.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_thread_bubble.dart';

/// Layar detail insiden dan percakapan realtime (HTTP + SSE) antar petugas
/// dan admin.
///
/// Mengelola siklus hidup stream foreground, pemulihan pesan tertinggal
/// (Last-Event-ID), resolusi insiden berkonsistensi atomik (HTTP 409 Conflict),
/// dan soft-delete admin dengan gaya kartu terstruktur yang serasi dengan
/// fitur Guest.
class IncidentDetailScreen extends StatefulWidget {
  /// Membuat instance [IncidentDetailScreen].
  const IncidentDetailScreen({required this.incidentId, super.key});

  /// ID insiden yang ditampilkan.
  final String incidentId;

  /// Factory rute navigasi standar [IncidentDetailScreen].
  static Route<dynamic> route({required String incidentId}) {
    return AppPageRoute.forwardBackward<dynamic>(
      builder: (context) {
        final module = context.read<IncidentModule>();
        return BlocProvider<IncidentDetailCubit>(
          create: (context) =>
              module.createIncidentDetailCubit(incidentId: incidentId),
          child: IncidentDetailScreen(incidentId: incidentId),
        );
      },
    );
  }

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final session = _resolveSession(context);
        context.read<IncidentDetailCubit>().init(session: session);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    final cubit = context.read<IncidentDetailCubit>();
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.hidden) {
      cubit.pauseStream();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      cubit.resumeStream();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _confirmResolve(
    BuildContext context,
    IncidentEntity incident,
    AuthSessionEntity? session,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Selesaikan Insiden?',
      message:
          'Setelah ditandai selesai, thread diskusi ini akan dikunci dan '
          'beralih ke mode baca saja.',
      confirmText: 'Ya, Selesaikan',
      isDestructive: false,
    );

    if (confirmed == true && context.mounted) {
      unawaited(
        context.read<IncidentDetailCubit>().resolveIncident(session: session),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    IncidentEntity incident,
    AuthSessionEntity? session,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus Laporan Insiden?',
      message:
          'Laporan insiden ini akan dihapus secara permanen dari pandangan '
          'pengguna. Tindakan ini hanya dapat dilakukan oleh Administrator.',
      confirmText: 'Hapus Insiden',
    );

    if (confirmed == true && context.mounted) {
      unawaited(
        context.read<IncidentDetailCubit>().deleteIncident(session: session),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final session = _resolveSession(context, listen: true);
    final isOffline = _resolveIsOffline(context, listen: true);

    return BlocConsumer<IncidentDetailCubit, IncidentDetailState>(
      listener: (context, state) {
        if (state.isTerminated) {
          AppSnackbar.show(
            context,
            message:
                state.errorMessage ??
                'Insiden telah dihapus oleh Administrator.',
          );
          Navigator.of(context).pop(widget.incidentId);
          return;
        }

        if (state.conflictNotice != null) {
          AppSnackbar.show(context, message: state.conflictNotice!);
          context.read<IncidentDetailCubit>().clearNotices();
        }

        if (state.infoNotice != null) {
          AppSnackbar.show(context, message: state.infoNotice!);
          context.read<IncidentDetailCubit>().clearNotices();
        }

        if (state.errorMessage != null && state.incident != null) {
          AppSnackbar.show(context, message: state.errorMessage!);
          context.read<IncidentDetailCubit>().clearNotices();
        }

        // Auto-scroll saat ada balasan baru
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      },
      builder: (context, state) {
        final incident = state.incident;
        final canResolve =
            incident != null &&
            incident.canBeResolvedBySession(session) &&
            !state.isReadOnly;
        final canDelete =
            incident != null && incident.canBeDeletedBySession(session);

        final greeting = AppDateFormat.formatGreeting(DateTime.now());

        Widget? trailingWidget;
        if (canResolve) {
          trailingWidget = AppButton(
            enabled: !state.isResolving && !isOffline,
            semanticLabel: 'Selesaikan insiden',
            onPressed: state.isResolving || isOffline
                ? null
                : () => _confirmResolve(context, incident, session),
            child: state.isResolving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: AppLoadingIndicator(),
                  )
                : Text('Selesaikan', style: typeScale.labelLarge),
          );
        } else if (canDelete) {
          trailingWidget = AppIconButton(
            onPressed: state.isDeleting || isOffline
                ? null
                : () => _confirmDelete(context, incident, session),
            tooltip: 'Hapus insiden',
            semanticLabel: 'Hapus laporan insiden',
            icon: AppSvgIcon(
              KawaloVectors.delete01,
              size: 24,
              color: colorScheme.error,
            ),
          );
        }

        return AppLoadingOverlay(
          isLoading: state.isResolving || state.isDeleting,
          semanticLabel: state.isResolving
              ? 'Menyelesaikan laporan insiden'
              : 'Menghapus laporan insiden',
          message: state.isResolving
              ? 'Menyelesaikan insiden...'
              : 'Menghapus laporan insiden...',
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppHomeAppBar(
              title: incident != null ? incident.title : 'Detail insiden',
              greeting: greeting,
              showBackButton: true,
              reserveGreetingSpace: true,
              onBackPressed: () => Navigator.of(context).pop(incident),
              trailing: trailingWidget,
            ),
            bottomNavigationBar: AppBottomOfflineBanner(isOffline: isOffline),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  // Banner Status Rekoneksi Realtime
                  if (state.isReconnecting)
                    Container(
                      width: double.infinity,
                      color: colorScheme.errorContainer.withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space200,
                        vertical: AppSpacing.space75,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: AppLoadingIndicator(),
                          ),
                          AppSpacing.hGapSm,
                          Flexible(
                            child: Text(
                              'Menghubungkan kembali ke server...',
                              style: typeScale.labelSmall.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Area Konten Detail & Percakapan
                  Expanded(child: _buildBodyContent(context, state, session)),

                  // Area Bawah: Composer Bar (aktif) atau Resolved Lock Banner
                  // (read-only)
                  if (incident != null) ...[
                    if (state.isReadOnly)
                      IncidentResolvedBanner(incident: incident)
                    else
                      IncidentComposerBar(
                        draftMessage: state.draftMessage,
                        draftPhotos: state.draftPhotos,
                        isPosting: state.isPostingReply,
                        onMessageChanged: (text) => context
                            .read<IncidentDetailCubit>()
                            .updateDraftMessage(text),
                        onAddPhoto: (photo) => context
                            .read<IncidentDetailCubit>()
                            .addDraftPhoto(photo),
                        onRemovePhoto: (id) => context
                            .read<IncidentDetailCubit>()
                            .removeDraftPhoto(id),
                        onSend: () => context
                            .read<IncidentDetailCubit>()
                            .postReply(session: session),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    IncidentDetailState state,
    AuthSessionEntity? session,
  ) {
    if (state.isLoading && state.incident == null) {
      return const Center(child: AppLoadingIndicator());
    }

    if (state.status == IncidentDetailStatus.failure &&
        state.incident == null) {
      return AppEmptyState.error(
        title: 'Gagal Memuat Insiden',
        description:
            state.errorMessage ??
            'Tidak dapat terhubung ke server untuk mengambil data insiden.',
        retryLabel: 'Coba lagi',
        onRetry: () =>
            context.read<IncidentDetailCubit>().init(session: session),
      );
    }

    final incident = state.incident;
    if (incident == null) return const SizedBox.shrink();

    final currentUserId = session?.userId;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            left: AppSpacing.space200,
            right: AppSpacing.space200,
            top: AppSpacing.space150,
            bottom: AppSpacing.space200,
          ),
          itemCount: state.replies.length + 1, // 0 = Header Card Insiden
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space150),
                child: _buildIncidentHeaderCard(
                  context,
                  incident,
                  repliesCount: state.replies.length,
                ),
              );
            }

            final reply = state.replies[index - 1];
            final isMe =
                currentUserId != null && reply.senderId == currentUserId;

            return IncidentThreadBubble(reply: reply, isMe: isMe);
          },
        ),
      ),
    );
  }

  Widget _buildIncidentHeaderCard(
    BuildContext context,
    IncidentEntity incident, {
    required int repliesCount,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Meta Atas (Kategori & Status) ─────────────────────────────
        Wrap(
          spacing: AppSpacing.space100,
          runSpacing: AppSpacing.space100,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppTag(
              label: incident.displayCategory,
              variant: AppTagVariant.secondary,
            ),
            AppTag(
              label: incident.displayStatusLabel,
              variant: incident.statusVariant,
              size: AppTagSize.small,
            ),
          ],
        ),

        AppSpacing.vGap200,

        // ── Kartu Ringkasan Informasi Insiden ───────────────────────────
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space150,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Avatar 40x40, Judul & Pelapor
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ClipRRect(
                    borderRadius: AppRadius.borderMedium,
                    child: AppSvgIcon.color(
                      KawaloColorVectors.incident1,
                      size: 40,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          incident.displayTitle,
                          style: emphasizedScale.titleLarge.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        AppSpacing.vGap25,
                        Text(
                          'Dilaporkan oleh ${incident.displayReporter} • '
                          '${incident.displayCreatedAt}',
                          style: typeScale.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: AppSpacing.paddingVertical150,
                child: AppDivider(),
              ),

              // Deskripsi Kejadian
              if (incident.description != null &&
                  incident.description!.trim().isNotEmpty) ...[
                Text(
                  'Deskripsi kejadian',
                  style: emphasizedScale.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                AppSpacing.vGap50,
                SelectableText(
                  incident.displayDescription,
                  style: typeScale.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGap150,
              ],

              // Titik Lokasi GPS jika ada
              if (incident.glat != null && incident.glong != null) ...[
                Row(
                  children: [
                    const AppSvgIcon.color(
                      KawaloColorVectors.location1,
                      size: 20,
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        'Koordinat GPS: ${incident.glat}, ${incident.glong}',
                        style: typeScale.labelMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ── Kartu Bukti Foto Laporan Awal (jika ada) ────────────────────
        if (incident.photos.isNotEmpty) ...[
          AppSpacing.vGap200,
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space200,
              vertical: AppSpacing.space150,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const AppSvgIcon(KawaloVectors.camera01, size: 24),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        'Foto Bukti Laporan (${incident.photos.length})',
                        style: emphasizedScale.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGap150,
                Wrap(
                  spacing: AppSpacing.space100,
                  runSpacing: AppSpacing.space100,
                  children: List.generate(incident.photos.length, (photoIndex) {
                    final photoUrl = incident.photos[photoIndex];
                    return GestureDetector(
                      onTap: () {
                        AppImageViewer.show(
                          context,
                          imageUrls: incident.photos,
                          initialIndex: photoIndex,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: AppRadius.borderMedium,
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const SizedBox(
                            width: 88,
                            height: 88,
                            child: AppImagePlaceholder(),
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 88,
                            height: 88,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],

        AppSpacing.vGap200,

        // ── Header Seksi Diskusi & Koordinasi ─────────────────────────
        Row(
          children: [
            const AppSvgIcon.color(KawaloColorVectors.log1, size: 24),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                'Diskusi & Koordinasi ($repliesCount)',
                style: emphasizedScale.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
