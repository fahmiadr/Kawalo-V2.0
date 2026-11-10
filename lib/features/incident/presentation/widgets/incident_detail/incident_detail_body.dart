import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_header_card.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_thread_bubble.dart';

/// Konten utama layar detail: loading, error, atau header insiden diikuti
/// thread percakapan.
class IncidentDetailBody extends StatelessWidget {
  /// Membuat instance [IncidentDetailBody].
  const IncidentDetailBody({
    required this.state,
    required this.session,
    required this.scrollController,
    super.key,
  });

  /// State terkini [IncidentDetailCubit].
  final IncidentDetailState state;

  /// Sesi pengguna aktif, bila ada.
  final AuthSessionEntity? session;

  /// Controller scroll thread, dimiliki oleh State layar induk.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.incident == null) {
      return const Center(child: AppLoadingIndicator());
    }

    if (state.status == IncidentDetailStatus.failure &&
        state.incident == null) {
      return AppEmptyState.error(
        title: 'Gagal Memuat Insiden',
        description:
            state.errorMessage ??
            'Tidak dapat terhubung ke server untuk mengambil data insiden.',
        retryLabel: 'Coba lagi',
        onRetry: () =>
            context.read<IncidentDetailCubit>().init(session: session),
      );
    }

    final incident = state.incident;
    if (incident == null) return const SizedBox.shrink();

    final currentEmail = session?.email.trim().toLowerCase();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(
            left: AppSpacing.space200,
            right: AppSpacing.space200,
            top: AppSpacing.space150,
            bottom: AppSpacing.space200,
          ),
          itemCount: state.replies.length + 1, // 0 = Header Card Insiden
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space150),
                child: IncidentDetailHeaderCard(
                  incident: incident,
                  repliesCount: state.replies.length,
                ),
              );
            }

            final reply = state.replies[index - 1];
            // The API sends the sender's email as `senderId`, not the JWT `sub`.
            final isMe =
                currentEmail != null &&
                currentEmail.isNotEmpty &&
                reply.senderId.trim().toLowerCase() == currentEmail;

            return IncidentThreadBubble(reply: reply, isMe: isMe);
          },
        ),
      ),
    );
  }
}
