import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';
import 'package:kawalo_mobile/features/incident/incident_module.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_location_section.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photo_action_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photo_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photos_section.dart';

/// Formulir pelaporan insiden baru berbasis Material 3 Expressive Fullscreen
/// Dialog, konsisten dan serasi dengan modul guest dan information.
class IncidentFormDialog extends StatefulWidget {
  /// Membuat instance [IncidentFormDialog].
  const IncidentFormDialog({
    super.key,
    this.cubit,
    this.mediaPickerService,
    this.reverseGeocodeService,
  });

  /// Instance [IncidentFormCubit] opsional untuk injeksi atau pengujian.
  final IncidentFormCubit? cubit;

  /// Layanan pemilihan media opsional (kamera & galeri).
  final MediaPickerService? mediaPickerService;

  /// Layanan reverse geocoding opsional untuk peta lokasi (seam pengujian).
  final ReverseGeocodeService? reverseGeocodeService;

  /// Menampilkan dialog penambahan laporan insiden baru.
  static Future<IncidentEntity?> showCreate(
    BuildContext context, {
    IncidentFormCubit? formCubit,
    IncidentListCubit? incidentListCubit,
    MediaPickerService? mediaPickerService,
  }) {
    return show(
      context: context,
      cubit: formCubit,
      incidentListCubit: incidentListCubit,
      mediaPickerService: mediaPickerService,
    );
  }

  /// Menampilkan dialog formulir insiden dalam mode fullscreen dialog.
  static Future<IncidentEntity?> show({
    required BuildContext context,
    IncidentFormCubit? cubit,
    IncidentListCubit? incidentListCubit,
    MediaPickerService? mediaPickerService,
  }) async {
    final (resolvedCubit, isInternal) = cubit != null
        ? (cubit, false)
        : _resolveCubitFromContext(context);
    const title = 'Laporkan insiden';

    AuthSessionEntity? session;
    try {
      session = context.read<UserSessionCubit?>()?.state;
    } on Object catch (_) {}

    try {
      final result = await AppDialog.showFullScreen<IncidentEntity>(
        context,
        title: title,
        bottomActions: [
          BlocSelector<IncidentFormCubit, IncidentFormState, bool>(
            bloc: resolvedCubit,
            selector: (state) => state.canPressSubmit,
            builder: (actionContext, canPressSubmit) {
              return AppButton(
                size: AppButtonSize.md,
                enabled: canPressSubmit,
                onPressed: () {
                  final activeSession =
                      actionContext.read<UserSessionCubit?>()?.state ?? session;
                  resolvedCubit.submit(session: activeSession);
                },
                child: const Text('Kirim'),
              );
            },
          ),
        ],
        body: IncidentFormDialog(
          cubit: resolvedCubit,
          mediaPickerService: mediaPickerService,
        ),
      );

      if (result != null && incidentListCubit != null) {
        incidentListCubit.onIncidentCreated(result);
      }

      return result;
    } finally {
      if (isInternal) {
        await resolvedCubit.close();
      }
    }
  }

  static (IncidentFormCubit, bool) _resolveCubitFromContext(
    BuildContext context,
  ) {
    try {
      final cubit = context.read<IncidentFormCubit>();
      return (cubit, false);
    } on Object catch (_) {
      return (
        context.read<IncidentModule>().createIncidentFormCubit(
          uploadRepository: context.read<UploadRepository>(),
        ),
        true,
      );
    }
  }

  static Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Buang laporan?',
      message: 'Data insiden yang telah diisi belum dikirim dan akan hilang.',
      cancelText: 'Lanjut mengisi',
      confirmText: 'Buang',
    );
    return confirmed ?? false;
  }

  @override
  State<IncidentFormDialog> createState() => _IncidentFormDialogState();
}

class _IncidentFormDialogState extends State<IncidentFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _descriptionFocusNode;
  late final ScrollController _scrollController;
  late final MediaPickerService _mediaPicker;

  IncidentFormCubit? _internalCubit;
  bool _isDiscarding = false;
  int _lastValidationAttempt = 0;

  @override
  void initState() {
    super.initState();
    _mediaPicker = widget.mediaPickerService ?? DefaultMediaPickerService();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _scrollController = ScrollController();
    // Fetch the GPS point once when the form opens; failure keeps the form
    // usable without a location.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_resolveCubit(context).resolveLocation());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = _resolveCubit(context);
    final state = cubit.state;

    if (_titleController.text != state.title) {
      _titleController.text = state.title;
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.text = state.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _scrollController.dispose();
    _internalCubit?.close();
    super.dispose();
  }

  IncidentFormCubit _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit!;
    if (_internalCubit != null) return _internalCubit!;

    final (cubit, isInternal) = IncidentFormDialog._resolveCubitFromContext(
      context,
    );
    if (isInternal) {
      _internalCubit = cubit;
    }
    return cubit;
  }

  void _handleValidationFocus(IncidentFormState state) {
    if (state.validationAttempt > _lastValidationAttempt) {
      _lastValidationAttempt = state.validationAttempt;
      final firstInvalid = state.firstInvalidField;
      if (firstInvalid == 'title') {
        _titleFocusNode.requestFocus();
      } else if (firstInvalid == 'description') {
        _descriptionFocusNode.requestFocus();
      }
    }
  }

  Future<void> _handlePickPhoto(IncidentFormCubit cubit) async {
    final source = await IncidentPhotoSourceBottomSheet.show(context);
    if (source == null || !mounted) return;

    if (cubit.state.photos.length >= 4) {
      AppSnackbar.show(context, message: 'Maksimal 4 foto dapat dilampirkan.');
      return;
    }

    try {
      final remainingSlots = cubit.state.remainingPhotoSlots;
      List<AppMediaFile> files;

      if (source == IncidentPhotoSource.camera) {
        files = await _mediaPicker.captureMultiImagesFromCamera(
          context,
          alreadyAttachedCount: cubit.state.photos.length,
        );
      } else {
        files = await _mediaPicker.pickMultiImagesFromGallery(
          limit: remainingSlots,
        );
      }

      if (files.isNotEmpty && mounted) {
        final items = files.map(IncidentMediaItem.fromAppMediaFile).toList();
        cubit.addPhotos(items);
      }
    } on Object catch (error) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Gagal memilih foto: $error');
      }
    }
  }

  Future<void> _handleClearAllPhotos(IncidentFormCubit cubit) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus semua foto?',
      message: 'Seluruh foto lampiran akan dihapus dari formulir.',
      confirmText: 'Hapus semua',
    );
    if (confirmed == true && mounted) {
      cubit.clearPhotos();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Seluruh foto lampiran telah dihapus.',
        );
      }
    }
  }

  void _showPhotoActionMenu(
    BuildContext context,
    IncidentFormCubit cubit,
    int index,
  ) {
    final photos = cubit.state.photos;
    if (index < 0 || index >= photos.length) return;
    final item = photos[index];

    IncidentPhotoActionBottomSheet.show(
      context,
      item: item,
      index: index,
      totalPhotos: photos.length,
      onViewPhoto: () => AppImageViewer.show(
        context,
        imageUrls: photos.map((p) => p.displaySource).toList(),
        initialIndex: index,
        heroTagPrefix: 'incident_form_photo',
      ),
      onMakePrimary: () => cubit.reorderPhotos(index, 0),
      onMoveLeft: () => cubit.reorderPhotos(index, index - 1),
      onMoveRight: () => cubit.reorderPhotos(index, index + 1),
      onDelete: () => cubit.removePhoto(item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = _resolveCubit(context);

    return BlocProvider<IncidentFormCubit>.value(
      value: cubit,
      child: BlocConsumer<IncidentFormCubit, IncidentFormState>(
        bloc: cubit,
        listener: (context, state) {
          _handleValidationFocus(state);

          if (state.status == IncidentFormStatus.success &&
              state.createdIncident != null) {
            AppSnackbar.show(
              context,
              message: 'Laporan insiden berhasil dikirim!',
            );
            Navigator.of(context).pop(state.createdIncident);
          } else if (state.status == IncidentFormStatus.failure &&
              state.errorMessage != null) {
            AppSnackbar.show(context, message: state.errorMessage!);
          }
        },
        builder: (context, state) {
          final isDirty = state.isDirty;
          final isSuccess = state.isSuccess;

          return PopScope(
            canPop: _isDiscarding || isSuccess || (!isDirty && !state.isBusy),
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop || state.isBusy) return;
              final confirmed = await IncidentFormDialog._confirmDiscard(
                context,
              );
              if (confirmed && context.mounted) {
                setState(() => _isDiscarding = true);
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              resizeToAvoidBottomInset: false,
              body: AppLoadingOverlay(
                isLoading: state.isSubmitting,
                semanticLabel: 'Mengirimkan laporan insiden',
                message: 'Mengirimkan laporan insiden...',
                child: AppKeyboardInsetsPadding(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(
                      left: AppSpacing.space200,
                      right: AppSpacing.space200,
                      top: AppSpacing.space150,
                      bottom: AppSpacing.space800 * 2,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppLayout.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Seksi 1: Kategori Insiden ────────────────────
                            AppFormSection(
                              title: 'Kategori insiden',
                              subtitle:
                                  'Pilih klasifikasi jenis insiden '
                                  'operasional.',
                              child: Wrap(
                                spacing: AppSpacing.space100,
                                runSpacing: AppSpacing.space100,
                                children: IncidentCategory.values.map((cat) {
                                  final isSelected = state.category == cat;
                                  return AppChip(
                                    type: AppChipType.filter,
                                    label: cat.displayName,
                                    selected: isSelected,
                                    onPressed: state.isBusy
                                        ? null
                                        : () {
                                            cubit.updateCategory(cat);
                                          },
                                  );
                                }).toList(),
                              ),
                            ),

                            AppSpacing.vGap300,

                            // ── Seksi 2: Informasi Detail Laporan ────────────
                            AppFormSection(
                              title: 'Detail laporan',
                              subtitle:
                                  'Informasi lengkap mengenai '
                                  'peristiwa yang terjadi.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppTextField(
                                    label: 'Judul laporan',
                                    isRequired: true,
                                    variant: AppTextFieldVariant.outlined,
                                    controller: _titleController,
                                    focusNode: _titleFocusNode,
                                    enabled: !state.isBusy,
                                    errorText:
                                        (state.validationAttempt > 0 ||
                                            state.title.isNotEmpty)
                                        ? state.titleError
                                        : null,
                                    textInputAction: TextInputAction.next,
                                    onChanged: cubit.updateTitle,
                                    onSubmitted: (_) =>
                                        _descriptionFocusNode.requestFocus(),
                                  ),
                                  AppSpacing.vGap200,
                                  AppTextField(
                                    label: 'Deskripsi kejadian',
                                    variant: AppTextFieldVariant.outlined,
                                    controller: _descriptionController,
                                    focusNode: _descriptionFocusNode,
                                    enabled: !state.isBusy,
                                    errorText:
                                        (state.validationAttempt > 0 ||
                                            state.description.isNotEmpty)
                                        ? state.descriptionError
                                        : null,
                                    minLines: 3,
                                    maxLines: 6,
                                    textInputAction: TextInputAction.done,
                                    onChanged: cubit.updateDescription,
                                  ),
                                ],
                              ),
                            ),

                            AppSpacing.vGap300,

                            // ── Seksi 3: Dokumentasi Foto Insiden ────────────
                            IncidentPhotosSection(
                              cubit: cubit,
                              isSubmitting: state.isBusy,
                              onRetryPhoto: (index) {
                                final photos = cubit.state.photos;
                                if (index >= 0 && index < photos.length) {
                                  cubit.retryPhotoUpload(photos[index].id);
                                }
                              },
                              onPickPhoto: () => _handlePickPhoto(cubit),
                              onClearAll: () => _handleClearAllPhotos(cubit),
                              onTapPhoto: (index) {
                                final photos = cubit.state.photos;
                                if (index < 0 || index >= photos.length) return;
                                AppImageViewer.show(
                                  context,
                                  imageUrls: photos
                                      .map((p) => p.displaySource)
                                      .toList(),
                                  initialIndex: index,
                                  heroTagPrefix: 'incident_form_photo',
                                );
                              },
                              onRemovePhoto: (index) {
                                final photos = cubit.state.photos;
                                if (index >= 0 && index < photos.length) {
                                  cubit.removePhoto(photos[index].id);
                                }
                              },
                              onMoreOptions: (index) =>
                                  _showPhotoActionMenu(context, cubit, index),
                            ),

                            AppSpacing.vGap300,

                            // ── Seksi 4: Lokasi Kejadian ─────────────────────
                            IncidentLocationSection(
                              latitude: state.glat,
                              longitude: state.glong,
                              isResolving: state.isResolvingLocation,
                              isBusy: state.isBusy,
                              error: state.locationError,
                              reverseGeocodeService:
                                  widget.reverseGeocodeService,
                              onRefresh: () =>
                                  unawaited(cubit.resolveLocation()),
                              onClear: cubit.clearLocation,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
