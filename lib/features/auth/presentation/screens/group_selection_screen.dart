import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_radio.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';

/// Screen for users belonging to multiple groups to choose their active group.
/// Follows Material 3 Expressive standards, accessible touch targets, and
/// design system tokens.
class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({
    required this.user,
    super.key,
  });

  final UserEntity user;

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  late String _selectedGroupUid;
  final Map<String, FocusNode> _groupFocusNodes = {};

  @override
  void initState() {
    super.initState();
    // Default selection: activeGroup if available, or first group in the list
    _selectedGroupUid = widget.user.activeGroup?.groupUid ??
        (widget.user.groups.isNotEmpty
            ? widget.user.groups.first.groupUid
            : '');

    // Initialize focus node for each group
    for (final group in widget.user.groups) {
      _groupFocusNodes[group.groupUid] = FocusNode(
        debugLabel: 'GroupCard_${group.groupUid}',
      );
    }

    // Auto-focus on the selected group after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedGroupUid.isNotEmpty) {
        _groupFocusNodes[_selectedGroupUid]?.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GroupSelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final group in widget.user.groups) {
      if (!_groupFocusNodes.containsKey(group.groupUid)) {
        _groupFocusNodes[group.groupUid] = FocusNode(
          debugLabel: 'GroupCard_${group.groupUid}',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final node in _groupFocusNodes.values) {
      node.dispose();
    }
    _groupFocusNodes.clear();
    super.dispose();
  }

  void _onGroupSelected(String groupUid) {
    _groupFocusNodes[groupUid]?.requestFocus();
    if (_selectedGroupUid == groupUid) return;

    setState(() {
      _selectedGroupUid = groupUid;
    });

    final selectedGroup = widget.user.groups.firstWhere(
      (g) => g.groupUid == groupUid,
      orElse: () => widget.user.groups.first,
    );
    final groupName = selectedGroup.groupName ?? selectedGroup.groupUid;
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Grup $groupName telah dipilih',
      Directionality.of(context),
    );
  }

  void _onConfirmSelection() {
    if (_selectedGroupUid.isEmpty) return;
    context.read<AuthBloc>().add(
          SwitchGroupSubmitted(groupUid: _selectedGroupUid),
        );
  }

  void _onLogoutPressed() {
    context.read<AuthBloc>().add(const LogoutRequested());
  }

  AppTagVariant _roleToVariant(String? category) {
    switch (category?.toUpperCase()) {
      case 'ADMIN':
        return AppTagVariant.primary;
      case 'GUARD':
        return AppTagVariant.secondary;
      case 'STAFF':
        return AppTagVariant.tertiary;
      case 'USER':
      default:
        return AppTagVariant.neutral;
    }
  }

  AppTagVariant _groupStatusToVariant(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return AppTagVariant.primary;
      case 'CLIENT':
        return AppTagVariant.secondary;
      case 'TRIAL':
        return AppTagVariant.tertiary;
      default:
        return AppTagVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasizedScale = AppTheme.emphasizedTypeScaleOf(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          AppSnackbar.show(
            context,
            message: state.message,
          );
        } else if (state is Authenticated) {
          Navigator.of(context).pushAndRemoveUntil<void>(
            AppPageRoute.fade<void>(
              builder: (_) => const MainNavigationScreen(),
            ),
            (route) => false,
          );
        } else if (state is Unauthenticated) {
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
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return PopScope(
          canPop: !isLoading,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: colorScheme.surface,
                appBar: AppBar(
                  backgroundColor: colorScheme.surface,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  leading: AppIconButton(
                    icon: const AppSvgIcon(
                      KawaloVectors.arrowLeft02,
                      size: 24,
                    ),
                    onPressed: isLoading ? null : _onLogoutPressed,
                    semanticLabel: 'Kembali ke halaman login',
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpacing.space150,
                      ),
                      child: AppButton(
                        style: AppButtonColor.text,
                        enabled: !isLoading,
                        onPressed: isLoading ? null : _onLogoutPressed,
                        semanticLabel: 'Ganti akun',
                        decoration: AppButtonDecoration(
                          foregroundColor: WidgetStatePropertyAll<Color?>(
                            colorScheme.error,
                          ),
                        ),
                        child: Text(
                          'Ganti akun',
                          style: typeScale.labelLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding =
                          AppLayout.horizontalMargin(constraints.maxWidth);

                      return Column(
                        children: [
                          // Scrollable List of Groups
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: AppSpacing.space200,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: AppLayout.contentMaxWidth,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Header Section
                                      Text(
                                        'Pilih grup',
                                        style: emphasizedScale.headlineMedium
                                            .copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      AppSpacing.vGapXs,
                                      Text(
                                        'Halo, ${widget.user.name}! Akun Anda '
                                        'terdaftar di beberapa grup '
                                        'organisasi. Pilih grup aktif untuk '
                                        'memulai operasional.',
                                        style: typeScale.bodyMedium.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      AppSpacing.vGap400,

                                      // Group Cards List
                                      ...widget.user.groups.map((group) {
                                        final isSelected =
                                            group.groupUid == _selectedGroupUid;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.space150,
                                          ),
                                          child: _GroupCard(
                                            key: ValueKey(group.groupUid),
                                            group: group,
                                            isSelected: isSelected,
                                            isLoading: isLoading,
                                            focusNode: _groupFocusNodes[
                                                group.groupUid],
                                            onSelect: () => _onGroupSelected(
                                              group.groupUid,
                                            ),
                                            roleVariant: _roleToVariant(
                                              group.category,
                                            ),
                                            statusVariant:
                                                _groupStatusToVariant(
                                              group.groupStatus,
                                            ),
                                          ),
                                        );
                                      }),
                                      AppSpacing.vGap200,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Persistent Sticky Action Bar (Always Visible)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              border: Border(
                                top: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppLayout.contentMaxWidth,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: AppSpacing.space150,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: AppButton(
                                      size: AppButtonSize.md,
                                      shape: AppButtonShape.square,
                                      enabled: !isLoading &&
                                          _selectedGroupUid.isNotEmpty,
                                      semanticLabel: isLoading
                                          ? 'Menyiapkan grup'
                                          : 'Konfirmasi dan lanjutkan ke '
                                              'beranda',
                                      onPressed: isLoading
                                          ? null
                                          : _onConfirmSelection,
                                      child: Text(
                                        'Lanjutkan ke beranda',
                                        style: typeScale.titleMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Modal Scrim Overlay
              if (isLoading)
                const AppLoadingOverlay(
                  semanticLabel: 'Menyiapkan grup',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupCard extends StatefulWidget {
  const _GroupCard({
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
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _isFocused = false;

  Widget _buildGroupLogo(String? logoUrl, String groupName) {
    return ExcludeSemantics(
      child: _buildGroupLogoVisual(logoUrl, groupName),
    );
  }

  Widget _buildGroupLogoVisual(String? logoUrl, String groupName) {
    if (logoUrl != null &&
        logoUrl.isNotEmpty &&
        (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: AppRadius.borderMedium,
        child: Image.network(
          logoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackLogo(groupName),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallbackLogo(groupName);
          },
        ),
      );
    }
    return _buildFallbackLogo(groupName);
  }

  Widget _buildFallbackLogo(String groupName) {
    return AppImagePlaceholder(
      width: 48,
      height: 48,
      borderRadius: AppRadius.borderMedium,
      icon: Image.asset(
        KawaloColorVectors.group2,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
      ),
      semanticLabel: 'Identitas $groupName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasizedScale = AppTheme.emphasizedTypeScaleOf(context);

    final groupName = widget.group.groupName ?? widget.group.groupUid;
    final roleName = (widget.group.category != null &&
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

    final hasOwner = widget.group.groupOwner != null &&
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
          border: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
          onPressed: widget.isLoading ? null : widget.onSelect,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Summary Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Logo with fallback to group-2
                  _buildGroupLogo(widget.group.groupLogo, groupName),
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
                      onChanged:
                          widget.isLoading ? null : (_) => widget.onSelect(),
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
