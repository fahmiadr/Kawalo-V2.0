import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/guest_module.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_destination_field.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_guest_type_field.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_host_field.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_identity_fields.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_name_field.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_photo_section.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_photo_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Formulir pendaftaran (create) dan pembaruan (update) data tamu
/// berbasis Material 3 Expressive Fullscreen Dialog.
class GuestFormDialog extends StatefulWidget {
  /// Membuat instance [GuestFormDialog].
  const GuestFormDialog({super.key, this.cubit, this.mediaPickerService});

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
      final created = context.read<GuestModule>().createGuestFormCubit(
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

    final (cubit, isInternal) = GuestFormDialog._resolveCubitFromContext(
      context,
    );
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
      picked = await _mediaPicker.pickMultiImagesFromGallery(limit: 1);
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
    final colorScheme = AppTheme.of(context).colorScheme;

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
            AppSnackbar.show(context, message: state.errorMessage!);
          }
        },
        child:
            BlocSelector<
              GuestFormCubit,
              GuestFormState,
              ({bool isSuccess, bool isDirty, bool isSubmitting, bool isCreate})
            >(
              selector: (state) => (
                isSuccess: state.isSuccess,
                isDirty: state.isDirty,
                isSubmitting: state.isSubmitting,
                isCreate: state.isCreateMode,
              ),
              builder: (popContext, record) {
                return PopScope(
                  canPop:
                      _isDiscarding ||
                      record.isSuccess ||
                      (!record.isDirty && !record.isSubmitting),
                  onPopInvokedWithResult: (didPop, _) async {
                    if (didPop || record.isSubmitting) return;
                    final confirmed = await GuestFormDialog._confirmDiscard(
                      popContext,
                    );
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
                                  _buildIdentitySection(cubit, isSubmitting),

                                  AppSpacing.vGap300,

                                  // ── SEKSI 2: TUJUAN & DETAIL KUNJUNGAN ───────
                                  _buildVisitSection(cubit, isSubmitting),

                                  AppSpacing.vGap300,

                                  // ── SEKSI 3: DOKUMENTASI FOTO TAMU ───────────
                                  AppFormSection.uncontained(
                                    title: 'Dokumentasi foto tamu',
                                    subtitle:
                                        'Lampiran foto identitas atau wajah tamu '
                                        'pengunjung (opsional).',
                                    child: GuestFormPhotoSection(
                                      cubit: cubit,
                                      isSubmitting: isSubmitting,
                                      onPickPhoto: () =>
                                          _handlePickPhoto(cubit),
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

  Widget _buildIdentitySection(GuestFormCubit cubit, bool isSubmitting) {
    return AppFormSection(
      title: 'Informasi tamu & identitas',
      subtitle:
          'Data diri dan verifikasi tanda pengenal '
          'pengunjung.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Nama Tamu
          GuestFormNameField(
            cubit: cubit,
            controller: _nameController,
            focusNode: _nameFocusNode,
            identityNumberFocusNode: _identityNumberFocusNode,
            addressFocusNode: _addressFocusNode,
          ),
          AppSpacing.vGap200,

          // Dropdown Tipe Tamu
          GuestFormGuestTypeField(
            cubit: cubit,
            shimmerController: _shimmerController,
          ),
          AppSpacing.vGap200,

          // Seksi Jenis & Nomor Identitas
          GuestFormIdentityFields(
            cubit: cubit,
            identityNumberController: _identityNumberController,
            identityNumberFocusNode: _identityNumberFocusNode,
            addressFocusNode: _addressFocusNode,
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
            onSubmitted: (_) => _guestNumberFocusNode.requestFocus(),
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
            onSubmitted: (_) => _purposeFocusNode.requestFocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitSection(GuestFormCubit cubit, bool isSubmitting) {
    return AppFormSection(
      title: 'Tujuan & detail kunjungan',
      subtitle:
          'Informasi tuan rumah, tujuan, dan '
          'destinasi kunjungan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tuan Rumah (Warga)
          GuestFormHostField(
            cubit: cubit,
            shimmerController: _shimmerController,
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
            onSubmitted: (_) => _destinationFocusNode.requestFocus(),
          ),
          AppSpacing.vGap200,

          // Input Destinasi Tujuan
          GuestFormDestinationField(
            cubit: cubit,
            controller: _destinationController,
            focusNode: _destinationFocusNode,
          ),
        ],
      ),
    );
  }
}
