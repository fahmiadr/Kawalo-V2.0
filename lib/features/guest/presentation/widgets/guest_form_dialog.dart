import 'dart:async';
import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_form_chip_group.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_form_field_slot.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_morphing_surface.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';
import 'package:kawalo_mobile/features/guest/guest_module.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/app_dropdown_menu.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_photo_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Formulir pendaftaran (create) dan pembaruan (update) data tamu
/// berbasis Material 3 Expressive Fullscreen Dialog.
class GuestFormDialog extends StatefulWidget {
  /// Membuat instance [GuestFormDialog].
  const GuestFormDialog({
    super.key,
    this.cubit,
    this.mediaPickerService,
  });

  /// Instance [GuestFormCubit] opsional untuk injeksi atau pengujian.
  final GuestFormCubit? cubit;

  /// Layanan opsional untuk pemilihan media foto (kamera & galeri).
  final MediaPickerService? mediaPickerService;

  /// Menampilkan dialog penambahan (pendaftaran) tamu baru.
  static Future<GuestItemEntity?> showCreate(
    BuildContext context, {
    GuestFormCubit? formCubit,
    GuestCubit? guestCubit,
    MediaPickerService? mediaPickerService,
  }) {
    return show(
      context: context,
      cubit: formCubit,
      guestCubit: guestCubit,
      mediaPickerService: mediaPickerService,
    );
  }

  /// Menampilkan dialog pembaruan (edit) data tamu yang sudah ada.
  static Future<GuestItemEntity?> showUpdate(
    BuildContext context, {
    required GuestItemEntity item,
    GuestFormCubit? formCubit,
    GuestCubit? guestCubit,
    MediaPickerService? mediaPickerService,
  }) {
    return show(
      context: context,
      initialItem: item,
      cubit: formCubit,
      guestCubit: guestCubit,
      mediaPickerService: mediaPickerService,
    );
  }

  /// Menampilkan dialog formulir tamu dalam mode fullscreen dialog.
  static Future<GuestItemEntity?> show({
    required BuildContext context,
    GuestItemEntity? initialItem,
    GuestFormCubit? cubit,
    GuestCubit? guestCubit,
    MediaPickerService? mediaPickerService,
  }) async {
    final (resolvedCubit, isInternal) = cubit != null
        ? (cubit, false)
        : _resolveCubitFromContext(context, initialItem: initialItem);
    final isCreate = resolvedCubit.state.isCreateMode;
    final title = isCreate ? 'Tambah tamu' : 'Edit data tamu';

    AuthSessionEntity? session;
    try {
      session = context.read<UserSessionCubit?>()?.state;
    } on Object catch (_) {}

    try {
      final result = await AppDialog.showFullScreen<GuestItemEntity>(
        context,
        title: title,
        action: BlocSelector<GuestFormCubit, GuestFormState, bool>(
          bloc: resolvedCubit,
          selector: (state) => state.canPressSubmit,
          builder: (actionContext, canPressSubmit) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space100),
              child: AppButton(
                style: AppButtonColor.text,
                onPressed: canPressSubmit
                    ? () {
                        final activeSession =
                            actionContext.read<UserSessionCubit?>()?.state ??
                                session;
                        resolvedCubit.submit(session: activeSession);
                      }
                    : null,
                child: const Text('Simpan'),
              ),
            );
          },
        ),
        body: GuestFormDialog(
          cubit: resolvedCubit,
          mediaPickerService: mediaPickerService,
        ),
      );

      if (result != null && guestCubit != null) {
        if (isCreate) {
          guestCubit.onGuestCreated(result);
        } else {
          guestCubit.onGuestUpdated(result);
        }
        unawaited(guestCubit.refreshGuests());
      }

      return result;
    } finally {
      if (isInternal) {
        await resolvedCubit.close();
      }
    }
  }

  static (GuestFormCubit, bool) _resolveCubitFromContext(
    BuildContext context, {
    GuestItemEntity? initialItem,
  }) {
    try {
      final existing = context.read<GuestFormCubit>();
      return (existing, false);
    } on Object catch (_) {
      final apiClient = context.read<ApiClient>();
      final isar = context.read<Isar>();

      final created = GuestModule.createGuestFormCubit(
        apiClient: apiClient,
        isar: isar,
        initialItem: initialItem,
      );
      return (created, true);
    }
  }

  static Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Buang perubahan?',
      message: 'Data tamu yang belum disimpan akan hilang.',
      cancelText: 'Lanjut mengisi',
      confirmText: 'Buang',
    );
    return confirmed ?? false;
  }

  @override
  State<GuestFormDialog> createState() => _GuestFormDialogState();
}

class _GuestFormDialogState extends State<GuestFormDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _destinationController;
  late final TextEditingController _identityNumberController;
  late final TextEditingController _guestNumberController;
  late final TextEditingController _purposeController;
  late final TextEditingController _addressController;

  late final FocusNode _nameFocusNode;
  late final FocusNode _destinationFocusNode;
  late final FocusNode _identityNumberFocusNode;
  late final FocusNode _guestNumberFocusNode;
  late final FocusNode _purposeFocusNode;
  late final FocusNode _addressFocusNode;

  late final ScrollController _scrollController;
  late final AnimationController _shimmerController;
  late final MediaPickerService _mediaPicker;

  GuestFormCubit? _internalCubit;
  bool _isDiscarding = false;
  int _lastValidationAttempt = 0;

  @override
  void initState() {
    super.initState();
    _mediaPicker = widget.mediaPickerService ?? DefaultMediaPickerService();
    _scrollController = ScrollController();

    _nameController = TextEditingController();
    _destinationController = TextEditingController();
    _identityNumberController = TextEditingController();
    _guestNumberController = TextEditingController();
    _purposeController = TextEditingController();
    _addressController = TextEditingController();

    _nameFocusNode = FocusNode();
    _destinationFocusNode = FocusNode();
    _identityNumberFocusNode = FocusNode();
    _guestNumberFocusNode = FocusNode();
    _purposeFocusNode = FocusNode();
    _addressFocusNode = FocusNode();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = _resolveCubit(context);
    final state = cubit.state;

    if (_nameController.text != state.name) {
      _nameController.text = state.name;
    }
    if (_destinationController.text != state.destination) {
      _destinationController.text = state.destination;
    }
    if (_identityNumberController.text != state.identityNumber) {
      _identityNumberController.text = state.identityNumber;
    }
    if (_guestNumberController.text != state.guestNumber) {
      _guestNumberController.text = state.guestNumber;
    }
    if (_purposeController.text != state.purpose) {
      _purposeController.text = state.purpose;
    }
    if (_addressController.text != state.address) {
      _addressController.text = state.address;
    }

    _updateShimmerAnimation(state);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _identityNumberController.dispose();
    _guestNumberController.dispose();
    _purposeController.dispose();
    _addressController.dispose();

    _nameFocusNode.dispose();
    _destinationFocusNode.dispose();
    _identityNumberFocusNode.dispose();
    _guestNumberFocusNode.dispose();
    _purposeFocusNode.dispose();
    _addressFocusNode.dispose();

    _scrollController.dispose();
    _shimmerController.dispose();
    _internalCubit?.close();
    super.dispose();
  }

  void _updateShimmerAnimation([GuestFormState? state]) {
    final s = state ?? _resolveCubit(context).state;
    final isLoading = s.isLoadingMasterTypes || s.isLoadingMasterHosts;
    final isReducedMotion = AppMotion.isReducedMotion(context);

    if (isLoading && !isReducedMotion) {
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
    } else {
      if (_shimmerController.isAnimating) {
        _shimmerController.stop();
      }
    }
  }

  GuestFormCubit _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit!;
    if (_internalCubit != null) return _internalCubit!;

    final (cubit, isInternal) =
        GuestFormDialog._resolveCubitFromContext(context);
    if (isInternal) {
      _internalCubit = cubit;
    }
    return cubit;
  }

  Future<void> _handlePickPhoto(GuestFormCubit cubit) async {
    final source = await GuestPhotoSourceBottomSheet.show(context);
    if (source == null || !mounted) return;

    var picked = <AppMediaFile>[];
    if (source == GuestPhotoSource.camera) {
      picked = await _mediaPicker.captureMultiImagesFromCamera(
        context,
        maxPhotos: 1,
      );
    } else {
      picked = await _mediaPicker.pickMultiImagesFromGallery(
        limit: 1,
      );
    }

    if (picked.isNotEmpty && mounted) {
      final file = picked.first;
      final mediaItem = InformationFormMediaItem.fromAppMediaFile(file);
      cubit.onPhotoMediaChanged(mediaItem);
    }
  }

  void _handleValidationFocus(GuestFormState state) {
    if (state.validationAttempt > _lastValidationAttempt) {
      _lastValidationAttempt = state.validationAttempt;
      final firstInvalid = state.firstInvalidField;
      if (firstInvalid == 'name') {
        _nameFocusNode.requestFocus();
      } else if (firstInvalid == 'identityNumber') {
        _identityNumberFocusNode.requestFocus();
      } else if (firstInvalid == 'destination') {
        _destinationFocusNode.requestFocus();
      } else if (firstInvalid == 'guestNumber') {
        _guestNumberFocusNode.requestFocus();
      } else if (firstInvalid == 'purpose') {
        _purposeFocusNode.requestFocus();
      } else if (firstInvalid == 'address') {
        _addressFocusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final m3eTheme = M3ETheme.of(context);

    return BlocProvider<GuestFormCubit>.value(
      value: cubit,
      child: BlocListener<GuestFormCubit, GuestFormState>(
        listener: (context, state) {
          _updateShimmerAnimation(state);
          _handleValidationFocus(state);

          if (state.status == GuestFormStatus.success &&
              state.createdOrUpdatedItem != null) {
            Navigator.of(context).pop(state.createdOrUpdatedItem);
          } else if (state.status == GuestFormStatus.failure &&
              state.errorMessage != null) {
            AppSnackbar.show(
              context,
              message: state.errorMessage!,
            );
          }
        },
        child: BlocSelector<GuestFormCubit, GuestFormState,
            ({bool isSuccess, bool isDirty, bool isSubmitting, bool isCreate})>(
          selector: (state) => (
            isSuccess: state.isSuccess,
            isDirty: state.isDirty,
            isSubmitting: state.isSubmitting,
            isCreate: state.isCreateMode,
          ),
          builder: (popContext, record) {
            return PopScope(
              canPop: _isDiscarding ||
                  record.isSuccess ||
                  (!record.isDirty && !record.isSubmitting),
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop || record.isSubmitting) return;
                final confirmed =
                    await GuestFormDialog._confirmDiscard(popContext);
                if (confirmed && popContext.mounted) {
                  setState(() => _isDiscarding = true);
                  Navigator.of(popContext).pop();
                }
              },
              child: Scaffold(
                backgroundColor: colorScheme.surface,
                resizeToAvoidBottomInset: false,
                body: BlocSelector<GuestFormCubit, GuestFormState, bool>(
                  selector: (state) => state.isSubmitting,
                  builder: (context, isSubmitting) {
                    final overlayMsg = record.isCreate
                        ? 'Mendaftarkan tamu baru...'
                        : 'Menyimpan perubahan data tamu...';

                    return AppLoadingOverlay(
                      isLoading: isSubmitting,
                      message: overlayMsg,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── SEKSI 1: INFORMASI TAMU & IDENTITAS ──────
                              AppFormSection(
                                title: 'Informasi tamu & identitas',
                                subtitle:
                                    'Data diri dan verifikasi tanda pengenal '
                                    'pengunjung.',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Input Nama Tamu
                                    BlocSelector<
                                        GuestFormCubit,
                                        GuestFormState,
                                        ({
                                          String? error,
                                          bool enabled,
                                          bool hasIdentityType,
                                          int validationAttempt,
                                        })>(
                                      selector: (state) => (
                                        error: state.nameError,
                                        enabled: !state.isSubmitting,
                                        hasIdentityType: state.hasIdentityType,
                                        validationAttempt:
                                            state.validationAttempt,
                                      ),
                                      builder: (context, nameState) {
                                        final showError =
                                            nameState.validationAttempt > 0 ||
                                                cubit.state.name.isNotEmpty;
                                        return AppTextField(
                                          label: 'Nama tamu',
                                          isRequired: true,
                                          variant: AppTextFieldVariant.outlined,
                                          controller: _nameController,
                                          focusNode: _nameFocusNode,
                                          enabled: nameState.enabled,
                                          errorText: showError
                                              ? nameState.error
                                              : null,
                                          textInputAction: TextInputAction.next,
                                          onChanged: cubit.onNameChanged,
                                          onSubmitted: (_) {
                                            if (nameState.hasIdentityType &&
                                                nameState.enabled) {
                                              _identityNumberFocusNode
                                                  .requestFocus();
                                            } else {
                                              _addressFocusNode.requestFocus();
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    AppSpacing.vGap200,

                                    // Dropdown Tipe Tamu
                                    _buildMasterGuestTypeSection(
                                      context,
                                      cubit,
                                      m3eTheme,
                                    ),
                                    AppSpacing.vGap200,

                                    // Seksi Jenis & Nomor Identitas
                                    _buildIdentitySection(
                                      context,
                                      cubit,
                                      m3eTheme,
                                    ),
                                    AppSpacing.vGap200,

                                    // Input Alamat Asal
                                    AppTextField(
                                      label: 'Alamat asal',
                                      variant: AppTextFieldVariant.outlined,
                                      controller: _addressController,
                                      focusNode: _addressFocusNode,
                                      enabled: !isSubmitting,
                                      textInputAction: TextInputAction.next,
                                      onChanged: cubit.onAddressChanged,
                                      onSubmitted: (_) =>
                                          _guestNumberFocusNode.requestFocus(),
                                    ),
                                    AppSpacing.vGap200,

                                    // Input Nomor Tamu / Plat Kendaraan
                                    AppTextField(
                                      label: 'Nomor tamu / Plat kendaraan',
                                      variant: AppTextFieldVariant.outlined,
                                      controller: _guestNumberController,
                                      focusNode: _guestNumberFocusNode,
                                      enabled: !isSubmitting,
                                      textInputAction: TextInputAction.next,
                                      onChanged: cubit.onGuestNumberChanged,
                                      onSubmitted: (_) =>
                                          _purposeFocusNode.requestFocus(),
                                    ),
                                  ],
                                ),
                              ),

                              AppSpacing.vGap300,

                              // ── SEKSI 2: TUJUAN & DETAIL KUNJUNGAN ───────
                              AppFormSection(
                                title: 'Tujuan & detail kunjungan',
                                subtitle: 'Informasi tuan rumah, tujuan, dan '
                                    'destinasi kunjungan.',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Tuan Rumah (Warga)
                                    _buildMasterHostSection(
                                      context,
                                      cubit,
                                      m3eTheme,
                                    ),
                                    AppSpacing.vGap200,

                                    // Input Keperluan Kunjungan
                                    AppTextField(
                                      label: 'Keperluan kunjungan',
                                      variant: AppTextFieldVariant.outlined,
                                      controller: _purposeController,
                                      focusNode: _purposeFocusNode,
                                      enabled: !isSubmitting,
                                      textInputAction: TextInputAction.next,
                                      onChanged: cubit.onPurposeChanged,
                                      onSubmitted: (_) =>
                                          _destinationFocusNode.requestFocus(),
                                    ),
                                    AppSpacing.vGap200,

                                    // Input Destinasi Tujuan
                                    BlocSelector<
                                        GuestFormCubit,
                                        GuestFormState,
                                        ({
                                          String? error,
                                          bool enabled,
                                          int validationAttempt,
                                        })>(
                                      selector: (state) => (
                                        error: state.destinationError,
                                        enabled: !state.isSubmitting,
                                        validationAttempt:
                                            state.validationAttempt,
                                      ),
                                      builder: (context, destState) {
                                        final showError =
                                            destState.validationAttempt > 0 ||
                                                cubit.state.destination
                                                    .isNotEmpty;
                                        return AppTextField(
                                          label: 'Destinasi tujuan *',
                                          variant: AppTextFieldVariant.outlined,
                                          controller: _destinationController,
                                          focusNode: _destinationFocusNode,
                                          enabled: destState.enabled,
                                          errorText: showError
                                              ? destState.error
                                              : null,
                                          textInputAction: TextInputAction.done,
                                          onChanged: cubit.onDestinationChanged,
                                          onSubmitted: (_) {
                                            if (destState.enabled) {
                                              cubit.submit();
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              AppSpacing.vGap300,

                              // ── SEKSI 3: DOKUMENTASI FOTO TAMU ───────────
                              AppFormSection.uncontained(
                                title: 'Dokumentasi foto tamu',
                                subtitle:
                                    'Lampiran foto identitas atau wajah tamu '
                                    'pengunjung (opsional).',
                                child: _buildPhotoSection(
                                  context,
                                  cubit,
                                  theme,
                                  isSubmitting,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdentitySection(
    BuildContext context,
    GuestFormCubit cubit,
    M3EThemeData theme,
  ) {
    return BlocSelector<
        GuestFormCubit,
        GuestFormState,
        ({
          String? identityType,
          String? identityNumberError,
          bool isBusy,
          int validationAttempt,
        })>(
      selector: (state) => (
        identityType: state.identityType,
        identityNumberError: state.identityNumberError,
        isBusy: state.isSubmitting,
        validationAttempt: state.validationAttempt,
      ),
      builder: (context, idState) {
        final hasIdentityType =
            idState.identityType != null && idState.identityType!.isNotEmpty;
        _identityNumberFocusNode.canRequestFocus =
            hasIdentityType && !idState.isBusy;
        _identityNumberFocusNode.skipTraversal =
            !hasIdentityType || idState.isBusy;

        final showError = idState.validationAttempt > 0 ||
            cubit.state.identityNumber.isNotEmpty;

        final chipItems = [
          AppFormChipItem<String?>(
            value: null,
            label: 'Tanpa Identitas',
            selected: idState.identityType == null,
          ),
          ...GuestIdentityType.values.map(
            (type) => AppFormChipItem<String?>(
              value: type.code,
              label: type.label,
              selected: idState.identityType == type.code,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormChipGroup<String?>(
              label: 'Jenis identitas',
              layout: AppFormChipGroupLayout.wrap,
              items: chipItems,
              selectedValue: idState.identityType,
              enabled: !idState.isBusy,
              onSelected: (val) {
                if (val == idState.identityType) return;
                cubit.onIdentityTypeChanged(val);
                if (val == null) {
                  _identityNumberController.clear();
                } else {
                  _identityNumberFocusNode.requestFocus();
                }
              },
            ),
            AppSpacing.vGap200,
            AppTextField(
              label: hasIdentityType
                  ? 'Nomor identitas (${idState.identityType}) *'
                  : 'Nomor identitas',
              variant: AppTextFieldVariant.outlined,
              controller: _identityNumberController,
              focusNode: _identityNumberFocusNode,
              enabled: !idState.isBusy && hasIdentityType,
              errorText: showError ? idState.identityNumberError : null,
              textInputAction: TextInputAction.next,
              onChanged: cubit.onIdentityNumberChanged,
              onSubmitted: (_) => _addressFocusNode.requestFocus(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMasterGuestTypeSection(
    BuildContext context,
    GuestFormCubit cubit,
    M3EThemeData theme,
  ) {
    return BlocSelector<
        GuestFormCubit,
        GuestFormState,
        ({
          List<MasterGuestTypeEntity> masterTypes,
          bool isLoading,
          String? masterTypesError,
          String guestType,
          String? typeError,
          bool isBusy,
          int validationAttempt,
        })>(
      selector: (state) => (
        masterTypes: state.masterTypes,
        isLoading: state.isLoadingMasterTypes,
        masterTypesError: state.masterTypesError,
        guestType: state.guestType,
        typeError: state.typeError,
        isBusy: state.isSubmitting,
        validationAttempt: state.validationAttempt,
      ),
      builder: (context, typeState) {
        final showError =
            typeState.validationAttempt > 0 || typeState.guestType.isNotEmpty;

        Widget inputChild;
        if (typeState.isLoading) {
          inputChild = _buildDropdownSkeleton(context);
        } else if (typeState.masterTypesError != null &&
            typeState.masterTypes.isEmpty) {
          inputChild = _buildMasterErrorWithRetry(
            context,
            message: 'Gagal memuat tipe tamu',
            tooltipMessage: 'Coba lagi memuat tipe tamu',
            onRetry: cubit.loadMasterGuestTypes,
          );
        } else {
          inputChild = AppDropdownMenu<String>(
            items: typeState.masterTypes
                .map(
                  (type) => AppDropdownItem<String>(
                    value: type.name,
                    label: type.name,
                    selected: typeState.guestType == type.name,
                  ),
                )
                .toList(),
            singleSelect: true,
            enabled: !typeState.isBusy,
            fieldStyle: const AppDropdownFieldStyle(
              hintText: 'Pilih tipe tamu',
              borderRadius: AppRadius.borderMedium,
            ),
            onSelectionChanged: (items) {
              cubit.onGuestTypeChanged(
                items.isNotEmpty ? items.first.value : '',
              );
            },
          );
        }

        return AppFormFieldSlot(
          label: 'Tipe tamu*',
          errorText: (showError && typeState.typeError != null)
              ? typeState.typeError
              : null,
          child: inputChild,
        );
      },
    );
  }

  Widget _buildMasterHostSection(
    BuildContext context,
    GuestFormCubit cubit,
    M3EThemeData theme,
  ) {
    return BlocSelector<
        GuestFormCubit,
        GuestFormState,
        ({
          List<GroupMemberEntity> masterHosts,
          bool isLoading,
          String? masterHostsError,
          String? hostEmail,
          bool isBusy,
        })>(
      selector: (state) => (
        masterHosts: state.masterHosts,
        isLoading: state.isLoadingMasterHosts,
        masterHostsError: state.masterHostsError,
        hostEmail: state.hostEmail,
        isBusy: state.isSubmitting,
      ),
      builder: (context, hostState) {
        Widget inputChild;
        if (hostState.isLoading) {
          inputChild = _buildDropdownSkeleton(context);
        } else if (hostState.masterHostsError != null &&
            hostState.masterHosts.isEmpty) {
          inputChild = _buildMasterErrorWithRetry(
            context,
            message: 'Gagal memuat daftar warga',
            tooltipMessage: 'Coba lagi memuat daftar warga',
            onRetry: cubit.loadMasterHosts,
          );
        } else {
          inputChild = AppDropdownMenu<String>(
            items: hostState.masterHosts
                .map(
                  (host) => AppDropdownItem<String>(
                    value: host.email,
                    label: host.displayLabel,
                    selected: hostState.hostEmail == host.email,
                  ),
                )
                .toList(),
            singleSelect: true,
            searchEnabled: true,
            enabled: !hostState.isBusy,
            fieldStyle: const AppDropdownFieldStyle(
              hintText: 'Pilih tuan rumah',
              borderRadius: AppRadius.borderMedium,
            ),
            onSelectionChanged: (items) {
              cubit.onHostEmailChanged(
                items.isNotEmpty ? items.first.value : null,
              );
            },
          );
        }

        return AppFormFieldSlot(
          label: 'Bertemu dengan (Tuan rumah)',
          child: inputChild,
        );
      },
    );
  }

  Widget _buildPhotoSection(
    BuildContext context,
    GuestFormCubit cubit,
    M3EThemeData theme,
    bool isSubmitting,
  ) {
    final colorScheme = theme.colorScheme;

    return BlocSelector<GuestFormCubit, GuestFormState,
        ({InformationFormMediaItem? photoMedia, String? photoUrl})>(
      selector: (state) => (
        photoMedia: state.photoMedia,
        photoUrl: state.photoUrl,
      ),
      builder: (context, photoState) {
        final photoMedia = photoState.photoMedia;
        final photoUrl = photoState.photoUrl;
        final hasPhoto = photoMedia != null ||
            (photoUrl != null && photoUrl.trim().isNotEmpty);

        if (!hasPhoto) {
          return AppFormEmptyPlaceholder(
            title: 'Lampirkan Foto Tamu',
            subtitle: 'Ketuk untuk mengambil foto kamera atau galeri',
            vectorIcon: KawaloVectors.camera01,
            onTap: isSubmitting ? null : () => _handlePickPhoto(cubit),
          );
        }

        // Render photo thumbnail with Hero transition to AppImageViewer
        final displaySource =
            photoMedia != null ? photoMedia.displaySource : photoUrl!;

        Widget imageContent;
        final mediaPath = photoMedia?.path;
        if (photoMedia?.bytes != null) {
          imageContent = Image.memory(
            photoMedia!.bytes!,
            fit: BoxFit.cover,
          );
        } else if (!kIsWeb &&
            mediaPath != null &&
            File(mediaPath).existsSync()) {
          imageContent = Image.file(
            File(mediaPath),
            fit: BoxFit.cover,
          );
        } else if (displaySource.startsWith('http://') ||
            displaySource.startsWith('https://')) {
          imageContent = CachedNetworkImage(
            imageUrl: displaySource,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, __) => const AppImagePlaceholder(
              icon: AppLoadingIndicator(
                size: AppLoadingIndicatorSize.small,
              ),
            ),
            errorWidget: (_, __, ___) => const AppImagePlaceholder(
              iconSize: 24,
            ),
          );
        } else {
          imageContent = const AppImagePlaceholder(
            iconPath: KawaloVectors.images,
            iconSize: 24,
          );
        }

        return AppCard(
          variant: AppCardVariant.outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 180,
                child: AppMorphingSurface(
                  onTap: () {
                    AppImageViewer.show(
                      context,
                      imageUrls: [displaySource],
                      heroTagPrefix: 'guest_form_photo',
                    );
                  },
                  semanticLabel: 'Lihat foto tamu layar penuh',
                  overlay: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Tombol Hapus Silang Cepat di Kanan Atas
                      Positioned(
                        top: AppSpacing.space100,
                        right: AppSpacing.space100,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: AppIconButton(
                            onPressed:
                                isSubmitting ? null : cubit.onRemovePhoto,
                            semanticLabel: 'Hapus foto tamu',
                            size: AppIconButtonSize.xs,
                            decoration: M3EIconButtonDecoration(
                              backgroundColor: WidgetStatePropertyAll(
                                colorScheme.scrim.withValues(alpha: 0.60),
                              ),
                              foregroundColor: const WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              side: WidgetStatePropertyAll(
                                BorderSide(
                                  color: Colors.white.withValues(alpha: 0.30),
                                ),
                              ),
                            ),
                            icon: const AppSvgIcon(
                              KawaloVectors.cancel01,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'guest_form_photo_0',
                    child: imageContent,
                  ),
                ),
              ),
              AppSpacing.vGap150,
              AppButton(
                style: AppButtonColor.outlined,
                enabled: !isSubmitting,
                onPressed: () => _handlePickPhoto(cubit),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppSvgIcon(KawaloVectors.camera01, size: 18),
                    AppSpacing.hGapXs,
                    Text('Ganti Foto'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownSkeleton(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isReducedMotion = AppMotion.isReducedMotion(context);

    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isReducedMotion ? baseColor : null,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: isReducedMotion
          ? null
          : AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [baseColor, highlightColor, baseColor],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _SlidingGradientTransform(
                        slidePercent: _shimmerController.value,
                      ),
                    ).createShader(bounds);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: AppRadius.borderMedium,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMasterErrorWithRetry(
    BuildContext context, {
    required String message,
    required String tooltipMessage,
    required VoidCallback onRetry,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typography.baseline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space150,
        vertical: AppSpacing.space100,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: AppRadius.borderMedium,
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            KawaloVectors.alertCircleFilled,
            color: colorScheme.error,
            size: 18,
          ),
          AppSpacing.hGap100,
          Expanded(
            child: Text(
              message,
              style: typeScale.bodySmall.copyWith(
                color: colorScheme.onErrorContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppTooltip(
            message: tooltipMessage,
            child: AppIconButton(
              onPressed: onRetry,
              semanticLabel: tooltipMessage,
              icon: AppSvgIcon(
                KawaloVectors.reload,
                size: 16,
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}
