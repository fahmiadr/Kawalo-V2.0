import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

/// App-bar title with a one-line subtitle (redesign 2026 top bar).
class PttAppBarTitle extends StatelessWidget {
  const PttAppBarTitle({required this.title, super.key, this.subtitle});

  final String title;
  final String? subtitle;

  /// The channel is the active group, so its name names the channel.
  static String channelName(BuildContext context) {
    final authState = context.watch<AuthBloc?>()?.state;
    final groupName = authState is Authenticated
        ? authState.user.activeGroup?.groupName?.trim()
        : null;
    return (groupName == null || groupName.isEmpty) ? 'Kanal grup' : groupName;
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tones.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tones.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Title of the walkie-talkie screen: "Walkie-talkie" over the channel name
/// and the live connection status.
class PttChannelHeader extends StatelessWidget {
  const PttChannelHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final channel = PttAppBarTitle.channelName(context);
    return BlocBuilder<PttCubit, PttState>(
      buildWhen: (a, b) =>
          a.channel.connectionStatus != b.channel.connectionStatus,
      builder: (context, state) {
        final status = switch (state.channel.connectionStatus) {
          PttConnectionStatus.connected => 'Terhubung',
          PttConnectionStatus.connecting ||
          PttConnectionStatus.reconnecting => 'Menyambung…',
          _ => 'Terputus',
        };
        return PttAppBarTitle(
          title: 'Walkie-talkie',
          subtitle: '$channel · $status',
        );
      },
    );
  }
}
