import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/face_photos_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/manual_requests_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/extensions/manual_request_ui_extension.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/face_photos_sheet.dart';

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
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasized = theme.typography.emphasized;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.space200,
        right: AppSpacing.space200,
        bottom: AppSpacing.space300 + MediaQuery.viewInsetsOf(context).bottom,
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
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _request.displayUserName,
                      style: emphasized.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _request.userEmail,
                      style: theme.typeScale.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.space100,
            runSpacing: AppSpacing.space100,
            children: [
              AppTag(
                label: _request.displayType,
                variant: _request.displayType == 'Masuk'
                    ? AppTagVariant.primary
                    : AppTagVariant.secondary,
              ),
              AppTag(
                label: _request.status.label,
                variant: _request.statusVariant,
              ),
            ],
          ),
          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),
          Text(
            'Lokasi petugas saat meminta',
            style: emphasized.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapSm,
          AppStaticMap(
            latitude: _request.latitude,
            longitude: _request.longitude,
            showAddress: false,
            locationSemanticLabel:
                'Titik lokasi permintaan ${_request.displayUserName}',
            noGpsDescription: 'Permintaan ini tidak membawa koordinat.',
          ),
          AppSpacing.vGap200,
          Text(
            'Rincian permintaan',
            style: emphasized.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapSm,
          _buildInfoCard(context),
          if (_request.isPending) ..._buildDecision(context),
          AppSpacing.vGapSm,
          AppButton(
            style: AppButtonColor.tonal,
            shape: AppButtonShape.square,
            onPressed: _openFacePhotos,
            child: const Text('Lihat foto registrasi wajah'),
          ),
          AppSpacing.vGapSm,
          AppButton(
            style: AppButtonColor.tonal,
            shape: AppButtonShape.square,
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecision(BuildContext context) {
    return [
      AppSpacing.vGap200,
      AppTextField(
        label: 'Catatan admin (opsional)',
        variant: AppTextFieldVariant.outlined,
        controller: _noteController,
        maxLength: 200,
        maxLines: 2,
      ),
      AppSpacing.vGapSm,
      BlocBuilder<ManualRequestsCubit, ManualRequestsState>(
        bloc: widget.cubit,
        buildWhen: (a, b) => a.decidingIds != b.decidingIds,
        builder: (context, state) {
          final busy = state.decidingIds.contains(_request.id);
          return Row(
            children: [
              Expanded(
                child: AppButton(
                  style: AppButtonColor.tonal,
                  shape: AppButtonShape.square,
                  onPressed: busy ? null : () => _decide(approve: false),
                  child: const Text('Tolak'),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: AppButton(
                  shape: AppButtonShape.square,
                  onPressed: busy ? null : () => _decide(approve: true),
                  child: Text(busy ? 'Memproses...' : 'Setujui'),
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildInfoCard(BuildContext context) {
    final rows = <(String, String, String)>[
      (
        KawaloColorVectors.calendar1,
        'Waktu permintaan',
        _request.displayRequestedAt,
      ),
      (KawaloColorVectors.checklist2, 'Alasan', _request.displayReason),
      if ((_request.note ?? '').isNotEmpty)
        (KawaloColorVectors.cardTag1, 'Catatan petugas', _request.note!),
      (KawaloColorVectors.timeRotation, 'Shift kerja', _request.displayShift),
      if ((_request.locationName ?? '').isNotEmpty)
        (KawaloColorVectors.location1, 'Pos absensi', _request.locationName!),
      if (_request.displayDistance != null)
        (KawaloColorVectors.location1, 'Jarak', _request.displayDistance!),
      if (_request.failedAttempts > 0)
        (
          KawaloColorVectors.cardTag1,
          'Verifikasi wajah gagal',
          '${_request.failedAttempts} kali',
        ),
      if (!_request.isPending) ...[
        (
          KawaloColorVectors.group2,
          'Diputuskan oleh',
          '${_request.decidedBy ?? '—'} • ${_request.displayDecidedAt}',
        ),
        if ((_request.decisionNote ?? '').isNotEmpty)
          (
            KawaloColorVectors.cardTag1,
            'Catatan admin',
            _request.decisionNote!,
          ),
      ],
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const AppDivider(),
            _InfoRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Row(
        children: [
          AppSvgIcon.color(icon, size: 32),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGap25,
                Text(
                  value,
                  style: theme.typography.emphasized.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
