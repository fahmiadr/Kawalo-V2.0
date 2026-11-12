import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card_skeleton.dart';
import 'package:kawalo_mobile/features/attendance_admin/attendance_admin_module.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/manual_requests_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/manual_request_card.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/manual_request_detail_sheet.dart';

/// Admin list of manual attendance requests, one tab per status.
class ManualRequestsScreen extends StatefulWidget {
  const ManualRequestsScreen({required this.module, super.key, this.cubit});

  final AttendanceAdminModule module;

  /// Injected by tests; otherwise created from [module] and owned here.
  final ManualRequestsCubit? cubit;

  /// Move the name to `AppRouteNames` when the route is wired up.
  static const String routeName = AppRouteNames.attendanceManualRequests;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: routeName),
    builder: (context) =>
        ManualRequestsScreen(module: context.read<AttendanceAdminModule>()),
  );

  @override
  State<ManualRequestsScreen> createState() => _ManualRequestsScreenState();
}

class _ManualRequestsScreenState extends State<ManualRequestsScreen> {
  late final ManualRequestsCubit _cubit;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? widget.module.createManualRequestsCubit();
    _scrollController = LoadMoreScrollController(onLoadMore: _cubit.loadMore);
    // The server refuses non-admins anyway; skip the pointless request.
    if (context.read<UserSessionCubit?>()?.state?.isAdminRole ?? false) {
      unawaited(_cubit.load());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (widget.cubit == null) unawaited(_cubit.close());
    super.dispose();
  }

  void _open(ManualRequestEntity request) {
    unawaited(
      ManualRequestDetailSheet.show(
        context: context,
        request: request,
        cubit: _cubit,
        createFacePhotosCubit: widget.module.createFacePhotosCubit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final isAdmin =
        context.watch<UserSessionCubit?>()?.state?.isAdminRole ?? false;

    return DefaultTabController(
      length: ManualRequestStatus.values.length,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Absen manual'),
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          elevation: 0,
          bottom: isAdmin
              ? TabBar(
                  onTap: (index) => unawaited(
                    _cubit.load(status: ManualRequestStatus.values[index]),
                  ),
                  tabs: [
                    for (final status in ManualRequestStatus.values)
                      Tab(text: status.label),
                  ],
                )
              : null,
        ),
        body: !isAdmin
            ? const AppEmptyState(
                icon: AppSvgIcon.color(KawaloColorVectors.checklist2),
                title: 'Khusus administrator',
                description:
                    'Hanya administrator yang dapat meninjau permintaan absen '
                    'manual.',
              )
            : BlocConsumer<ManualRequestsCubit, ManualRequestsState>(
                bloc: _cubit,
                listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
                listener: (context, state) {
                  final notice = state.notice;
                  if (notice != null) {
                    AppSnackbar.show(context, message: notice);
                  }
                },
                builder: (context, state) => SafeArea(
                  top: false,
                  child: AppRefreshIndicator.contained(
                    semanticsLabel: 'Memuat ulang permintaan absen manual',
                    onRefresh: _cubit.refresh,
                    child: _buildBody(state),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBody(ManualRequestsState state) {
    switch (state.phase) {
      case ManualRequestsPhase.loading:
        return ListScreenSkeleton(
          bottomPadding: AppSpacing.space200,
          itemBuilder: (_, _) => const AttendanceCardSkeleton(),
        );
      case ManualRequestsPhase.failure:
        return ListErrorState(
          noun: 'permintaan absen manual',
          message:
              state.errorMessage ?? 'Terjadi kendala saat memuat permintaan.',
          onRetry: () => unawaited(_cubit.load()),
        );
      case ManualRequestsPhase.loaded:
        if (state.items.isEmpty) {
          return AppEmptyState(
            icon: const AppSvgIcon.color(KawaloColorVectors.checklist2),
            title: 'Tidak ada permintaan',
            description: switch (state.status) {
              ManualRequestStatus.pending =>
                'Belum ada permintaan absen manual yang menunggu keputusan.',
              ManualRequestStatus.approved =>
                'Belum ada permintaan yang disetujui.',
              ManualRequestStatus.rejected =>
                'Belum ada permintaan yang ditolak.',
            },
          );
        }
        return ListScreenListView(
          controller: _scrollController,
          bottomPadding: AppSpacing.space200,
          itemCount: state.items.length,
          isLoadingMore: state.isLoadingMore,
          itemBuilder: (context, index) {
            final request = state.items[index];
            return ManualRequestCard(
              request: request,
              onTap: () => _open(request),
            );
          },
        );
    }
  }
}
