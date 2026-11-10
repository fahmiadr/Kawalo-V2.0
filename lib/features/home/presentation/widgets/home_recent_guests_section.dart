import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_detail_screen.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_recent_guests_card.dart';

/// Binds [HomeRecentGuestsCard] to the global [GuestCubit]: the 12 newest
/// guests, three per carousel page. Opening a row reuses the cubit so a
/// check-out or delete in the detail screen is reflected here.
class HomeRecentGuestsSection extends StatelessWidget {
  const HomeRecentGuestsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GuestCubit?>();
    final state = cubit?.state;
    final guests = state?.displayedGuests ?? const [];

    return HomeRecentGuestsCard(
      guestPages: buildRecentGuestPages(guests),
      isLoading: state is GuestInitial || state is GuestLoading,
      errorMessage: state is GuestError && guests.isEmpty
          ? state.message
          : null,
      isFromCache: state?.isFromCache ?? false,
      onRetry: cubit == null ? null : () => unawaited(cubit.fetchGuests()),
      onTapItem: (item) {
        final guest = item.guest;
        if (guest == null) return;
        unawaited(
          navigateToGuestDetailScreen(context, item: guest, cubit: cubit),
        );
      },
    );
  }
}
