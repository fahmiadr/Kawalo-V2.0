import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance/attendance_module.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/photo/attendance_photo_button.dart';
import 'package:kawalo_mobile/features/attendance/photo/authenticated_photo_fetcher.dart';
import 'package:kawalo_mobile/features/attendance/presentation/extensions/attendance_item_ui_extension.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_shift_marker.dart';

/// Bottom sheet interaktif yang menyajikan rincian lengkap catatan absensi
/// personil disertai peta OpenStreetMap (OSM) legal untuk penggunaan komersial.
class AttendanceDetailBottomSheet extends StatelessWidget {
  /// Membuat instance [AttendanceDetailBottomSheet].
  const AttendanceDetailBottomSheet({
    required this.item,
    this.reverseGeocodeService,
    this.photoFetcher,
    super.key,
  });

  /// Data catatan absensi yang ditampilkan.
  final AttendanceItemEntity item;

  /// Layanan opsional untuk reverse geocoding alamat fisik dari koordinat.
  final ReverseGeocodeService? reverseGeocodeService;

  /// Overrides the fetcher that [AttendanceModule] provides (tests).
  final AuthenticatedPhotoFetcher? photoFetcher;

  /// Menampilkan [AttendanceDetailBottomSheet] dalam modal.
  static Future<void> show({
    required BuildContext context,
    required AttendanceItemEntity item,
    ReverseGeocodeService? reverseGeocodeService,
    AuthenticatedPhotoFetcher? photoFetcher,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      child: AttendanceDetailBottomSheet(
        item: item,
        reverseGeocodeService: reverseGeocodeService,
        photoFetcher: photoFetcher,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppSpacing.space200,
        right: AppSpacing.space200,
        bottom: AppSpacing.space300,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Modal: Avatar, Identitas, Tag & Tombol Tutup ─────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppUserAvatar(
                name: item.displayUserName,
                imageUrl: item.displayAvatarUrl,
                size: 64,
              ),
              AppSpacing.hGap200,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.displayUserName,
                      style: emphasizedTypeScale.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGap25,
                    Text(
                      item.displayUserEmail,
                      style: typeScale.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGapSm,
                    AppTag(
                      label: item.displayCategory,
                      variant: item.tagVariant,
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapSm,
              AppIconButton(
                icon: const AppSvgIcon(KawaloVectors.cancel01, size: 24),
                semanticLabel: 'Tutup rincian absensi',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),

          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),

          // ── Section 1: Lokasi & Peta Statis OpenStreetMap ───────────
          Text(
            'Lokasi absensi',
            style: emphasizedTypeScale.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapSm,
          AppStaticMap(
            latitude: item.latitude,
            longitude: item.longitude,
            locationSemanticLabel:
                'Titik lokasi absensi ${item.displayUserName}',
            reverseGeocodeService: reverseGeocodeService,
            noGpsDescription:
                'Absensi ini dicatat tanpa data koordinat posisi.',
          ),

          AppSpacing.vGap200,

          // ── Section 2: Rincian Lengkap Absensi ─────────────────────
          Text(
            'Informasi kehadiran',
            style: emphasizedTypeScale.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapSm,
          _buildInfoCard(context, showSimilarity: _isAdmin(context)),

          AppSpacing.vGap300,

          // ── Tombol Aksi Bawah ──────────────────────────────────────
          ..._buildPhotoAction(context),
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

  bool _isAdmin(BuildContext context) =>
      context.read<UserSessionCubit?>()?.state?.isAdminRole ?? false;

  /// Check-in/out photos are biometric data: only admin roles may open them,
  /// and only when the server reports that a photo exists.
  List<Widget> _buildPhotoAction(BuildContext context) {
    final isAdmin = _isAdmin(context);
    final fetcher =
        photoFetcher ?? context.read<AttendanceModule?>()?.photoFetcher;
    if (!isAdmin || item.hasPhoto != true || fetcher == null) return const [];
    return [
      AttendancePhotoButton(
        label: 'Lihat foto',
        load: () => fetcher.fetch(
          '/v1/attendance/${item.id}/photo',
          name: 'attendance_${item.id}',
        ),
        discard: fetcher.discard,
      ),
      AppSpacing.vGapSm,
    ];
  }

  Widget _buildInfoCard(BuildContext context, {required bool showSimilarity}) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        children: [
          _buildInfoItem(
            context: context,
            iconPath: KawaloColorVectors.calendar1,
            label: 'Waktu absensi',
            value: item.displayAttendanceDt,
            trailingWidget: AppTag(
              label: item.displayDiffLabel,
              variant: item.statusVariant,
              size: AppTagSize.small,
            ),
          ),
          if (item.faceVerified != null) ...[
            const AppDivider(),
            _buildInfoItem(
              context: context,
              iconPath: KawaloColorVectors.cardTag1,
              label: 'Verifikasi wajah',
              value: item.isUnverified
                  ? 'Tidak terverifikasi'
                  : 'Terverifikasi',
              trailingWidget: AppTag(
                label: item.isUnverified ? 'Manual' : 'Cocok',
                variant: item.isUnverified
                    ? AppTagVariant.neutral
                    : AppTagVariant.primary,
                size: AppTagSize.small,
              ),
            ),
          ],
          if (showSimilarity && item.faceSimilarityPercent != null) ...[
            const AppDivider(),
            _buildInfoItem(
              context: context,
              iconPath: KawaloColorVectors.cardTag1,
              label: 'Hasil pencocokan',
              value: 'Kemiripan wajah ${item.faceSimilarityPercent}%',
            ),
          ],
          const AppDivider(),
          _buildInfoItem(
            context: context,
            iconPath: KawaloColorVectors.timeRotation,
            label: 'Shift kerja',
            value: item.displayShift,
            trailingWidget: AttendanceShiftMarker(item: item),
          ),
          const AppDivider(),
          _buildInfoItem(
            context: context,
            iconPath: KawaloColorVectors.location1,
            label: 'Pos absensi',
            value: item.displayLocationName,
          ),
          const AppDivider(),
          _buildInfoItem(
            context: context,
            iconPath: KawaloColorVectors.group2,
            label: 'Grup',
            value: item.displayGroupName,
          ),
          const AppDivider(),
          _buildInfoItem(
            context: context,
            iconPath: KawaloColorVectors.cardTag1,
            label: 'Status kedinasan',
            value: item.displayUserDuty,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required String iconPath,
    required String label,
    required String value,
    Widget? trailingWidget,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Row(
        children: [
          AppSvgIcon.color(iconPath, size: 32),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: typeScale.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGap25,
                Text(
                  value,
                  style: emphasizedTypeScale.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailingWidget != null) ...[AppSpacing.hGapSm, trailingWidget],
        ],
      ),
    );
  }
}
