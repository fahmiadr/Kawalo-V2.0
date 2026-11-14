import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/face_photos_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/manual_requests_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/extensions/manual_request_ui_extension.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/face_photos_sheet.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// Detail of a manual attendance request with the approve/reject decision.
class ManualRequestDetailSheet extends StatefulWidget {
  const ManualRequestDetailSheet({
    required this.request,
    required this.cubit,
    required this.createFacePhotosCubit,
    super.key,
  });

  final ManualRequestEntity request;
  final ManualRequestsCubit cubit;

  /// Builds the cubit behind the face registration photo gallery.
  final FacePhotosCubit Function(String email) createFacePhotosCubit;

  static Future<void> show({
    required BuildContext context,
    required ManualRequestEntity request,
    required ManualRequestsCubit cubit,
    required FacePhotosCubit Function(String email) createFacePhotosCubit,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      child: ManualRequestDetailSheet(
        request: request,
        cubit: cubit,
        createFacePhotosCubit: createFacePhotosCubit,
      ),
    );
  }

  @override
  State<ManualRequestDetailSheet> createState() =>
      _ManualRequestDetailSheetState();
}

class _ManualRequestDetailSheetState extends State<ManualRequestDetailSheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  ManualRequestEntity get _request => widget.request;

  Future<void> _decide({required bool approve}) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: approve ? 'Setujui absen manual?' : 'Tolak absen manual?',
      message: approve
          ? 'Absensi ${_request.displayType.toLowerCase()} untuk '
                '${_request.displayUserName} akan dicatat pada '
                '${_request.displayRequestedAt} dan ditandai tidak '
                'terverifikasi.'
          : 'Permintaan ${_request.displayUserName} akan ditolak dan tidak '
                'ada absensi yang dicatat.',
      confirmText: approve ? 'Setujui' : 'Tolak',
      isDestructive: !approve,
      confirmStyle: approve ? AppButtonColor.filled : AppButtonColor.text,
    );
    if (confirmed != true || !mounted) return;
    final done = await widget.cubit.decide(
      request: _request,
      approve: approve,
      note: _noteController.text,
      session: context.read<UserSessionCubit?>()?.state,
    );
    if (done && mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _openFacePhotos() => FacePhotosSheet.show(
    context: context,
    name: _request.displayUserName,
    cubit: widget.createFacePhotosCubit(_request.userEmail),
  );

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final distance = _request.displayDistance;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: 22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppUserAvatar(
                name: _request.displayUserName,
                imageUrl: _request.avatarUrl,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _request.displayUserName,
                      style: TextStyle(
                        color: tones.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_request.displayType} · ${_request.displayShift}',
                      style: TextStyle(color: tones.ink2, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!_request.isPending)
                AppStatusPill(
                  label: _request.status.label,
                  kind: _request.status == ManualRequestStatus.approved
                      ? AppStatusKind.ok
                      : AppStatusKind.bad,
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoCard(),
          const SizedBox(height: 14),
          AppStaticMap(
            latitude: _request.latitude,
            longitude: _request.longitude,
            showAddress: false,
            locationSemanticLabel:
                'Titik lokasi permintaan ${_request.displayUserName}',
            noGpsDescription: 'Permintaan ini tidak membawa koordinat.',
          ),
          if (distance != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AppStatusPill(
                label: distance,
                icon: Icons.location_on_outlined,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AppTaskButton(
              label: 'Lihat foto registrasi wajah',
              icon: Icons.photo_library_outlined,
              variant: AppTaskButtonVariant.secondary,
              size: AppTaskButtonSize.small,
              onPressed: _openFacePhotos,
            ),
          ),
          if (_request.isPending) ..._buildDecision(context),
        ],
      ),
    );
  }

  List<Widget> _buildDecision(BuildContext context) {
    final tones = KawaloTones.of(context);
    return [
      const SizedBox(height: 14),
      AppTextField(
        label: 'Catatan admin (opsional)',
        variant: AppTextFieldVariant.outlined,
        controller: _noteController,
        maxLength: 200,
        maxLines: 2,
      ),
      const SizedBox(height: 8),
      BlocBuilder<ManualRequestsCubit, ManualRequestsState>(
        bloc: widget.cubit,
        buildWhen: (a, b) => a.decidingIds != b.decidingIds,
        builder: (context, state) {
          final busy = state.decidingIds.contains(_request.id);
          return Row(
            children: [
              Expanded(
                child: taskSecondary(
                  'Tolak',
                  busy ? null : () => _decide(approve: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTaskButton(
                  label: busy ? 'Memproses…' : 'Setujui',
                  icon: Icons.check_rounded,
                  tone: tones.adm,
                  size: AppTaskButtonSize.medium,
                  isLoading: busy,
                  onPressed: busy ? null : () => _decide(approve: true),
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildInfoCard() {
    return TaskBox(
      children: [
        TaskKeyValue('Dilaporkan', _request.displayRequestedAt),
        TaskKeyValue('Alasan', _request.displayReason),
        if ((_request.note ?? '').isNotEmpty)
          TaskKeyValue('Catatan petugas', _request.note!),
        if ((_request.locationName ?? '').isNotEmpty)
          TaskKeyValue('Pos absensi', _request.locationName!),
        if (_request.failedAttempts > 0)
          TaskKeyValue(
            'Verifikasi wajah gagal',
            '${_request.failedAttempts} kali',
          ),
        if (!_request.isPending) ...[
          TaskKeyValue(
            'Diputuskan oleh',
            '${_request.decidedBy ?? '—'} · ${_request.displayDecidedAt}',
          ),
          if ((_request.decisionNote ?? '').isNotEmpty)
            TaskKeyValue('Catatan admin', _request.decisionNote!),
        ],
      ],
    );
  }
}
