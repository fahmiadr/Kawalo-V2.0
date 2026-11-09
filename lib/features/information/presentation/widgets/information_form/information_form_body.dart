import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_document_section.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form/information_form_media_actions.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_location_section.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photos_section.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_publication_section.dart';

/// Scaffold berisi seksi-seksi formulir informasi beserta overlay pemuatan.
class InformationFormBody extends StatelessWidget {
  /// Membuat instance [InformationFormBody].
  const InformationFormBody({
    required this.cubit,
    required this.isCreate,
    required this.scrollController,
    required this.titleController,
    required this.textController,
    required this.eventLocationController,
    required this.titleFocusNode,
    required this.textFocusNode,
    required this.eventLocationFocusNode,
    required this.onPickPhoto,
    required this.onPickDocument,
    required this.onPickLocation,
    this.reverseGeocodeService,
    super.key,
  });

  /// Cubit formulir yang menerima perubahan input.
  final InformationFormCubit cubit;

  /// Apakah formulir dalam mode posting baru (bukan edit).
  final bool isCreate;

  /// Controller scroll untuk auto-scroll saat keyboard muncul.
  final ScrollController scrollController;

  /// Controller judul publikasi.
  final TextEditingController titleController;

  /// Controller isi publikasi.
  final TextEditingController textController;

  /// Controller nama lokasi kejadian.
  final TextEditingController eventLocationController;

  /// Focus node judul publikasi.
  final FocusNode titleFocusNode;

  /// Focus node isi publikasi.
  final FocusNode textFocusNode;

  /// Focus node nama lokasi kejadian.
  final FocusNode eventLocationFocusNode;

  /// Dipanggil saat pengguna memilih untuk menambah foto.
  final VoidCallback onPickPhoto;

  /// Dipanggil saat pengguna memilih untuk menambah dokumen.
  final VoidCallback onPickDocument;

  /// Dipanggil saat pengguna memilih untuk menentukan lokasi.
  final VoidCallback onPickLocation;

  /// Layanan reverse geocoding opsional untuk pratinjau lokasi.
  final ReverseGeocodeService? reverseGeocodeService;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: BlocSelector<InformationFormCubit, InformationFormState, bool>(
        selector: (state) => state.isSubmitting,
        builder: (context, isSubmitting) {
          final overlayMsg = isCreate
              ? 'Mempublikasikan informasi...'
              : 'Menyimpan perubahan informasi...';

          return AppLoadingOverlay(
            isLoading: isSubmitting,
            message: overlayMsg,
            child: AppKeyboardInsetsPadding(
              child: SingleChildScrollView(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(
                  left: AppSpacing.space200,
                  right: AppSpacing.space200,
                  top: AppSpacing.space150,
                  bottom: AppSpacing.space800 * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── SEKSI 1: DETAIL PUBLIKASI & KATEGORI ────
                    RepaintBoundary(
                      child: InformationPublicationSection(
                        titleController: titleController,
                        textController: textController,
                        titleFocusNode: titleFocusNode,
                        textFocusNode: textFocusNode,
                        isSubmitting: isSubmitting,
                        onTitleChanged: cubit.onTitleChanged,
                        onTextChanged: cubit.onTextChanged,
                        onFeedTypeChanged: cubit.onFeedTypeChanged,
                      ),
                    ),

                    AppSpacing.vGap400,

                    // ── SEKSI 2: DOKUMENTASI FOTO ────────────────
                    RepaintBoundary(
                      child: InformationPhotosSection(
                        isSubmitting: isSubmitting,
                        onPickPhoto: onPickPhoto,
                        onClearAll: () =>
                            clearAllInformationFormPhotos(context, cubit),
                        onTapPhoto: (index) =>
                            viewInformationFormPhoto(context, cubit, index),
                        onRemovePhoto: cubit.onRemovePhoto,
                        onMoreOptions: (index) =>
                            showInformationFormPhotoActionMenu(
                              context,
                              cubit,
                              index,
                            ),
                      ),
                    ),

                    AppSpacing.vGap400,

                    // ── SEKSI 3: DOKUMEN LAMPIRAN ────────
                    RepaintBoundary(
                      child: InformationDocumentSection(
                        isSubmitting: isSubmitting,
                        onPickDocument: onPickDocument,
                        onClearDocument: cubit.onClearDocumentMedia,
                      ),
                    ),

                    AppSpacing.vGap400,

                    // ── SEKSI 4: LOKASI KEJADIAN & PETA ─────────
                    BlocSelector<
                      InformationFormCubit,
                      InformationFormState,
                      bool
                    >(
                      selector: (state) => state.isResolvingLocation,
                      builder: (context, isResolvingLocation) {
                        return RepaintBoundary(
                          child: InformationLocationSection(
                            eventLocationController: eventLocationController,
                            eventLocationFocusNode: eventLocationFocusNode,
                            isSubmitting: isSubmitting,
                            isResolvingLocation: isResolvingLocation,
                            onLocationNameChanged: cubit.onEventLocationChanged,
                            onPickLocation: onPickLocation,
                            onClearLocation: cubit.onClearLocationCoordinates,
                            reverseGeocodeService: reverseGeocodeService,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
