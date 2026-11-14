import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/cubit/theme_mode_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/account_menu_row.dart';

/// "Tampilan": Otomatis (follow the phone), Terang or Gelap. The choice
/// applies immediately; there is no save button.
class ThemeModeScreen extends StatelessWidget {
  const ThemeModeScreen({super.key});

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.themeMode),
    builder: (_) => const ThemeModeScreen(),
  );

  static String label(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Otomatis',
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
  };

  static const List<(ThemeMode, IconData, String?)> _options = [
    (ThemeMode.system, Icons.smartphone_rounded, 'Ikuti pengaturan HP'),
    (ThemeMode.light, Icons.light_mode_outlined, null),
    (ThemeMode.dark, Icons.dark_mode_outlined, 'Hemat baterai di malam hari'),
  ];

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppBar(
        backgroundColor: tones.background,
        scrolledUnderElevation: 0,
        title: const Text('Tampilan'),
      ),
      body: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, current) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            for (final (mode, icon, subtitle) in _options) ...[
              AccountMenuRow(
                icon: icon,
                title: label(mode),
                subtitle: subtitle,
                selected: mode == current,
                trailing: Icon(
                  mode == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: mode == current ? tones.ptt.color : tones.ink3,
                ),
                onTap: () =>
                    unawaited(context.read<ThemeModeCubit>().select(mode)),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
