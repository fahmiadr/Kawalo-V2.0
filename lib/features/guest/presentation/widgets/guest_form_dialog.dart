import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
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

/// Fields folded into "Detail lain (opsional)"; an invalid one expands it.
const _moreDetailFields = {
  'identityNumber',
  'address',
  'guestNumber',
  'hostName',
  'purpose',
};

/// Create/edit guest form (redesign 2026), shown as a full-screen dialog that
/// covers the bottom bar. Only Nama tamu, Tipe tamu and Tujuan are required
/// (the API requires the same three); the photo is optional and every other
/// field sits in the collapsed "Detail lain (opsional)" section.
class GuestFormDialog extends StatefulWidget {
  const GuestFormDialog({super.key, this.cubit, this.mediaPickerService});

  final GuestFormCubit? cubit;
  final MediaPickerService? mediaPickerService;

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

    AuthSessionEntity? session;
    try {
      session = context.read<UserSessionCubit?>()?.state;
    } on Object catch (_) {}

    try {
      final result = await AppDialog.showFullScreen<GuestItemEntity>(
        context,
        title: isCreate ? 'Tamu Baru' : 'Ubah Data Tamu',
        bottomActions: [
          BlocBuilder<GuestFormCubit, GuestFormState>(
            bloc: resolvedCubit,
            buildWhen: (a, b) =>
                a.canPressSubmit != b.canPressSubmit || a.status != b.status,
            builder: (actionContext, state) {
              final (label, icon) = state.isSubmitting
                  ? ('Menyimpan…', null)
                  : state.isFailure
                  ? ('Coba Simpan Lagi', Icons.refresh_rounded)
                  : (
                      isCreate ? 'Simpan Tamu' : 'Simpan Perubahan',
                      Icons.check_rounded,
                    );
              return AppTaskButton(
                label: label,
                icon: icon,
                tone: KawaloTones.of(actionContext).gst,
                isLoading: state.isSubmitting,
                onPressed: state.canPressSubmit || state.isSubmitting
                    ? () => resolvedCubit.submit(
                        session:
                            actionContext.read<UserSessionCubit?>()?.state ??
                            session,
                      )
                    : null,
              );
            },
          ),
        ],
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
        uploadRepository: context.read<UploadRepository>(),
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
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _identityNumberController = TextEditingController();
  final _guestNumberController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _addressController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _destinationFocusNode = FocusNode();
  final _hostNameFocusNode = FocusNode();
  final _identityNumberFocusNode = FocusNode();
  final _guestNumberFocusNode = FocusNode();
  final _purposeFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  final _scrollController = ScrollController();
  late final AnimationController _shimmerController;
  late final MediaPickerService _mediaPicker;

  GuestFormCubit? _internalCubit;
  bool _isDiscarding = false;
  int _lastValidationAttempt = 0;

  /// Null until the first build decides it from the edited guest.
  bool? _showMore;

  @override
  void initState() {
    super.initState();
    _mediaPicker = widget.mediaPickerService ?? DefaultMediaPickerService();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = _resolveCubit(context).state;

    void sync(TextEditingController c, String value) {
      if (c.text != value) c.text = value;
    }

    sync(_nameController, state.name);
    sync(_destinationController, state.destination);
    sync(_identityNumberController, state.identityNumber);
    sync(_guestNumberController, state.guestNumber);
    sync(_hostNameController, state.hostName);
    sync(_purposeController, state.purpose);
    sync(_addressController, state.address);

    _showMore ??=
        (state.identityType?.isNotEmpty ?? false) ||
        [
          state.identityNumber,
          state.address,
          state.guestNumber,
          state.hostName,
          state.purpose,
        ].any((v) => v.trim().isNotEmpty);

    _updateShimmerAnimation(state);
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _destinationController,
      _identityNumberController,
      _guestNumberController,
      _hostNameController,
      _purposeController,
      _addressController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocusNode,
      _destinationFocusNode,
      _hostNameFocusNode,
      _identityNumberFocusNode,
      _guestNumberFocusNode,
      _purposeFocusNode,
      _addressFocusNode,
    ]) {
      f.dispose();
    }
    _scrollController.dispose();
    _shimmerController.dispose();
    _internalCubit?.close();
    super.dispose();
  }

  void _updateShimmerAnimation(GuestFormState state) {
    if (state.isLoadingMasterTypes && !AppMotion.isReducedMotion(context)) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
    } else if (_shimmerController.isAnimating) {
      _shimmerController.stop();
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

    final picked = source == GuestPhotoSource.camera
        ? await _mediaPicker.captureMultiImagesFromCamera(context, maxPhotos: 1)
        : await _mediaPicker.pickMultiImagesFromGallery(limit: 1);

    if (picked.isNotEmpty && mounted) {
      cubit.onPhotoMediaChanged(
        InformationFormMediaItem.fromAppMediaFile(picked.first),
      );
    }
  }

  void _handleValidationFocus(GuestFormState state) {
    if (state.validationAttempt <= _lastValidationAttempt) return;
    _lastValidationAttempt = state.validationAttempt;
    final firstInvalid = state.firstInvalidField;
    final node = switch (firstInvalid) {
      'name' => _nameFocusNode,
      'destination' => _destinationFocusNode,
      'identityNumber' => _identityNumberFocusNode,
      'guestNumber' => _guestNumberFocusNode,
      'hostName' => _hostNameFocusNode,
      'purpose' => _purposeFocusNode,
      'address' => _addressFocusNode,
      _ => null,
    };
    if (node == null) return;
    if (_moreDetailFields.contains(firstInvalid) && _showMore != true) {
      // The field only exists once the section is open.
      setState(() => _showMore = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) node.requestFocus();
      });
    } else {
      node.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    final tones = KawaloTones.of(context);

    return BlocProvider<GuestFormCubit>.value(
      value: cubit,
      child: BlocListener<GuestFormCubit, GuestFormState>(
        listener: (context, state) {
          _updateShimmerAnimation(state);
          _handleValidationFocus(state);
          if (state.status == GuestFormStatus.success &&
              state.createdOrUpdatedItem != null) {
            Navigator.of(context).pop(state.createdOrUpdatedItem);
          }
        },
        child:
            BlocSelector<
              GuestFormCubit,
              GuestFormState,
              ({bool isSuccess, bool isDirty, bool isSubmitting})
            >(
              selector: (state) => (
                isSuccess: state.isSuccess,
                isDirty: state.isDirty,
                isSubmitting: state.isSubmitting,
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
                    backgroundColor: tones.background,
                    resizeToAvoidBottomInset: false,
                    body: AppKeyboardInsetsPadding(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FailureBanner(cubit: cubit),
                            GuestFormNameField(
                              cubit: cubit,
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              nextFocusNode: _destinationFocusNode,
                            ),
                            AppSpacing.vGap200,
                            GuestFormGuestTypeField(
                              cubit: cubit,
                              shimmerController: _shimmerController,
                            ),
                            AppSpacing.vGap200,
                            GuestFormDestinationField(
                              cubit: cubit,
                              controller: _destinationController,
                              focusNode: _destinationFocusNode,
                            ),
                            AppSpacing.vGap300,
                            AppFormSection.uncontained(
                              title: 'Foto tamu (opsional)',
                              child: GuestFormPhotoSection(
                                cubit: cubit,
                                isSubmitting: record.isSubmitting,
                                onPickPhoto: () => _handlePickPhoto(cubit),
                              ),
                            ),
                            AppSpacing.vGap300,
                            _buildMoreDetails(cubit, record.isSubmitting),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _buildMoreDetails(GuestFormCubit cubit, bool isSubmitting) {
    final tones = KawaloTones.of(context);
    final expanded = _showMore ?? false;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tones.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _showMore = !expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Detail lain ',
                                style: TextStyle(
                                  color: tones.ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                children: [
                                  TextSpan(
                                    text: '(opsional)',
                                    style: TextStyle(
                                      color: tones.ink2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!expanded)
                              Text(
                                'Identitas, plat kendaraan, tuan rumah, '
                                'keperluan, alamat',
                                style: TextStyle(
                                  color: tones.ink2,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: tones.ink2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded)
            BlocSelector<
              GuestFormCubit,
              GuestFormState,
              (String?, String?, String?)
            >(
              bloc: cubit,
              selector: (s) =>
                  (s.guestNumberError, s.purposeError, s.addressError),
              builder: (context, errors) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GuestFormIdentityFields(
                      cubit: cubit,
                      identityNumberController: _identityNumberController,
                      identityNumberFocusNode: _identityNumberFocusNode,
                      addressFocusNode: _guestNumberFocusNode,
                    ),
                    AppSpacing.vGap200,
                    AppTextField(
                      label: 'Nomor tamu / Plat kendaraan',
                      variant: AppTextFieldVariant.outlined,
                      controller: _guestNumberController,
                      focusNode: _guestNumberFocusNode,
                      enabled: !isSubmitting,
                      errorText: errors.$1,
                      textInputAction: TextInputAction.next,
                      onChanged: cubit.onGuestNumberChanged,
                      onSubmitted: (_) => _hostNameFocusNode.requestFocus(),
                    ),
                    AppSpacing.vGap200,
                    GuestFormHostField(
                      cubit: cubit,
                      controller: _hostNameController,
                      focusNode: _hostNameFocusNode,
                      nextFocusNode: _purposeFocusNode,
                    ),
                    AppSpacing.vGap200,
                    AppTextField(
                      label: 'Keperluan kunjungan',
                      variant: AppTextFieldVariant.outlined,
                      controller: _purposeController,
                      focusNode: _purposeFocusNode,
                      enabled: !isSubmitting,
                      errorText: errors.$2,
                      textInputAction: TextInputAction.next,
                      onChanged: cubit.onPurposeChanged,
                      onSubmitted: (_) => _addressFocusNode.requestFocus(),
                    ),
                    AppSpacing.vGap200,
                    AppTextField(
                      label: 'Alamat asal',
                      variant: AppTextFieldVariant.outlined,
                      controller: _addressController,
                      focusNode: _addressFocusNode,
                      enabled: !isSubmitting,
                      errorText: errors.$3,
                      textInputAction: TextInputAction.done,
                      onChanged: cubit.onAddressChanged,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown after a failed save; the typed data stays in the form.
class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.cubit});

  final GuestFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return BlocBuilder<GuestFormCubit, GuestFormState>(
      bloc: cubit,
      buildWhen: (a, b) =>
          a.status != b.status || a.errorMessage != b.errorMessage,
      builder: (context, state) {
        final message = state.errorMessage;
        if (!state.isFailure || message == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tones.sos.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: tones.sos.color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gagal menyimpan. Data tidak hilang, coba lagi.\n'
                      '$message',
                      style: TextStyle(
                        color: tones.sos.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
