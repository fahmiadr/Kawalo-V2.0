import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_composer_bar.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_resolved_banner.dart';

/// Area bawah layar detail: composer bar (aktif) atau banner kunci resolved
/// (read-only).
class IncidentDetailBottomArea extends StatelessWidget {
  /// Membuat instance [IncidentDetailBottomArea].
  const IncidentDetailBottomArea({
    required this.incident,
    required this.state,
    required this.session,
    super.key,
  });

  /// Insiden yang sedang ditampilkan.
  final IncidentEntity incident;

  /// State terkini [IncidentDetailCubit].
  final IncidentDetailState state;

  /// Sesi pengguna aktif, bila ada.
  final AuthSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    if (state.isReadOnly) {
      return IncidentResolvedBanner(incident: incident);
    }

    return IncidentComposerBar(
      draftMessage: state.draftMessage,
      draftPhotos: state.draftPhotos,
      isPosting: state.isPostingReply,
      onMessageChanged: (text) =>
          context.read<IncidentDetailCubit>().updateDraftMessage(text),
      onAddPhoto: (photo) =>
          context.read<IncidentDetailCubit>().addDraftPhoto(photo),
      onRemovePhoto: (id) =>
          context.read<IncidentDetailCubit>().removeDraftPhoto(id),
      onSend: () =>
          context.read<IncidentDetailCubit>().postReply(session: session),
    );
  }
}
