import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/presentation/widgets/forecast_widgets.dart';

enum _RoleFilter {
  all('Semua'),
  guard('Petugas'),
  admin('Admin'),
  other('Lainnya');

  const _RoleFilter(this.label);

  final String label;

  bool matches(ForecastPerson p) => switch (this) {
    all => true,
    guard => p.role == 'GUARD',
    admin => p.role == 'ADMIN' || p.role == 'SUPER_ADMIN',
    other => p.role != 'GUARD' && p.role != 'ADMIN' && p.role != 'SUPER_ADMIN',
  };
}

/// Picks the people a forecast schedules. Pops with the selected emails in the
/// order of [people], or `null` when the user leaves without confirming.
class ForecastPersonnelScreen extends StatefulWidget {
  const ForecastPersonnelScreen({
    required this.people,
    required this.selected,
    super.key,
  });

  static const String routeName = AppRouteNames.forecastPersonnel;

  final List<ForecastPerson> people;
  final List<String> selected;

  static Route<List<String>> route({
    required List<ForecastPerson> people,
    required List<String> selected,
  }) => AppPageRoute.slideFade<List<String>>(
    settings: const RouteSettings(name: routeName),
    builder: (_) => ForecastPersonnelScreen(people: people, selected: selected),
  );

  @override
  State<ForecastPersonnelScreen> createState() =>
      _ForecastPersonnelScreenState();
}

class _ForecastPersonnelScreenState extends State<ForecastPersonnelScreen> {
  late final Set<String> _selected = {...widget.selected};
  _RoleFilter _filter = _RoleFilter.all;
  String _query = '';

  List<ForecastPerson> get _visible {
    final q = _query.trim().toLowerCase();
    return [
      for (final p in widget.people)
        if (_filter.matches(p) &&
            (q.isEmpty ||
                p.displayName.toLowerCase().contains(q) ||
                p.email.toLowerCase().contains(q)))
          p,
    ];
  }

  void _toggleAll(List<ForecastPerson> visible, {required bool select}) {
    setState(() {
      for (final p in visible) {
        if (select) {
          _selected.add(p.email);
        } else {
          _selected.remove(p.email);
        }
      }
    });
  }

  void _confirm() => Navigator.of(context).pop([
    for (final p in widget.people)
      if (_selected.contains(p.email)) p.email,
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = _visible;
    final selectedVisible = visible
        .where((p) => _selected.contains(p.email))
        .length;
    final allVisible = visible.isNotEmpty && selectedVisible == visible.length;
    final chips = [
      for (final f in _RoleFilter.values)
        if (f == _RoleFilter.all ||
            f == _RoleFilter.guard ||
            f == _RoleFilter.admin ||
            widget.people.any(f.matches))
          f,
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const AppHomeAppBar(
        greeting: 'Forecast Jadwal',
        title: 'Pilih Personil',
        showBackButton: true,
        showTrailing: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ForecastContent(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space200,
                        AppSpacing.space100,
                        AppSpacing.space200,
                        AppSpacing.space100,
                      ),
                      child: AppSearchBar(
                        hintText: 'Cari nama atau email',
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space200,
                      ),
                      child: Row(
                        children: [
                          for (final f in chips) ...[
                            ChoiceChip(
                              label: Text(
                                '${f.label} '
                                '${widget.people.where(f.matches).length}',
                              ),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                            AppSpacing.hGapSm,
                          ],
                        ],
                      ),
                    ),
                    CheckboxListTile(
                      tristate: true,
                      enabled: visible.isNotEmpty,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: allVisible
                          ? true
                          : (selectedVisible == 0 ? false : null),
                      title: const Text('Pilih semua'),
                      secondary: Text(
                        '${_selected.length} dari ${widget.people.length} '
                        'dipilih',
                        style: theme.typeScale.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onChanged: (_) =>
                          _toggleAll(visible, select: !allVisible),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const AppEmptyState.search(
                              title: 'Tidak ada anggota',
                              description:
                                  'Tidak ada anggota yang cocok dengan '
                                  'pencarian atau filter ini.',
                            )
                          : ListView.builder(
                              itemCount: visible.length,
                              itemBuilder: (_, i) {
                                final p = visible[i];
                                return _PersonRow(
                                  person: p,
                                  selected: _selected.contains(p.email),
                                  onChanged: (v) => setState(() {
                                    if (v) {
                                      _selected.add(p.email);
                                    } else {
                                      _selected.remove(p.email);
                                    }
                                  }),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            ForecastBottomBar(
              buttons: [
                AppButton(
                  size: AppButtonSize.md,
                  onPressed: _confirm,
                  child: Text('Pilih ${_selected.length} Personil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.selected,
    required this.onChanged,
  });

  final ForecastPerson person;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasName = person.displayName != person.email;
    return CheckboxListTile(
      value: selected,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (v) => onChanged(v ?? false),
      title: Row(
        children: [
          AppUserAvatar(
            name: person.displayName,
            imageUrl: person.avatarUrl,
            size: 36,
            circle: true,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // The name falls back to the email, so it is not repeated.
                if (hasName)
                  Text(
                    person.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.of(context).typeScale.bodySmall.copyWith(
                      color: AppTheme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      secondary: AppTag(
        label: person.role.isEmpty ? '-' : person.role,
        size: AppTagSize.small,
        variant: person.isGuard
            ? AppTagVariant.secondary
            : AppTagVariant.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
      ),
    );
  }
}
