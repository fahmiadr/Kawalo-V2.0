import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_navigation_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/home/presentation/utils/home_greeting_helper.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_screen.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

/// Halaman shell navigasi utama aplikasi Kawalo.
///
/// Mengelola kerangka Scaffold utama, perpindahan 4 destinasi navigasi
/// via [AppNavigationBar], serta koordinasi bilah aplikasi terpusat.
class MainNavigationScreen extends StatefulWidget {
  /// Membuat instance [MainNavigationScreen].
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinPttChannelIfAvailable();
    });
  }

  Future<void> _joinPttChannelIfAvailable() async {
    try {
      final session = context.read<UserSessionCubit?>()?.state;
      final groupUid = session?.groupUid;
      if (groupUid == null || groupUid.isEmpty) return;

      final pttCubit = context.read<PttCubit?>();
      if (pttCubit == null) return;

      if (pttCubit.state is! PttInitial && pttCubit.state is! PttDisconnected) {
        return;
      }

      final storageService = context.read<SecureStorageService?>();
      final token = await storageService?.getAccessToken();
      if (token == null || token.isEmpty) return;

      final baseUri = Uri.parse(EnvConfig.apiBaseUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final portPart = baseUri.hasPort ? ':${baseUri.port}' : '';
      final channelUrl = '$wsScheme://${baseUri.host}$portPart/ws/ptt/$groupUid';

      await pttCubit.joinChannel(
        channelUrl: channelUrl,
        groupUid: groupUid,
        token: token,
      );
    } on Object catch (_) {}
  }

  void _onDestinationSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      unawaited(_joinPttChannelIfAvailable());
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
        Expanded(
          child: HomeDashboardView(),
        ),
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
              const _PlaceholderView(
                title: 'Laporan',
                description:
                    'Daftar laporan dan validasi akan ditampilkan di sini.',
                iconPath: KawaloVectors.documentValidationFilled,
              ),
              const _PlaceholderView(
                title: 'Lainnya',
                description:
                    'Pengaturan dan menu lainnya akan ditampilkan di sini.',
                iconPath: KawaloVectors.moreHorizontalCircle01Filled,
              ),
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
                icon: AppSvgIcon(KawaloVectors.documentValidation),
                selectedIcon:
                    AppSvgIcon(KawaloVectors.documentValidationFilled),
                label: 'Laporan',
                semanticLabel: 'Buat laporan',
              ),
              AppNavigationBarDestination(
                icon: AppSvgIcon(KawaloVectors.moreHorizontalCircle01),
                selectedIcon:
                    AppSvgIcon(KawaloVectors.moreHorizontalCircle01Filled),
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
        if (state is Authenticated) {
          unawaited(_joinPttChannelIfAvailable());
        } else if (state is Unauthenticated) {
          try {
            unawaited(context.read<PttCubit?>()?.leaveChannel());
          } on Object catch (_) {}
          Navigator.of(context).pushAndRemoveUntil<void>(
            AppPageRoute.fade<void>(
              builder: (_) => LoginScreen(
                sessionExpiredMessage: state.message,
              ),
            ),
            (route) => false,
          );
        }
      },
      child: scaffold,
    );
  }
}

/// Widget placeholder untuk konten kosongan tiap tab destinasi navigasi.
class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({
    required this.title,
    required this.description,
    required this.iconPath,
  });

  final String title;
  final String description;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return SafeArea(
      bottom: false,
      maintainBottomViewPadding: true,
      child: Center(
        child: AppRefreshIndicator.contained(
        semanticsLabel: 'Memuat ulang data $title',
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (context.mounted) {
            AppSnackbar.show(
              context,
              message: '$title berhasil diperbarui.',
            );
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingAll300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                iconPath,
                size: 64,
                color: colorScheme.primary,
              ),
              AppSpacing.vGap300,
              Text(
                title,
                style: typeScale.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
              Text(
                description,
                style: typeScale.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
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

  @override
  Widget build(BuildContext context) {
    final hasAuthBloc =
        context.findAncestorWidgetOfExactType<BlocProvider<AuthBloc>>() != null;

    if (!hasAuthBloc) {
      return AppHomeAppBar(
        greeting: HomeGreetingHelper.formatGreeting(),
        unreadNotificationsCount: 9,
        onNotificationPressed: () {
          AppSnackbar.show(
            context,
            message: '9 Notifikasi baru belum dibaca.',
          );
        },
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
          unreadNotificationsCount: 9,
          onNotificationPressed: () {
            AppSnackbar.show(
              context,
              message: '9 Notifikasi baru belum dibaca.',
            );
          },
        );
      },
    );
  }
}
