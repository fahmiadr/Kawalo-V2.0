import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// One row of a [SchedulePickerSheet].
class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
}

/// Single-choice list for the person and shift fields of the schedule form.
/// Pops with the chosen value. The search field only appears with
/// [searchable]; it matches title and subtitle.
class SchedulePickerSheet<T> extends StatefulWidget {
  const SchedulePickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    super.key,
    this.searchable = false,
    this.emptyText = 'Tidak ada data.',
  });

  final String title;
  final List<PickerOption<T>> options;
  final T? selected;
  final bool searchable;
  final String emptyText;

  @override
  State<SchedulePickerSheet<T>> createState() => _SchedulePickerSheetState<T>();
}

class _SchedulePickerSheetState<T> extends State<SchedulePickerSheet<T>> {
  String _query = '';

  List<PickerOption<T>> get _shown {
    final q = _query.toLowerCase();
    return widget.options
        .where(
          (o) =>
              q.isEmpty ||
              o.title.toLowerCase().contains(q) ||
              (o.subtitle?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The sheet is anchored to the screen bottom and not resized by the
        // keyboard, so the keyboard height becomes bottom padding: the search
        // field and the list stay above it.
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        // A searchable sheet keeps one height; filtering must not resize it
        // while the user types.
        final fixedHeight = widget.searchable && constraints.hasBoundedHeight;
        final content = Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.space200,
            0,
            AppSpacing.space200,
            AppSpacing.space200 + keyboard,
          ),
          child: Column(
            mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: theme.typography.emphasized.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              AppSpacing.vGapSm,
              if (widget.searchable) ...[
                AppSearchBar(
                  hintText: 'Cari nama atau email',
                  onChanged: (v) => setState(() => _query = v.trim()),
                  leading: AppSvgIcon(
                    KawaloVectors.search01,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapSm,
              ],
              if (fixedHeight)
                Expanded(child: _list(context))
              else
                Flexible(child: _list(context)),
            ],
          ),
        );
        return fixedHeight
            ? SizedBox(height: constraints.maxHeight, child: content)
            : content;
      },
    );
  }

  Widget _list(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final shown = _shown;
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space300),
        child: Text(
          widget.emptyText,
          textAlign: TextAlign.center,
          style: theme.typeScale.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      // The default ListView padding adds the status-bar inset above the
      // first row, which looked like a large gap under the title.
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final o = shown[i];
        final isSelected = o.value == widget.selected;
        return Semantics(
          button: true,
          selected: isSelected,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(o.value),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppStateLayer.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space100,
                  horizontal: AppSpacing.space50,
                ),
                child: Row(
                  children: [
                    if (o.leading != null) ...[o.leading!, AppSpacing.hGap150],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.emphasized.bodyLarge
                                .copyWith(color: colorScheme.onSurface),
                          ),
                          if (o.subtitle != null)
                            Text(
                              o.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.typeScale.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (o.trailing != null) ...[AppSpacing.hGapSm, o.trailing!],
                    if (isSelected) ...[
                      AppSpacing.hGapSm,
                      AppSvgIcon(
                        KawaloVectors.check,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
