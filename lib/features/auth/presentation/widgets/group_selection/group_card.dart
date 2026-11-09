import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_radio.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_logo.dart';

class GroupCard extends StatefulWidget {
  const GroupCard({
    required this.group,
    required this.isSelected,
    required this.isLoading,
    required this.onSelect,
    required this.roleVariant,
    required this.statusVariant,
    this.focusNode,
    super.key,
  });

  final UserGroupEntity group;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onSelect;
  final AppTagVariant roleVariant;
  final AppTagVariant statusVariant;
  final FocusNode? focusNode;

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasizedScale = AppTheme.emphasizedTypeScaleOf(context);

    final groupName = widget.group.groupName ?? widget.group.groupUid;
    final roleName =
        (widget.group.category != null &&
            widget.group.category!.trim().isNotEmpty)
        ? widget.group.category!.trim()
        : '-';

    final isSelected = widget.isSelected;
    final isFocused = _isFocused;

    final borderColor = isFocused
        ? colorScheme.secondary
        : (isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5));

    final borderWidth = isFocused ? 2.5 : (isSelected ? 2.0 : 1.0);

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer.withValues(
            alpha: 0.16 + (isFocused ? AppStateLayer.focusOpacity : 0.0),
          )
        : (isFocused
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surfaceContainerLowest);

    final hasOwner =
        widget.group.groupOwner != null &&
        widget.group.groupOwner!.trim().isNotEmpty;
    final ownerPart = hasOwner ? ', pemilik ${widget.group.groupOwner}' : '';
    final selectionText = isSelected ? 'Terpilih' : 'Ketuk untuk memilih';

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (hasFocus) {
        if (_isFocused != hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        }
        if (hasFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: AppMotion.durationMedium1,
            curve: AppMotion.emphasizedDecelerate,
          );
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          if (!widget.isLoading) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: 'Grup $groupName$ownerPart, peran $roleName. $selectionText.',
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        button: true,
        child: AppCard(
          variant: isSelected ? AppCardVariant.filled : AppCardVariant.outlined,
          color: backgroundColor,
          border: BorderSide(color: borderColor, width: borderWidth),
          onPressed: widget.isLoading ? null : widget.onSelect,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Summary Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Logo with fallback to group-2
                  GroupLogo(
                    logoUrl: widget.group.groupLogo,
                    groupName: groupName,
                  ),
                  AppSpacing.hGap200,

                  // Group Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          groupName,
                          style: emphasizedScale.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.group.groupOwner != null &&
                            widget.group.groupOwner!.trim().isNotEmpty) ...[
                          AppSpacing.vGap25,
                          Row(
                            children: [
                              AppSvgIcon(
                                KawaloVectors.userRoundKey,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              AppSpacing.hGapSm,
                              Expanded(
                                child: Text(
                                  'Pemilik: ${widget.group.groupOwner}',
                                  style: typeScale.labelMedium.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        AppSpacing.vGap50,
                        Wrap(
                          spacing: AppSpacing.space50,
                          runSpacing: AppSpacing.space25,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppTag(
                              label: roleName,
                              variant: widget.roleVariant,
                            ),
                            if (widget.group.groupStatus != null &&
                                widget.group.groupStatus!.isNotEmpty)
                              AppTag(
                                label: widget.group.groupStatus!,
                                variant: widget.statusVariant,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hGapSm,

                  // Selection Radio Control (semantics handled by card)
                  ExcludeSemantics(
                    child: AppRadio<String>(
                      value: widget.group.groupUid,
                      groupValue: isSelected ? widget.group.groupUid : null,
                      onChanged: widget.isLoading
                          ? null
                          : (_) => widget.onSelect(),
                    ),
                  ),
                ],
              ),

              // Expandable Authority / Permissions Section (Auto-Disclosure)
              ClipRect(
                child: AnimatedSize(
                  duration: AppMotion.durationMedium2,
                  curve: AppMotion.emphasizedDecelerate,
                  alignment: Alignment.topCenter,
                  child: isSelected
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSpacing.vGap200,
                            const AppDivider(),
                            AppSpacing.vGapSm,
                            Text(
                              'Hak akses akun',
                              style: emphasizedScale.titleMedium.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.vGapSm,
                            Wrap(
                              spacing: AppSpacing.space50,
                              runSpacing: AppSpacing.space50,
                              children: [
                                AppTag(
                                  label: widget.group.allowAdmin
                                      ? 'Admin: Aktif'
                                      : 'Admin: Nonaktif',
                                  variant: widget.group.allowAdmin
                                      ? AppTagVariant.primary
                                      : AppTagVariant.neutral,
                                  size: AppTagSize.small,
                                  leading: const AppSvgIcon(
                                    KawaloVectors.userShield01,
                                    size: 14,
                                  ),
                                ),
                                AppTag(
                                  label: widget.group.allowPatrol
                                      ? 'Patroli: Aktif'
                                      : 'Patroli: Nonaktif',
                                  variant: widget.group.allowPatrol
                                      ? AppTagVariant.secondary
                                      : AppTagVariant.neutral,
                                  size: AppTagSize.small,
                                  leading: const AppSvgIcon(
                                    KawaloVectors.route1,
                                    size: 14,
                                  ),
                                ),
                                AppTag(
                                  label: widget.group.allowMonPatrol
                                      ? 'Monitor patroli: Aktif'
                                      : 'Monitor patroli: Nonaktif',
                                  variant: widget.group.allowMonPatrol
                                      ? AppTagVariant.tertiary
                                      : AppTagVariant.neutral,
                                  size: AppTagSize.small,
                                  leading: const AppSvgIcon(
                                    KawaloVectors.computerActivity,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.group.status != null &&
                                widget.group.status!.isNotEmpty) ...[
                              AppSpacing.vGapSm,
                              Text(
                                'Status keanggotaan: ${widget.group.status}',
                                style: typeScale.labelMedium.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
