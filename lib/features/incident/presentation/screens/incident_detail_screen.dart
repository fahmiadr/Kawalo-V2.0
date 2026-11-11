import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/incident_module.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_app_bar_actions.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_body.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_bottom_area.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_reconnecting_banner.dart';

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
      settings: RouteSettings(
        name: AppRouteNames.incidentDetail,
        arguments: incidentId,
      ),
      builder: (context) {
        final module = context.read<IncidentModule>();
        return BlocProvider<IncidentDetailCubit>(
          create: (context) => module.createIncidentDetailCubit(
            incidentId: incidentId,
            uploadRepository: context.read<UploadRepository>(),
          ),
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
          trailingWidget = IncidentDetailResolveButton(
            isResolving: state.isResolving,
            isOffline: isOffline,
            onPressed: () => _confirmResolve(context, incident, session),
          );
        } else if (canDelete) {
          trailingWidget = IncidentDetailDeleteButton(
            isDeleting: state.isDeleting,
            isOffline: isOffline,
            onPressed: () => _confirmDelete(context, incident, session),
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
            // Scaffold strips the bottom padding from the body whenever a
            // bottomNavigationBar exists, so the composer's own SafeArea sees 0.
            // The banner must therefore keep reserving the system nav inset,
            // tinted like the bar above it.
            bottomNavigationBar: AppBottomOfflineBanner(
              isOffline: isOffline,
              keepSafeAreaWhenHidden: true,
              safeAreaColor: state.isReadOnly
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainer,
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  // Banner Status Rekoneksi Realtime
                  if (state.isReconnecting)
                    const IncidentDetailReconnectingBanner(),

                  // Area Konten Detail & Percakapan
                  Expanded(
                    child: IncidentDetailBody(
                      state: state,
                      session: session,
                      scrollController: _scrollController,
                    ),
                  ),

                  // Area Bawah: Composer Bar (aktif) atau Resolved Lock Banner
                  // (read-only)
                  if (incident != null)
                    IncidentDetailBottomArea(
                      incident: incident,
                      state: state,
                      session: session,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
