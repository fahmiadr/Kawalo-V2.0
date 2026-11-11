import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/utils/ptt_platform.dart';

/// Keeps the PTT channel of the active group joined for as long as there is a
/// session, whichever screen is open. Incoming audio plays in the native
/// service, so the channel must not depend on the PTT screen (or the main
/// navigation shell) having been visited.
///
/// Sits above the `MaterialApp`. Joins on session/group changes and when the
/// app returns to the foreground; `PttCubit.joinForGroup` is idempotent, so
/// extra calls are harmless.
class PttSessionBridge extends StatefulWidget {
  const PttSessionBridge({required this.child, super.key});

  final Widget child;

  @override
  State<PttSessionBridge> createState() => _PttSessionBridgeState();
}

class _PttSessionBridgeState extends State<PttSessionBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _join();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _join();
  }

  void _join() {
    if (!isPttSupportedPlatform) return;
    try {
      final groupUid = context.read<UserSessionCubit>().state?.groupUid;
      unawaited(context.read<PttCubit>().joinForGroup(groupUid));
    } on Object catch (_) {}
  }

  void _leave() {
    if (!isPttSupportedPlatform) return;
    try {
      final cubit = context.read<PttCubit>();
      if (cubit.state is! PttInitial) unawaited(cubit.leaveChannel());
    } on Object catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserSessionCubit, AuthSessionEntity?>(
      listenWhen: (previous, current) =>
          previous?.groupUid != current?.groupUid,
      // A logout clears the session; `switch-group` changes the group, and
      // `joinForGroup` leaves the old group's channel first.
      listener: (_, session) {
        final groupUid = session?.groupUid;
        if (groupUid == null || groupUid.isEmpty) {
          _leave();
        } else {
          _join();
        }
      },
      child: widget.child,
    );
  }
}
