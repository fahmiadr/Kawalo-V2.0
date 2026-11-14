import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_inline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/incident_module.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_location_chip.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photo_action_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photo_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photo_thumbnail.dart';

/// "Laporan Kejadian": one required field, photos taken beforehand, location
/// filled in automatically.
///
/// [showCreate] runs the whole camera-first flow; the name is kept because the
/// Beranda card calls it.
class IncidentFormDialog extends StatefulWidget {
  const IncidentFormDialog({
    required this.cubit,
    super.key,
    this.mediaPickerService,
  });

  final IncidentFormCubit cubit;
  final MediaPickerService? mediaPickerService;

  static Route<IncidentEntity?> route({
    required IncidentFormCubit cubit,
    MediaPickerService? mediaPickerService,
  }) {
    return AppPageRoute.forwardBackward<IncidentEntity?>(
      settings: const RouteSettings(name: AppRouteNames.incidentCreate),
      builder: (_) => IncidentFormDialog(
        cubit: cubit,
        mediaPickerService: mediaPickerService,
      ),
    );
  }

  /// Camera first (evidence before words), then the form. "Lewati", closing
  /// the camera, or "Lanjut tanpa foto" after a denied camera permission all
  /// continue without photos. On success the new incident is pushed into
  /// [incidentListCubit] and "Laporan terkirim ke grup." is shown on the
  /// screen the flow started from.
  static Future<IncidentEntity?> showCreate(
    BuildContext context, {
    IncidentFormCubit? formCubit,
    IncidentListCubit? incidentListCubit,
    MediaPickerService? mediaPickerService,
  }) async {
    final cubit =
        formCubit ??
        context.read<IncidentModule>().createIncidentFormCubit(
          uploadRepository: context.read<UploadRepository>(),
        );
    final picker = mediaPickerService ?? DefaultMediaPickerService();
    try {
      // GPS warms up while the guard takes photos.
      if (!cubit.state.hasLocation) unawaited(cubit.resolveLocation());

      try {
        final files = await picker.captureMultiImagesFromCamera(
          context,
          alreadyAttachedCount: cubit.state.photos.length,
          allowSkip: true,
        );
        cubit.addPhotos(files.map(IncidentMediaItem.fromAppMediaFile).toList());
      } on Object catch (_) {
        // The camera screen reports its own errors; carry on without photos.
      }
      if (!context.mounted) return null;

      final created = await Navigator.of(
        context,
      ).push(route(cubit: cubit, mediaPickerService: picker));
      if (created != null) {
        incidentListCubit?.onIncidentCreated(created);
        if (context.mounted) {
          AppSnackbar.show(context, message: 'Laporan terkirim ke grup.');
        }
      }
      return created;
    } finally {
      if (formCubit == null) await cubit.close();
    }
  }

  @override
  State<IncidentFormDialog> createState() => _IncidentFormDialogState();
}

class _IncidentFormDialogState extends State<IncidentFormDialog> {
  late final TextEditingController _textController;
  final _textFocusNode = FocusNode();
  late final MediaPickerService _mediaPicker;
  bool _isDiscarding = false;
  int _lastValidationAttempt = 0;

  IncidentFormCubit get _cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    _mediaPicker = widget.mediaPickerService ?? DefaultMediaPickerService();
    _textController = TextEditingController(text: _cubit.state.text);
    final s = _cubit.state;
    if (!s.hasLocation && !s.isResolvingLocation && s.locationError == null) {
      unawaited(_cubit.resolveLocation());
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  bool _isOffline(BuildContext context) {
    try {
      return context.watch<ConnectivityCubit?>()?.state ==
          ConnectivityStatus.offline;
    } on Object catch (_) {
      return false;
    }
  }

  void _submit(BuildContext context) {
    UserSessionCubit? sessionCubit;
    try {
      sessionCubit = context.read<UserSessionCubit?>();
    } on Object catch (_) {}
    unawaited(_cubit.submit(session: sessionCubit?.state));
  }

  Future<void> _pickPhoto() async {
    final source = await IncidentPhotoSourceBottomSheet.show(context);
    if (source == null || !mounted) return;
    try {
      final files = source == IncidentPhotoSource.camera
          ? await _mediaPicker.captureMultiImagesFromCamera(
              context,
              alreadyAttachedCount: _cubit.state.photos.length,
            )
          : await _mediaPicker.pickMultiImagesFromGallery(
              limit: _cubit.state.remainingPhotoSlots,
            );
      _cubit.addPhotos(files.map(IncidentMediaItem.fromAppMediaFile).toList());
    } on Object catch (_) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Foto tidak dapat diambil.');
      }
    }
  }

  void _viewPhoto(int index) {
    AppImageViewer.show(
      context,
      imageUrls: _cubit.state.photos.map((p) => p.displaySource).toList(),
      initialIndex: index,
      heroTagPrefix: 'incident_form_photo',
    );
  }

  void _showPhotoMenu(int index) {
    final photos = _cubit.state.photos;
    if (index < 0 || index >= photos.length) return;
    final item = photos[index];
    IncidentPhotoActionBottomSheet.show(
      context,
      item: item,
      index: index,
      totalPhotos: photos.length,
      onViewPhoto: () => _viewPhoto(index),
      onMakePrimary: () => _cubit.reorderPhotos(index, 0),
      onMoveLeft: () => _cubit.reorderPhotos(index, index - 1),
      onMoveRight: () => _cubit.reorderPhotos(index, index + 1),
      onDelete: () => _cubit.removePhoto(item.id),
    );
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Buang laporan?',
      message: 'Laporan dan foto yang belum dikirim akan hilang.',
      cancelText: 'Lanjut mengisi',
      confirmText: 'Buang',
    );
    if ((confirmed ?? false) && mounted) {
      setState(() => _isDiscarding = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final isOffline = _isOffline(context);

    return BlocConsumer<IncidentFormCubit, IncidentFormState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state.validationAttempt > _lastValidationAttempt) {
          _lastValidationAttempt = state.validationAttempt;
          if (state.textError != null) _textFocusNode.requestFocus();
        }
        if (state.isSuccess && state.createdIncident != null) {
          Navigator.of(context).pop(state.createdIncident);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop:
              _isDiscarding ||
              state.isSuccess ||
              (!state.isDirty && !state.isBusy),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || state.isBusy) return;
            unawaited(_confirmDiscard());
          },
          child: Scaffold(
            backgroundColor: tones.background,
            appBar: const AppTopBar(
              title: 'Laporan Kejadian',
              leading: AppTopBarLeading.close,
            ),
            body: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              children: [
                if (isOffline)
                  const _Gap(
                    AppInlineBanner(
                      message:
                          'Anda offline. Laporan bisa dikirim saat '
                          'tersambung.',
                    ),
                  )
                else if (state.errorMessage != null)
                  _Gap(
                    AppInlineBanner(
                      message: state.errorMessage!,
                      kind: AppInlineBannerKind.error,
                    ),
                  ),
                _Gap(_buildPhotos(state, tones)),
                AppTextField(
                  label: 'Apa yang terjadi?',
                  placeholder: 'Contoh: pagar sisi timur rusak',
                  isRequired: true,
                  variant: AppTextFieldVariant.outlined,
                  controller: _textController,
                  focusNode: _textFocusNode,
                  enabled: !state.isBusy,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: IncidentFormCubit.textMaxLength,
                  showCounter: false,
                  textCapitalization: TextCapitalization.sentences,
                  errorText: state.textError,
                  supportingText: 'Kalimat pertama menjadi judul laporan.',
                  onChanged: _cubit.updateText,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IncidentLocationChip(
                    latitude: state.glat,
                    longitude: state.glong,
                    isResolving: state.isResolvingLocation,
                    error: state.locationError,
                    enabled: !state.isBusy,
                    onRetry: () => unawaited(_cubit.resolveLocation()),
                    onClear: _cubit.clearLocation,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  10 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: _buildAction(context, state, tones, isOffline),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotos(IncidentFormState state, KawaloTones tones) {
    const size = 96.0;
    final photos = state.photos;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < photos.length; i++)
          SizedBox.square(
            dimension: size,
            child: IncidentPhotoThumbnail(
              item: photos[i],
              index: i,
              isSubmitting: state.isBusy,
              borderRadius: BorderRadius.circular(14),
              onTap: () => _viewPhoto(i),
              onRemove: () => _cubit.removePhoto(photos[i].id),
              onMoreOptions: () => _showPhotoMenu(i),
              onRetry: () => unawaited(_cubit.retryPhotoUpload(photos[i].id)),
            ),
          ),
        if (photos.length < 4)
          Semantics(
            button: true,
            label: 'Tambah foto',
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: tones.line, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: state.isBusy ? null : _pickPhoto,
                child: SizedBox.square(
                  dimension: size,
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: tones.ink2,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context,
    IncidentFormState state,
    KawaloTones tones,
    bool isOffline,
  ) {
    if (state.isUploading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: state.uploadProgress,
              minHeight: 6,
              color: tones.inc.color,
              backgroundColor: tones.surface2,
            ),
          ),
          const SizedBox(height: 8),
          AppTaskButton(
            label:
                'Mengunggah foto ${state.uploadingPhotoNumber} dari '
                '${state.photos.length}…',
            tone: tones.inc,
            isLoading: true,
            onPressed: () {},
          ),
        ],
      );
    }
    if (state.isSubmitting) {
      return AppTaskButton(
        label: 'Mengirim laporan…',
        tone: tones.inc,
        isLoading: true,
        onPressed: () {},
      );
    }
    final failed = state.status == IncidentFormStatus.failure;
    return AppTaskButton(
      label: failed ? 'Coba Kirim Lagi' : 'Kirim Laporan',
      icon: failed ? Icons.refresh_rounded : Icons.send_rounded,
      tone: tones.inc,
      onPressed: isOffline || state.isBusy ? null : () => _submit(context),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
}
