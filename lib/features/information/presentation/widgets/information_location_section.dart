import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';

/// Organism seksi lokasi kegiatan dan titik peta interaktif.
class InformationLocationSection extends StatelessWidget {
  /// Membuat instance [InformationLocationSection].
  const InformationLocationSection({
    required this.eventLocationController,
    required this.eventLocationFocusNode,
    required this.isSubmitting,
    required this.isResolvingLocation,
    required this.onLocationNameChanged,
    required this.onPickLocation,
    required this.onClearLocation,
    this.reverseGeocodeService,
    super.key,
  });

  /// Controller untuk input nama lokasi kegiatan.
  final TextEditingController eventLocationController;

  /// FocusNode untuk input nama lokasi kegiatan.
  final FocusNode eventLocationFocusNode;

  /// Status proses submit formulir.
  final bool isSubmitting;

  /// Status proses deteksi GPS atau resolusi peta.
  final bool isResolvingLocation;

  /// Callback saat teks nama lokasi berubah.
  final ValueChanged<String> onLocationNameChanged;

  /// Callback untuk memicu modal pemilihan lokasi (GPS / Peta).
  final VoidCallback onPickLocation;

  /// Callback untuk menghapus koordinat lokasi yang terpasang.
  final VoidCallback onClearLocation;

  /// Layanan opsional untuk reverse geocoding alamat fisik dari koordinat.
  final ReverseGeocodeService? reverseGeocodeService;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return AppFormSection.uncontained(
      title: 'Lokasi kegiatan dan titik peta',
      subtitle: 'Tentukan nama lokasi dan koordinat kejadian atau acara.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Input Nama Lokasi ───────────────────────────────────────
          BlocSelector<InformationFormCubit, InformationFormState, String?>(
            selector: (state) => state.eventLocationError,
            builder: (context, eventLocationError) {
              return AppTextField(
                label: 'Nama lokasi atau tempat acara',
                variant: AppTextFieldVariant.outlined,
                controller: eventLocationController,
                focusNode: eventLocationFocusNode,
                enabled: !isSubmitting,
                errorText: eventLocationError,
                maxLength: 128,
                textInputAction: TextInputAction.done,
                onChanged: onLocationNameChanged,
              );
            },
          ),
          AppSpacing.vGap200,

          // ── Pratinjau Titik Lokasi & Peta Statis ────────────────────
          BlocSelector<
            InformationFormCubit,
            InformationFormState,
            ({double? lat, double? lng, bool hasLocation})
          >(
            selector: (state) => (
              lat: state.latitude,
              lng: state.longitude,
              hasLocation: state.hasLocation,
            ),
            builder: (context, data) {
              if (!data.hasLocation) {
                return AppFormEmptyPlaceholder(
                  title: 'Belum ada titik lokasi',
                  subtitle:
                      'Ketuk untuk menentukan lokasi saat ini atau '
                      'pilih di peta',
                  vectorIcon: KawaloVectors.mapPin,
                  isLoading: isResolvingLocation,
                  onTap: (isSubmitting || isResolvingLocation)
                      ? null
                      : onPickLocation,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pratinjau AppStaticMap murni berdasarkan koordinat GPS
                  ClipRRect(
                    borderRadius: AppRadius.borderMedium,
                    child: AppStaticMap(
                      latitude: data.lat,
                      longitude: data.lng,
                      markerStyle: AppStaticMapMarkerStyle.dot,
                      reverseGeocodeService: reverseGeocodeService,
                    ),
                  ),
                  AppSpacing.vGap150,

                  // Tombol Aksi: Ubah & Hapus
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.space150,
                      runSpacing: AppSpacing.space100,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppButton(
                          style: AppButtonColor.outlined,
                          onPressed: (isSubmitting || isResolvingLocation)
                              ? null
                              : onPickLocation,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isResolvingLocation)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: AppLoadingIndicator(
                                    size: AppLoadingIndicatorSize.small,
                                  ),
                                )
                              else
                                const AppSvgIcon(
                                  KawaloVectors.edit03,
                                  size: 16,
                                ),
                              AppSpacing.hGapXs,
                              Text(
                                isResolvingLocation
                                    ? 'Mencari lokasi...'
                                    : 'Ubah lokasi',
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          style: AppButtonColor.text,
                          onPressed: isSubmitting ? null : onClearLocation,
                          semanticLabel: 'Hapus titik lokasi',
                          decoration: AppButtonDecoration(
                            foregroundColor: WidgetStatePropertyAll<Color?>(
                              colorScheme.error,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppSvgIcon(KawaloVectors.delete01, size: 16),
                              AppSpacing.hGapXs,
                              Text('Hapus titik'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
