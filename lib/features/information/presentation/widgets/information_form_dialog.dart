import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_keyboard_auto_scroller.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_map_picker_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/information_module.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_document_section.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_location_section.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_location_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_action_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photos_section.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_publication_section.dart';

/// Formulir publikasi (posting) dan pembaruan (update) informasi/feed
/// berbasis Material 3 Expressive Fullscreen Dialog.
class InformationFormDialog extends StatefulWidget {
  /// Membuat instance [InformationFormDialog].
  const InformationFormDialog({
    super.key,
    this.cubit,
    this.mediaPickerService,
    this.locationService = const DefaultLocationService(),
    this.locationProvider,
    this.reverseGeocodeService,
    this.launcherService = const DefaultAppLauncherService(),
    this.openAppSettingsFn,
    this.openLocationSettingsFn,
  });

  /// Instance [InformationFormCubit] opsional untuk injeksi atau pengujian.
  final InformationFormCubit? cubit;

  /// Layanan opsional untuk pemilihan media (kamera, galeri, dokumen).
  final MediaPickerService? mediaPickerService;

  /// Layanan inspeksi lokasi GPS terpadu (Pure DI).
  final LocationService locationService;

  /// Provider lokasi GPS opsional (untuk injeksi dependensi & pengujian).
  final Future<LocationResult> Function()? locationProvider;

  /// Layanan reverse geocoding opsional untuk resolusi alamat fisik (Pure DI).
  final ReverseGeocodeService? reverseGeocodeService;

  /// Layanan peluncur intent eksternal untuk membuka pengaturan OS (Pure DI).
  final AppLauncherService launcherService;

  /// Delegasi fungsi pembuka pengaturan perizinan aplikasi di sistem operasi.
  final Future<bool> Function()? openAppSettingsFn;

  /// Delegasi fungsi pembuka pengaturan sakelar lokasi/GPS di sistem operasi.
  final Future<bool> Function()? openLocationSettingsFn;

  /// Menampilkan dialog penambahan (posting) informasi baru.
  static Future<InformationItemEntity?> showCreate(
    BuildContext context, {
    InformationFormCubit? formCubit,
    InformationCubit? informationCubit,
    MediaPickerService? mediaPickerService,
    LocationService locationService = const DefaultLocationService(),
    Future<LocationResult> Function()? locationProvider,
    ReverseGeocodeService? reverseGeocodeService,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    Future<bool> Function()? openAppSettingsFn,
    Future<bool> Function()? openLocationSettingsFn,
  }) {
    return show(
      context: context,
      cubit: formCubit,
      informationCubit: informationCubit,
      mediaPickerService: mediaPickerService,
      locationService: locationService,
      locationProvider: locationProvider,
      reverseGeocodeService: reverseGeocodeService,
      launcherService: launcherService,
      openAppSettingsFn: openAppSettingsFn,
      openLocationSettingsFn: openLocationSettingsFn,
    );
  }

  /// Menampilkan dialog pembaruan (edit) informasi yang sudah ada.
  static Future<InformationItemEntity?> showUpdate(
    BuildContext context, {
    required InformationItemEntity item,
    InformationFormCubit? formCubit,
    InformationCubit? informationCubit,
    MediaPickerService? mediaPickerService,
    LocationService locationService = const DefaultLocationService(),
    Future<LocationResult> Function()? locationProvider,
    ReverseGeocodeService? reverseGeocodeService,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    Future<bool> Function()? openAppSettingsFn,
    Future<bool> Function()? openLocationSettingsFn,
  }) {
    return show(
      context: context,
      initialItem: item,
      cubit: formCubit,
      informationCubit: informationCubit,
      mediaPickerService: mediaPickerService,
      locationService: locationService,
      locationProvider: locationProvider,
      reverseGeocodeService: reverseGeocodeService,
      launcherService: launcherService,
      openAppSettingsFn: openAppSettingsFn,
      openLocationSettingsFn: openLocationSettingsFn,
    );
  }

  /// Menampilkan dialog formulir informasi dalam mode fullscreen.
  static Future<InformationItemEntity?> show({
    required BuildContext context,
    InformationItemEntity? initialItem,
    InformationFormCubit? cubit,
    InformationCubit? informationCubit,
    MediaPickerService? mediaPickerService,
    LocationService locationService = const DefaultLocationService(),
    Future<LocationResult> Function()? locationProvider,
    ReverseGeocodeService? reverseGeocodeService,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    Future<bool> Function()? openAppSettingsFn,
    Future<bool> Function()? openLocationSettingsFn,
  }) async {
    final (resolvedCubit, isInternal) = cubit != null
        ? (cubit, false)
        : _resolveCubitFromContext(context, initialItem: initialItem);
    final isCreate = resolvedCubit.state.isCreateMode;
    final title = isCreate ? 'Posting informasi' : 'Edit informasi';
    final actionLabel = isCreate ? 'Posting' : 'Simpan';

    AuthSessionEntity? session;
    try {
      session = context.read<UserSessionCubit?>()?.state;
    } on Object catch (_) {}

    try {
      final result = await AppDialog.showFullScreen<InformationItemEntity>(
        context,
        title: title,
        action: BlocSelector<InformationFormCubit, InformationFormState, bool>(
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
                child: Text(actionLabel),
              ),
            );
          },
        ),
        body: InformationFormDialog(
          cubit: resolvedCubit,
          mediaPickerService: mediaPickerService,
          locationService: locationService,
          locationProvider: locationProvider,
          reverseGeocodeService: reverseGeocodeService,
          launcherService: launcherService,
          openAppSettingsFn: openAppSettingsFn,
          openLocationSettingsFn: openLocationSettingsFn,
        ),
      );

      if (result != null && informationCubit != null) {
        if (isCreate) {
          informationCubit.onInformationCreated(result);
        } else {
          informationCubit.onInformationUpdated(result);
        }
        unawaited(informationCubit.refreshInformation());
      }

      return result;
    } finally {
      if (isInternal) {
        await resolvedCubit.close();
      }
    }
  }

  static Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Buang perubahan?',
      message: 'Data formulir yang belum disimpan akan hilang.',
      cancelText: 'Lanjut mengisi',
      confirmText: 'Buang',
    );
    return confirmed ?? false;
  }

  static (InformationFormCubit, bool) _resolveCubitFromContext(
    BuildContext context, {
    InformationItemEntity? initialItem,
  }) {
    try {
      final existing = context.read<InformationFormCubit>();
      return (existing, false);
    } on Object catch (_) {}

    ApiClient? apiClient;
    try {
      apiClient = context.read<ApiClient>();
    } on Object catch (_) {}

    Isar? isar;
    try {
      isar = context.read<Isar>();
    } on Object catch (_) {}

    final client = apiClient ?? ApiClient();
    final newCubit = InformationModule.createFormCubit(
      apiClient: client,
      isar: isar ?? (throw StateError('Isar is required')),
      initialItem: initialItem,
    );
    return (newCubit, true);
  }

  @override
  State<InformationFormDialog> createState() => _InformationFormDialogState();
}

class _InformationFormDialogState extends State<InformationFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _eventLocationController;

  late final FocusNode _titleFocusNode;
  late final FocusNode _textFocusNode;
  late final FocusNode _eventLocationFocusNode;

  late final ScrollController _scrollController;
  late final AppKeyboardAutoScroller _keyboardScroller;
  late final MediaPickerService _mediaPicker;

  InformationFormCubit? _internalCubit;
  bool _ownsCubit = false;
  bool _isDiscarding = false;
  bool _isResolvingLocation = false;
  int _lastHandledValidationAttempt = 0;
  bool _isErrorSheetVisible = false;
  int _gpsGeneration = 0;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _mediaPicker = widget.mediaPickerService ?? DefaultMediaPickerService();
    _scrollController = ScrollController();

    _lifecycleListener = AppLifecycleListener(
      onResume: _handleAppResume,
    );

    final cubit = _resolveCubit(context);
    final initial = cubit.state;

    _titleController = TextEditingController(text: initial.title);
    _textController = TextEditingController(text: initial.text);
    _eventLocationController =
        TextEditingController(text: initial.eventLocation);

    _titleFocusNode = FocusNode();
    _textFocusNode = FocusNode();
    _eventLocationFocusNode = FocusNode();

    _keyboardScroller = AppKeyboardAutoScroller(
      scrollController: _scrollController,
    );
    _keyboardScroller.registerNodes([
      _titleFocusNode,
      _textFocusNode,
      _eventLocationFocusNode,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardScroller.attachContext(context);
      }
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _keyboardScroller.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _textController.dispose();
    _eventLocationController.dispose();

    _titleFocusNode.dispose();
    _textFocusNode.dispose();
    _eventLocationFocusNode.dispose();

    if (_ownsCubit) {
      _internalCubit?.close();
    }
    super.dispose();
  }

  void _syncControllerIfUnfocused(
    TextEditingController controller,
    FocusNode focusNode,
    String value,
  ) {
    if (!focusNode.hasFocus && controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  InformationFormCubit _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit!;
    if (_internalCubit != null) return _internalCubit!;

    final (cubit, isOwner) =
        InformationFormDialog._resolveCubitFromContext(context);
    _ownsCubit = isOwner;
    _internalCubit = cubit;
    return _internalCubit!;
  }

  Future<void> _handlePickPhoto(InformationFormCubit cubit) async {
    final source = await InformationPhotoSourceBottomSheet.show(context);
    if (source == null || !mounted) return;

    if (cubit.state.isPhotoLimitReached) {
      AppSnackbar.show(
        context,
        message: 'Maksimal '
            '${InformationFormState.maxPhotosLimit} foto dapat dilampirkan.',
      );
      return;
    }

    try {
      final remainingSlots = cubit.state.remainingPhotoSlots;
      List<AppMediaFile> files;

      if (source == InformationPhotoSource.camera) {
        files = await _mediaPicker.captureMultiImagesFromCamera(
          context,
          alreadyAttachedCount: cubit.state.photos.length,
        );
      } else {
        files = await _mediaPicker.pickMultiImagesFromGallery(
          limit: remainingSlots,
        );
      }

      if (files.isEmpty || !mounted) return;

      final mediaItems =
          files.map(InformationFormMediaItem.fromAppMediaFile).toList();
      final addedCount = cubit.onAddMediaPhotos(mediaItems);
      if (!mounted) return;

      if (addedCount > 0) {
        AppSnackbar.show(
          context,
          message: addedCount == 1
              ? 'Foto berhasil ditambahkan ke lampiran.'
              : '$addedCount foto berhasil ditambahkan ke lampiran.',
        );
      } else if (cubit.state.photosError != null) {
        AppSnackbar.show(
          context,
          message: cubit.state.photosError!,
        );
      }
    } on Exception catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Gagal memproses foto. Silakan coba lagi.',
        );
      }
    }
  }

  Future<void> _handlePickDocument(InformationFormCubit cubit) async {
    final file = await _mediaPicker.pickDocumentFile();
    if (file == null || !mounted) return;

    final mediaItem = InformationFormMediaItem.fromAppMediaFile(file);
    cubit.onSetDocumentMedia(mediaItem);

    if (mounted) {
      AppSnackbar.show(
        context,
        message: 'Dokumen "${mediaItem.name}" berhasil dipilih.',
      );
    }
  }

  Future<void> _handlePickOnMap(
    InformationFormCubit cubit, {
    bool autoTriggerGps = true,
  }) async {
    if (!mounted) return;
    final picked = await AppMapPickerDialog.show(
      context,
      initialLatitude: cubit.state.latitude,
      initialLongitude: cubit.state.longitude,
      reverseGeocodeService: widget.reverseGeocodeService,
      locationService: widget.locationService,
      locationProvider: widget.locationProvider,
      launcherService: widget.launcherService,
      openAppSettingsFn: widget.openAppSettingsFn,
      openLocationSettingsFn: widget.openLocationSettingsFn,
      autoTriggerGps: autoTriggerGps,
    );
    if (picked != null && mounted) {
      cubit.onSetLocationCoordinates(
        lat: picked.latitude,
        lng: picked.longitude,
      );

      AppSnackbar.show(
        context,
        message: 'Titik lokasi peta berhasil ditentukan.',
      );
    }
  }

  /// Self-Healing State Reconciliation saat aplikasi kembali aktif
  /// (misalnya pengguna mengaktifkan GPS di OS Settings atau panel
  /// Quick Settings dan kembali ke app).
  void _handleAppResume() {
    if (!mounted) return;
    final cubit = _resolveCubit(context);
    final shouldRecover = _isErrorSheetVisible && !_isResolvingLocation;
    if (shouldRecover) {
      unawaited(_handleGetGpsLocation(cubit, isAutoRecovery: true));
    }
  }

  void _dismissErrorSheetIfVisible() {
    if (!_isErrorSheetVisible) return;
    _isErrorSheetVisible = false;
    final dialogRoute = ModalRoute.of(context);
    if (dialogRoute != null && !dialogRoute.isCurrent) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _handleGetGpsLocation(
    InformationFormCubit cubit, {
    bool isAutoRecovery = false,
  }) async {
    if (_isResolvingLocation) return;
    final generation = ++_gpsGeneration;
    setState(() => _isResolvingLocation = true);

    final LocationResult result;
    try {
      final fetchPosition =
          widget.locationProvider ?? widget.locationService.getCurrentPosition;
      result = await fetchPosition();
    } finally {
      if (mounted && generation == _gpsGeneration) {
        setState(() => _isResolvingLocation = false);
      }
    }

    if (!mounted || generation != _gpsGeneration) return;

    if (result.isSuccess && result.coordinates != null) {
      _dismissErrorSheetIfVisible();
      final (lat, lng) = result.coordinates!;
      cubit.onSetLocationCoordinates(
        lat: lat,
        lng: lng,
      );
      AppSnackbar.show(
        context,
        message: 'Titik lokasi GPS berhasil diperoleh.',
      );
    } else if (result.status == LocationStatus.timeout) {
      LocationActionableError.showTimeoutSnackbar(
        context,
        onRetry: () => unawaited(_handleGetGpsLocation(cubit)),
      );
    } else {
      if (!_isErrorSheetVisible) {
        await _presentLocationError(cubit, result);
      }
    }
  }

  Future<void> _presentLocationError(
    InformationFormCubit cubit,
    LocationResult result,
  ) async {
    if (_isErrorSheetVisible) return;
    _isErrorSheetVisible = true;
    var shouldPickOnMap = false;

    try {
      await LocationActionableError.showBottomSheet<void>(
        context,
        result: result,
        secondaryActionLabel:
            result.status == LocationStatus.mockLocationDetected
                ? 'Kembali'
                : 'Pilih di peta',
        onDismiss: () {
          if (result.status != LocationStatus.mockLocationDetected) {
            shouldPickOnMap = true;
          }
          _isErrorSheetVisible = false;
          Navigator.of(context).maybePop();
        },
        onRetry: () {
          _isErrorSheetVisible = false;
          Navigator.of(context).maybePop();
          unawaited(_handleGetGpsLocation(cubit));
        },
        launcherService: widget.launcherService,
        openAppSettingsFn: widget.openAppSettingsFn,
        openLocationSettingsFn: widget.openLocationSettingsFn,
      );
    } finally {
      _isErrorSheetVisible = false;
    }

    if (shouldPickOnMap && mounted) {
      await _handlePickOnMap(cubit, autoTriggerGps: false);
    }
  }

  Future<void> _handlePickLocation(InformationFormCubit cubit) async {
    final source = await InformationLocationSourceBottomSheet.show(context);
    if (source == null || !mounted) return;

    if (source == InformationLocationSource.currentLocation) {
      await _handleGetGpsLocation(cubit);
    } else if (source == InformationLocationSource.pickOnMap) {
      await _handlePickOnMap(cubit);
    }
  }

  Future<void> _handleClearAllPhotos(InformationFormCubit cubit) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus semua foto?',
      message: 'Seluruh foto lampiran akan dihapus dari formulir.',
      confirmText: 'Hapus semua',
    );
    if (confirmed == true && mounted) {
      cubit.onClearAllPhotos();
      AppSnackbar.show(
        context,
        message: 'Seluruh foto lampiran telah dihapus.',
      );
    }
  }

  void _showPhotoActionMenu(
    BuildContext context,
    InformationFormCubit cubit,
    int index,
  ) {
    final photos = cubit.state.photos;
    if (index < 0 || index >= photos.length) return;
    final item = photos[index];
    if (item.isLoading) return;

    InformationPhotoActionBottomSheet.show(
      context,
      item: item,
      index: index,
      totalPhotos: photos.length,
      onViewPhoto: () => AppImageViewer.show(
        context,
        imageUrls: photos.map((p) => p.displaySource).toList(),
        initialIndex: index,
      ),
      onMakePrimary: () => cubit.onReorderPhotos(index, 0),
      onMoveLeft: () => cubit.onReorderPhotos(index, index - 1),
      onMoveRight: () => cubit.onReorderPhotos(index, index + 1),
      onDelete: () => cubit.onRemovePhoto(index),
    );
  }

  void _handleValidationFailure(InformationFormState state) {
    if (state.titleError != null) {
      _titleFocusNode.requestFocus();
      _keyboardScroller.scrollToNode(_titleFocusNode, immediate: true);
    } else if (state.textError != null) {
      _textFocusNode.requestFocus();
      _keyboardScroller.scrollToNode(_textFocusNode, immediate: true);
    } else if (state.eventLocationError != null) {
      _eventLocationFocusNode.requestFocus();
      _keyboardScroller.scrollToNode(_eventLocationFocusNode, immediate: true);
    } else if (state.photosError != null) {
      AppSnackbar.show(context, message: state.photosError!);
    } else if (state.glatError != null || state.glongError != null) {
      AppSnackbar.show(
        context,
        message: state.glatError ?? state.glongError!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: cubit,
      child: BlocListener<InformationFormCubit, InformationFormState>(
        listener: (context, state) {
          _syncControllerIfUnfocused(
            _titleController,
            _titleFocusNode,
            state.title,
          );
          _syncControllerIfUnfocused(
            _textController,
            _textFocusNode,
            state.text,
          );
          _syncControllerIfUnfocused(
            _eventLocationController,
            _eventLocationFocusNode,
            state.eventLocation,
          );

          if (state.validationAttempt > _lastHandledValidationAttempt) {
            _lastHandledValidationAttempt = state.validationAttempt;
            _handleValidationFailure(state);
          }

          if (state.status == InformationFormStatus.success &&
              state.createdOrUpdatedItem != null) {
            final msg = state.isCreateMode
                ? 'Informasi "${state.title}" berhasil dipublikasikan.'
                : 'Informasi "${state.title}" berhasil diperbarui.';
            AppSnackbar.show(
              context,
              message: msg,
            );
            Navigator.of(context).pop(state.createdOrUpdatedItem);
          } else if (state.status == InformationFormStatus.failure &&
              state.errorMessage != null) {
            AppSnackbar.show(
              context,
              message: state.errorMessage!,
            );
          }
        },
        child: BlocSelector<InformationFormCubit, InformationFormState,
            ({bool isDirty, bool isSuccess, bool isSubmitting, bool isCreate})>(
          selector: (state) => (
            isDirty: state.isDirty,
            isSuccess: state.status == InformationFormStatus.success,
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
                    await InformationFormDialog._confirmDiscard(popContext);
                if (confirmed && popContext.mounted) {
                  setState(() => _isDiscarding = true);
                  Navigator.of(popContext).pop();
                }
              },
              child: Scaffold(
                backgroundColor: colorScheme.surface,
                resizeToAvoidBottomInset: false,
                body: BlocSelector<InformationFormCubit, InformationFormState,
                    bool>(
                  selector: (state) => state.isSubmitting,
                  builder: (context, isSubmitting) {
                    final overlayMsg = record.isCreate
                        ? 'Mempublikasikan informasi...'
                        : 'Menyimpan perubahan informasi...';

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
                              // ── SEKSI 1: DETAIL PUBLIKASI & KATEGORI ────
                              RepaintBoundary(
                                child: InformationPublicationSection(
                                  titleController: _titleController,
                                  textController: _textController,
                                  titleFocusNode: _titleFocusNode,
                                  textFocusNode: _textFocusNode,
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
                                  onPickPhoto: () => _handlePickPhoto(cubit),
                                  onClearAll: () =>
                                      _handleClearAllPhotos(cubit),
                                  onTapPhoto: (index) {
                                    final photos = cubit.state.photos;
                                    if (index < 0 || index >= photos.length) {
                                      return;
                                    }
                                    if (photos[index].isLoading) return;
                                    AppImageViewer.show(
                                      context,
                                      imageUrls: photos
                                          .map((p) => p.displaySource)
                                          .toList(),
                                      initialIndex: index,
                                      heroTagPrefix: 'info_form_photo',
                                    );
                                  },
                                  onRemovePhoto: cubit.onRemovePhoto,
                                  onMoreOptions: (index) =>
                                      _showPhotoActionMenu(
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
                                  onPickDocument: () =>
                                      _handlePickDocument(cubit),
                                  onClearDocument: cubit.onClearDocumentMedia,
                                ),
                              ),

                              AppSpacing.vGap400,

                              // ── SEKSI 4: LOKASI KEJADIAN & PETA ─────────
                              RepaintBoundary(
                                child: InformationLocationSection(
                                  eventLocationController:
                                      _eventLocationController,
                                  eventLocationFocusNode:
                                      _eventLocationFocusNode,
                                  isSubmitting: isSubmitting,
                                  isResolvingLocation: _isResolvingLocation,
                                  onLocationNameChanged:
                                      cubit.onEventLocationChanged,
                                  onPickLocation: () =>
                                      _handlePickLocation(cubit),
                                  onClearLocation:
                                      cubit.onClearLocationCoordinates,
                                  reverseGeocodeService:
                                      widget.reverseGeocodeService,
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
}
