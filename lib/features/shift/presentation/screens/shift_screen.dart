import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_state.dart';
import 'package:kawalo_mobile/features/shift/presentation/screens/shift_form_dialog.dart';
import 'package:kawalo_mobile/features/shift/presentation/widgets/shift_card.dart';
import 'package:kawalo_mobile/features/shift/presentation/widgets/shift_card_skeleton.dart';

/// Shifts of the active group. Every member reads; only the ADMIN and
/// SUPER_ADMIN roles (the role, not the `allow_admin` flag) see the create,
/// edit and delete controls. The API enforces the same rule.
class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key, this.cubit, this.canManage});

  /// Route name; move to `AppRouteNames` when wiring the feature.
  static const String routeName = AppRouteNames.shifts;

  /// Test injection; defaults to the [ShiftListCubit] of the widget tree.
  final ShiftListCubit? cubit;

  /// Test override of the role check, which otherwise reads the session.
  final bool? canManage;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: routeName),
    builder: (_) => const ShiftScreen(),
  );

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  ShiftListCubit get _cubit => widget.cubit ?? context.read<ShiftListCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_cubit.fetch());
    });
  }

  Future<void> _refresh() async {
    final ok = await _cubit.fetch(silent: true);
    if (!ok && mounted && _cubit.state is ShiftListLoaded) {
      AppSnackbar.show(context, message: 'Gagal memperbarui daftar shift.');
    }
  }

  Future<void> _openForm({ShiftEntity? shift}) async {
    final changed = await ShiftFormDialog.show(context, initial: shift);
    if (changed == true && mounted) unawaited(_cubit.fetch(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final canManage =
        widget.canManage ??
        context.select<UserSessionCubit, bool>(
          (c) => c.state?.isAdminRole ?? false,
        );

    final tones = KawaloTones.of(context);

    return BlocBuilder<ShiftListCubit, ShiftListState>(
      bloc: cubit,
      builder: (context, state) => Scaffold(
        backgroundColor: tones.background,
        appBar: AppTopBar(
          title: 'Shift',
          subtitle: switch (state) {
            ShiftListLoaded(:final shifts) when shifts.isNotEmpty =>
              '${shifts.length} shift aktif',
            _ => null,
          },
        ),
        bottomNavigationBar: canManage
            ? AppTaskFooter(
                children: [
                  AppTaskButton(
                    label: 'Tambah Shift',
                    icon: Icons.add_rounded,
                    tone: tones.adm,
                    onPressed: () => unawaited(_openForm()),
                  ),
                ],
              )
            : null,
        body: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang daftar shift',
          onRefresh: _refresh,
          child: switch (state) {
            ShiftListInitial() || ShiftListLoading() => ListScreenSkeleton(
              itemBuilder: (_, _) => const ShiftCardSkeleton(),
            ),
            ShiftListError(:final message) => ListErrorState(
              noun: 'daftar shift',
              message: message,
              onRetry: () => unawaited(cubit.fetch()),
            ),
            ShiftListLoaded(:final shifts) when shifts.isEmpty => AppEmptyState(
              icon: const AppSvgIcon.color(
                KawaloColorVectors.calendar2,
                size: 64,
              ),
              title: 'Belum ada shift',
              description: canManage
                  ? 'Buat shift dulu, misalnya Pagi 07:00–15:00, sebelum '
                        'menyusun jadwal.'
                  : 'Grup ini belum memiliki shift.',
            ),
            ShiftListLoaded(:final shifts) => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: shifts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth,
                  ),
                  child: ShiftCard(
                    shift: shifts[index],
                    onTap: canManage
                        ? () => unawaited(_openForm(shift: shifts[index]))
                        : null,
                  ),
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}
