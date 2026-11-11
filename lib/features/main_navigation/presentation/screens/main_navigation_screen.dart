import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/home/presentation/utils/home_greeting_helper.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/more_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/app_navigation_bar.dart';

/// Halaman shell navigasi utama aplikasi Kawalo.
///
/// Mengelola kerangka Scaffold utama, perpindahan 3 destinasi navigasi
/// via [AppNavigationBar], serta koordinasi bilah aplikasi terpusat.
class MainNavigationScreen extends StatefulWidget {
  /// Membuat instance [MainNavigationScreen].
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  /// Indeks destinasi navigasi awal saat dibuka (default: 0 = Beranda).
  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    } else if (index == 1) {
      // Refresh data jika tab informasi ditekan kembali saat sudah berada
      // di tab informasi.
      try {
        context.read<InformationCubit>().fetchInformation();
      } on Object catch (_) {}
    }
  }

  Widget _buildHomeTab() {
    return const Column(
      children: [
        _HomeAppBarWithAuth(),
        Expanded(child: HomeDashboardView()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    final connectivityCubit = context.watch<ConnectivityCubit?>();
    final isOffline = connectivityCubit?.state == ConnectivityStatus.offline;

    final hasAuthBloc =
        context.findAncestorWidgetOfExactType<BlocProvider<AuthBloc>>() != null;

    final scaffold = Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth,
          ),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeTab(),
              InformationScreen(isActive: _currentIndex == 1),
              const MoreScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppNavigationBar(
            backgroundColor: colorScheme.surfaceContainerHigh,
            safeArea: false,
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              AppNavigationBarDestination(
                icon: AppSvgIcon(KawaloVectors.home01),
                selectedIcon: AppSvgIcon(KawaloVectors.home01Filled),
                label: 'Beranda',
                semanticLabel: 'Beranda utama',
              ),
              AppNavigationBarDestination(
                icon: AppSvgIcon(KawaloVectors.kanban),
                selectedIcon: AppSvgIcon(KawaloVectors.kanbanFilled),
                label: 'Informasi',
                semanticLabel: 'Pusat informasi',
              ),
              AppNavigationBarDestination(
                icon: AppSvgIcon(KawaloVectors.moreHorizontalCircle01),
                selectedIcon: AppSvgIcon(
                  KawaloVectors.moreHorizontalCircle01Filled,
                ),
                label: 'Lainnya',
                semanticLabel: 'Menu lainnya',
              ),
            ],
          ),
          AppBottomOfflineBanner(
            isOffline: isOffline,
            keepSafeAreaWhenHidden: true,
            safeAreaColor: colorScheme.surfaceContainerHigh,
          ),
        ],
      ),
    );

    if (!hasAuthBloc) {
      return scaffold;
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          unawaited(
            AppRouter.of(context).toLogin(sessionExpiredMessage: state.message),
          );
        }
      },
      child: scaffold,
    );
  }
}

/// App Bar khusus Beranda yang terhubung secara reaktif dengan [AuthBloc].
class _HomeAppBarWithAuth extends StatelessWidget
    implements PreferredSizeWidget {
  const _HomeAppBarWithAuth();

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppHomeAppBar.defaultPreferredHeight);

  // The backend has no notification feature yet, so the bell shows no badge.
  static void _showNotificationsUnavailable(BuildContext context) {
    AppSnackbar.show(context, message: 'Notifikasi belum tersedia.');
  }

  @override
  Widget build(BuildContext context) {
    final hasAuthBloc =
        context.findAncestorWidgetOfExactType<BlocProvider<AuthBloc>>() != null;

    if (!hasAuthBloc) {
      return AppHomeAppBar(
        greeting: HomeGreetingHelper.formatGreeting(),
        onNotificationPressed: () => _showNotificationsUnavailable(context),
      );
    }

    return BlocSelector<AuthBloc, AuthState, (String?, String?)>(
      selector: (state) => state is Authenticated
          ? (state.user.name, state.user.activeGroup?.category)
          : (null, null),
      builder: (context, userInfo) {
        final greeting = HomeGreetingHelper.formatGreeting(
          name: userInfo.$1,
          role: userInfo.$2,
        );

        return AppHomeAppBar(
          greeting: greeting,
          onNotificationPressed: () => _showNotificationsUnavailable(context),
        );
      },
    );
  }
}
