import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_form_values.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_state.dart';
import 'package:kawalo_mobile/features/shift/presentation/widgets/shift_radius_selector.dart';
import 'package:material_3_expressive/material_3_expressive.dart'
    show M3ESwitch;

/// "Lokasi absen": the limit switch, the picked point, its name and radius.
class ShiftLocationSection extends StatelessWidget {
  const ShiftLocationSection({
    required this.state,
    required this.locationNameController,
    required this.onLimitChanged,
    required this.onPickPoint,
    required this.onLocationNameChanged,
    required this.onRadiusPreset,
    required this.onRadiusCustom,
    required this.onRadiusText,
    super.key,
  });

  final ShiftFormState state;
  final TextEditingController locationNameController;
  final ValueChanged<bool> onLimitChanged;
  final VoidCallback onPickPoint;
  final ValueChanged<String> onLocationNameChanged;
  final ValueChanged<int> onRadiusPreset;
  final VoidCallback onRadiusCustom;
  final ValueChanged<String> onRadiusText;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final values = state.values;
    final errors = state.errors;
    final enabled = !state.isBusy;
    final lat = values.latitude;
    final long = values.longitude;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Lokasi absen',
            style: theme.typography.emphasized.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        AppSpacing.vGapSm,
        MergeSemantics(
          child: InkWell(
            borderRadius: AppRadius.borderMedium,
            onTap: enabled ? () => onLimitChanged(!values.limitLocation) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batasi lokasi absen',
                          style: theme.typeScale.bodyLarge.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Absen hanya sah di dalam radius titik ini.',
                          style: theme.typeScale.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hGapSm,
                  M3ESwitch(
                    value: values.limitLocation,
                    onChanged: enabled ? onLimitChanged : null,
                    semanticLabel: 'Batasi lokasi absen',
                  ),
                ],
              ),
            ),
          ),
        ),
        if (values.limitLocation) ...[
          AppSpacing.vGap150,
          if (lat == null || long == null)
            AppFormEmptyPlaceholder(
              title: 'Belum ada titik lokasi',
              subtitle: 'Ketuk untuk memilih titik pos jaga di peta',
              vectorIcon: KawaloVectors.mapPin,
              onTap: enabled ? onPickPoint : null,
            )
          else ...[
            ClipRRect(
              borderRadius: AppRadius.borderMedium,
              child: AppStaticMap(
                latitude: lat,
                longitude: long,
                mapHeight: 140,
                markerStyle: AppStaticMapMarkerStyle.dot,
                showAddress: false,
                showOpenExternalButton: false,
              ),
            ),
            AppSpacing.vGapSm,
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                style: AppButtonColor.tonal,
                onPressed: enabled ? onPickPoint : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(KawaloVectors.location01, size: 18),
                    AppSpacing.hGapXs,
                    Text('Ubah titik'),
                  ],
                ),
              ),
            ),
          ],
          if (errors.location != null) ...[
            AppSpacing.vGap50,
            Text(
              errors.location!,
              style: theme.typeScale.bodySmall.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          AppSpacing.vGap200,
          AppTextField(
            label: 'Nama lokasi',
            variant: AppTextFieldVariant.outlined,
            controller: locationNameController,
            enabled: enabled,
            maxLength: ShiftFormValues.textMax,
            showCounter: false,
            errorText: errors.locationName,
            textInputAction: TextInputAction.done,
            onChanged: onLocationNameChanged,
          ),
          AppSpacing.vGap200,
          ShiftRadiusSelector(
            radiusText: values.radiusText,
            isCustom: state.isCustomRadius,
            enabled: enabled,
            errorText: errors.radius,
            onPreset: onRadiusPreset,
            onCustom: onRadiusCustom,
            onTextChanged: onRadiusText,
          ),
        ],
      ],
    );
  }
}
