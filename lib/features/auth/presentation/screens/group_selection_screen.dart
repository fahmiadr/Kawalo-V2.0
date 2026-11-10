import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_card.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_selection_action_bar.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_selection_header.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_variant_mapper.dart';

/// Screen for users belonging to multiple groups to choose their active group.
/// Follows Material 3 Expressive standards, accessible touch targets, and
/// design system tokens.
class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({
    required this.user,
    this.allowCancel = false,
    super.key,
  });

  final UserEntity user;

  /// True when the screen is pushed over the main shell (switching group from
  /// the Lainnya tab): back then returns to the shell instead of logging out.
  final bool allowCancel;

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
    _selectedGroupUid =
        widget.user.activeGroup?.groupUid ??
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

  void _onBackPressed() {
    if (widget.allowCancel) {
      Navigator.of(context).maybePop();
    } else {
      _onLogoutPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is Authenticated) {
          unawaited(AppRouter.of(context).toMain());
        } else if (state is Unauthenticated) {
          unawaited(
            AppRouter.of(context).toLogin(sessionExpiredMessage: state.message),
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
                    icon: const AppSvgIcon(KawaloVectors.arrowLeft02, size: 24),
                    onPressed: isLoading ? null : _onBackPressed,
                    semanticLabel: widget.allowCancel
                        ? 'Kembali'
                        : 'Kembali ke halaman login',
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
                        child: Text('Ganti akun', style: typeScale.labelLarge),
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = AppLayout.horizontalMargin(
                        constraints.maxWidth,
                      );

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
                                      GroupSelectionHeader(
                                        userName: widget.user.name,
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
                                          child: GroupCard(
                                            key: ValueKey(group.groupUid),
                                            group: group,
                                            isSelected: isSelected,
                                            isLoading: isLoading,
                                            focusNode:
                                                _groupFocusNodes[group
                                                    .groupUid],
                                            onSelect: () => _onGroupSelected(
                                              group.groupUid,
                                            ),
                                            roleVariant: roleToVariant(
                                              group.category,
                                            ),
                                            statusVariant: groupStatusToVariant(
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
                          GroupSelectionActionBar(
                            horizontalPadding: horizontalPadding,
                            isLoading: isLoading,
                            canConfirm: _selectedGroupUid.isNotEmpty,
                            onConfirm: _onConfirmSelection,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Modal Scrim Overlay
              if (isLoading)
                const AppLoadingOverlay(semanticLabel: 'Menyiapkan grup'),
            ],
          ),
        );
      },
    );
  }
}
