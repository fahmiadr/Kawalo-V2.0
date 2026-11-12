import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/presentation/cubit/personnel_cubit.dart';
import 'package:kawalo_mobile/features/group/presentation/cubit/personnel_state.dart';
import 'package:kawalo_mobile/features/group/presentation/widgets/personnel_card.dart';
import 'package:kawalo_mobile/features/group/presentation/widgets/personnel_card_skeleton.dart';

/// Read-only list of the members of the active group.
class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key, this.cubit});

  /// Test injection; defaults to the [PersonnelCubit] of the widget tree.
  final PersonnelCubit? cubit;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.personnel),
    builder: (_) => const PersonnelScreen(),
  );

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  PersonnelCubit get _cubit => widget.cubit ?? context.read<PersonnelCubit>();

  String _query = '';

  List<GroupMemberEntity> _filter(List<GroupMemberEntity> members) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return members;
    return [
      for (final m in members)
        if (m.displayName.toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q))
          m,
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_cubit.fetch());
    });
  }

  Future<void> _refresh() async {
    final ok = await _cubit.fetch(silent: true);
    if (!ok && mounted && _cubit.state is PersonnelLoaded) {
      AppSnackbar.show(context, message: 'Gagal memperbarui daftar personil.');
    }
  }

  Widget _buildList(List<GroupMemberEntity> members) {
    if (members.isEmpty) {
      return const AppEmptyState.search(
        title: 'Personil tidak ditemukan',
        description: 'Tidak ada personil yang cocok dengan pencarian ini.',
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space200,
        AppSpacing.space50,
        AppSpacing.space200,
        AppSpacing.space300,
      ),
      itemCount: members.length,
      separatorBuilder: (_, _) => AppSpacing.vGapSm,
      itemBuilder: (_, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth,
          ),
          child: PersonnelCard(member: members[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    return Scaffold(
      backgroundColor: AppTheme.of(context).colorScheme.surface,
      appBar: const AppHomeAppBar(
        title: 'Personil',
        showBackButton: true,
        showTrailing: false,
      ),
      body: SafeArea(
        top: false,
        child: AppRefreshIndicator.contained(
          semanticsLabel: 'Memuat ulang daftar personil',
          onRefresh: _refresh,
          child: BlocBuilder<PersonnelCubit, PersonnelState>(
            bloc: cubit,
            builder: (context, state) => switch (state) {
              PersonnelInitial() || PersonnelLoading() => ListScreenSkeleton(
                bottomPadding: AppSpacing.space300,
                itemBuilder: (_, _) => const PersonnelCardSkeleton(),
              ),
              PersonnelError(:final message) => ListErrorState(
                noun: 'daftar personil',
                message: message,
                onRetry: () => unawaited(cubit.fetch()),
              ),
              PersonnelLoaded(:final members) when members.isEmpty =>
                const AppEmptyState(
                  icon: AppSvgIcon.color(KawaloColorVectors.group1, size: 64),
                  title: 'Belum ada personil',
                  description: 'Grup ini belum memiliki anggota yang aktif.',
                ),
              PersonnelLoaded(:final members) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space200,
                      AppSpacing.space100,
                      AppSpacing.space200,
                      AppSpacing.space100,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppLayout.contentMaxWidth,
                        ),
                        child: AppSearchBar(
                          hintText: 'Cari nama atau email',
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildList(_filter(members))),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}
