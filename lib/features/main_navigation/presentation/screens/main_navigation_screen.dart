import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_module.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:kawalo_mobile/features/home/home_module.dart';
import 'package:kawalo_mobile/features/home/presentation/cubit/home_attendance_cubit.dart';
import 'package:kawalo_mobile/features/home/presentation/cubit/home_layout_cubit.dart';
import 'package:kawalo_mobile/features/home/presentation/extensions/home_card_ui_extension.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_layout_sheet.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_more_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_ptt_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_task_cards.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_task_deck.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/more_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/background_access_sheet.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/utils/ptt_platform.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';

/// The signed-in shell: the Beranda (redesign 2026) is a deck of task cards
/// whose bottom bar is the navigation. Every other feature opens as a pushed
/// screen from the cards or from "Lainnya".
///
/// The layout and duty-status cubits are created here when their modules are
/// provided; without them (isolated widget tests) the default layout is shown
/// and cannot be changed.
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeModule = context.read<HomeModule?>();
    final checkModule = context.read<AttendanceCheckModule?>();
    final session = context.read<UserSessionCubit?>()?.state;
    final providers = [
      if (homeModule != null)
        BlocProvider<HomeLayoutCubit>(
          create: (_) => homeModule.createLayoutCubit()..load(session),
        ),
      if (checkModule != null)
        BlocProvider<HomeAttendanceCubit>(
          create: (_) =>
              HomeAttendanceCubit(repository: checkModule.repository)..load(),
        ),
    ];
    if (providers.isEmpty) return const _Shell();
    return MultiBlocProvider(providers: providers, child: const _Shell());
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(BackgroundAccessSheet.maybeShow(context));
      _loadCards();
    });
  }

  void _loadCards() {
    final session = context.read<UserSessionCubit?>()?.state;
    // Always reloaded: the schedule is personal and per group.
    unawaited(context.read<ScheduleCubit?>()?.fetch());
    final incidents = context.read<IncidentListCubit?>();
    if (incidents != null && incidents.state is IncidentInitial) {
      unawaited(incidents.fetchIncidents(session: session));
    }
  }

  bool get _pttShown =>
      isPttSupportedPlatform && context.read<PttCubit?>() != null;

  Future<void> _arrange() async {
    final cubit = context.read<HomeLayoutCubit?>();
    if (cubit == null) return;
    final layout = await HomeLayoutSheet.show(
      context,
      layout: cubit.state,
      showPtt: _pttShown,
    );
    if (layout != null) unawaited(cubit.save(layout));
  }

  List<HomeDeckPage> _pages(HomeLayout layout, KawaloTones tones) {
    final pttShown = _pttShown;
    return [
      for (final card in layout.visible)
        if (card != HomeCard.ptt || pttShown)
          HomeDeckPage(
            id: card.name,
            label: card.label,
            icon: card.icon,
            tone: card.tone(tones),
            child: switch (card) {
              HomeCard.ptt => const HomePttCard(),
              HomeCard.sos || HomeCard.pat => HomeSoonCard(card: card),
              HomeCard.inc => const HomeIncidentCard(),
              HomeCard.gst || HomeCard.sch => HomeShortcutCard(card: card),
            },
          ),
      HomeDeckPage(
        id: 'lain',
        label: 'Lainnya',
        icon: Icons.grid_view_rounded,
        tone: tones.abs,
        child: HomeMoreCard(onArrange: () => unawaited(_arrange())),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final isOffline =
        context.watch<ConnectivityCubit?>()?.state ==
        ConnectivityStatus.offline;
    final layout =
        context.watch<HomeLayoutCubit?>()?.state ?? HomeLayout.fallback;

    final scaffold = Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: tones.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: Column(
              children: [
                HomeHeader(
                  onAvatarTap: () =>
                      Navigator.of(context).push(MoreScreen.route()),
                ),
                Expanded(child: HomeTaskDeck(pages: _pages(layout, tones))),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomOfflineBanner(
        isOffline: isOffline,
        keepSafeAreaWhenHidden: true,
        safeAreaColor: tones.background,
      ),
    );

    final listeners = [
      if (context.read<UserSessionCubit?>() != null)
        // A group switch keeps this screen when only the session changes.
        BlocListener<UserSessionCubit, AuthSessionEntity?>(
          listenWhen: (a, b) =>
              HomeLayoutCubit.scopeOf(a) != HomeLayoutCubit.scopeOf(b),
          listener: (context, session) {
            unawaited(context.read<HomeLayoutCubit?>()?.load(session));
            unawaited(context.read<HomeAttendanceCubit?>()?.load());
          },
        ),
      if (context.read<AuthBloc?>() != null)
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              unawaited(
                AppRouter.of(
                  context,
                ).toLogin(sessionExpiredMessage: state.message),
              );
            }
          },
        ),
    ];
    if (listeners.isEmpty) return scaffold;
    return MultiBlocListener(listeners: listeners, child: scaffold);
  }
}
