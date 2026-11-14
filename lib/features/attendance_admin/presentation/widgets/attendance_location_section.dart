import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_location_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/attendance_radius_selector.dart';

/// The picked point on a map, its name and the radius. Read-only when
/// [enabled] is false.
class AttendanceLocationSection extends StatelessWidget {
  const AttendanceLocationSection({
    required this.state,
    required this.locationNameController,
    required this.enabled,
    required this.onPickPoint,
    required this.onLocationNameChanged,
    required this.onRadiusPreset,
    required this.onRadiusCustom,
    required this.onRadiusText,
    super.key,
  });

  final AttendanceLocationState state;
  final TextEditingController locationNameController;
  final bool enabled;
  final VoidCallback onPickPoint;
  final ValueChanged<String> onLocationNameChanged;
  final ValueChanged<int> onRadiusPreset;
  final VoidCallback onRadiusCustom;
  final ValueChanged<String> onRadiusText;

  @override
  Widget build(BuildContext context) {
    final lat = state.latitude;
    final long = state.longitude;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lat == null || long == null)
          AppFormEmptyPlaceholder(
            title: 'Belum ada titik lokasi',
            subtitle: 'Ketuk untuk memilih titik pos jaga di peta',
            vectorIcon: KawaloVectors.mapPin,
            onTap: enabled ? onPickPoint : null,
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AppStaticMap(
              latitude: lat,
              longitude: long,
              mapHeight: 140,
              markerStyle: AppStaticMapMarkerStyle.dot,
              showAddress: false,
              showOpenExternalButton: false,
            ),
          ),
          if (enabled) ...[
            AppSpacing.vGapSm,
            Align(
              alignment: Alignment.centerRight,
              child: AppTaskButton(
                label: 'Ubah titik',
                icon: Icons.location_on_outlined,
                variant: AppTaskButtonVariant.secondary,
                size: AppTaskButtonSize.small,
                onPressed: onPickPoint,
              ),
            ),
          ],
        ],
        AppSpacing.vGap200,
        AppTextField(
          label: 'Nama titik',
          variant: AppTextFieldVariant.outlined,
          controller: locationNameController,
          enabled: enabled,
          maxLength: AttendanceLocationCubit.nameMax,
          showCounter: false,
          textInputAction: TextInputAction.done,
          onChanged: onLocationNameChanged,
        ),
        AppSpacing.vGap200,
        AttendanceRadiusSelector(
          radiusText: state.radiusText,
          isCustom: state.isCustomRadius,
          enabled: enabled,
          errorText: state.radiusError,
          onPreset: onRadiusPreset,
          onCustom: onRadiusCustom,
          onTextChanged: onRadiusText,
        ),
      ],
    );
  }
}
