import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_card.dart';

/// "Pilih grup" (redesign 2026) for users in several groups. The logout
/// button in the top bar returns to login (to use another account).
class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({
    required this.user,
    this.allowCancel = false,
    super.key,
  });

  final UserEntity user;

  /// True when the screen is pushed over the main shell (switching group from
  /// the Pengaturan tab): back then returns to the shell instead of logging out.
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
    final tones = KawaloTones.of(context);
    final count = widget.user.groups.length;

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
          child: Scaffold(
            backgroundColor: tones.background,
            appBar: AppBar(
              backgroundColor: tones.background,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              leading: widget.allowCancel
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Kembali',
                      onPressed: isLoading ? null : _onBackPressed,
                    )
                  : null,
              title: const Text('Pilih grup'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Keluar dan ganti akun',
                  onPressed: isLoading ? null : _onLogoutPressed,
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                          children: [
                            Text(
                              'Akun Anda terdaftar di $count grup. '
                              'Pilih grup untuk bertugas hari ini.',
                              style: TextStyle(color: tones.ink2, fontSize: 14),
                            ),
                            const SizedBox(height: 14),
                            for (final group in widget.user.groups) ...[
                              GroupCard(
                                key: ValueKey(group.groupUid),
                                group: group,
                                isSelected: group.groupUid == _selectedGroupUid,
                                isLoading: isLoading,
                                focusNode: _groupFocusNodes[group.groupUid],
                                onSelect: () =>
                                    _onGroupSelected(group.groupUid),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        child: AppTaskButton(
                          label: 'Lanjut',
                          isLoading: isLoading,
                          semanticLabel: isLoading
                              ? 'Menyiapkan grup'
                              : 'Lanjut dengan grup terpilih',
                          onPressed: _selectedGroupUid.isEmpty
                              ? null
                              : _onConfirmSelection,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
