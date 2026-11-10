import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/utils/app_keyboard_auto_scroller.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/information_module.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form/information_form_body.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form/information_form_media_actions.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form/information_form_submit_action.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_location_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/app_map_picker_dialog.dart';

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
        action: InformationFormSubmitAction(
          cubit: resolvedCubit,
          label: actionLabel,
          session: session,
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

    final newCubit = context.read<InformationModule>().createFormCubit(
      uploadRepository: context.read<UploadRepository>(),
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
  int _lastHandledValidationAttempt = 0;
  bool _isErrorSheetVisible = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _mediaPicker = widget.mediaPickerService ?? DefaultMediaPickerService();
    _scrollController = ScrollController();

    _lifecycleListener = AppLifecycleListener(onResume: _handleAppResume);

    final cubit = _resolveCubit(context);
    final initial = cubit.state;

    _titleController = TextEditingController(text: initial.title);
    _textController = TextEditingController(text: initial.text);
    _eventLocationController = TextEditingController(
      text: initial.eventLocation,
    );

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

    final (cubit, isOwner) = InformationFormDialog._resolveCubitFromContext(
      context,
    );
    _ownsCubit = isOwner;
    _internalCubit = cubit;
    return _internalCubit!;
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
    final shouldRecover =
        _isErrorSheetVisible && !cubit.state.isResolvingLocation;
    if (shouldRecover) _resolveGps(cubit);
  }

  void _dismissErrorSheetIfVisible() {
    if (!_isErrorSheetVisible) return;
    _isErrorSheetVisible = false;
    final dialogRoute = ModalRoute.of(context);
    if (dialogRoute != null && !dialogRoute.isCurrent) {
      Navigator.of(context).maybePop();
    }
  }

  void _resolveGps(InformationFormCubit cubit) {
    unawaited(cubit.resolveGpsLocation(fetchPosition: widget.locationProvider));
  }

  Future<void> _handleGpsResult(
    InformationFormCubit cubit,
    LocationResult result,
  ) async {
    if (result.isSuccess && result.coordinates != null) {
      _dismissErrorSheetIfVisible();
      AppSnackbar.show(
        context,
        message: 'Titik lokasi GPS berhasil diperoleh.',
      );
    } else if (result.status == LocationStatus.timeout) {
      LocationActionableError.showTimeoutSnackbar(
        context,
        onRetry: () => _resolveGps(cubit),
      );
    } else if (!_isErrorSheetVisible) {
      await _presentLocationError(cubit, result);
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
          _resolveGps(cubit);
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
      _resolveGps(cubit);
    } else if (source == InformationLocationSource.pickOnMap) {
      await _handlePickOnMap(cubit);
    }
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
      AppSnackbar.show(context, message: state.glatError ?? state.glongError!);
    }
  }

  void _handleFormStateChange(
    BuildContext context,
    InformationFormState state,
  ) {
    _syncControllerIfUnfocused(_titleController, _titleFocusNode, state.title);
    _syncControllerIfUnfocused(_textController, _textFocusNode, state.text);
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
      AppSnackbar.show(context, message: msg);
      Navigator.of(context).pop(state.createdOrUpdatedItem);
    } else if (state.status == InformationFormStatus.failure &&
        state.errorMessage != null) {
      AppSnackbar.show(context, message: state.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);

    return BlocProvider.value(
      value: cubit,
      child: BlocListener<InformationFormCubit, InformationFormState>(
        listenWhen: (previous, current) =>
            previous.gpsResultVersion != current.gpsResultVersion,
        listener: (context, state) {
          final result = state.gpsResult;
          if (result != null) unawaited(_handleGpsResult(cubit, result));
        },
        child: BlocListener<InformationFormCubit, InformationFormState>(
          listener: _handleFormStateChange,
          child:
              BlocSelector<
                InformationFormCubit,
                InformationFormState,
                ({
                  bool isDirty,
                  bool isSuccess,
                  bool isSubmitting,
                  bool isCreate,
                })
              >(
                selector: (state) => (
                  isDirty: state.isDirty,
                  isSuccess: state.status == InformationFormStatus.success,
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
                      final confirmed =
                          await InformationFormDialog._confirmDiscard(
                            popContext,
                          );
                      if (confirmed && popContext.mounted) {
                        setState(() => _isDiscarding = true);
                        Navigator.of(popContext).pop();
                      }
                    },
                    child: InformationFormBody(
                      cubit: cubit,
                      isCreate: record.isCreate,
                      scrollController: _scrollController,
                      titleController: _titleController,
                      textController: _textController,
                      eventLocationController: _eventLocationController,
                      titleFocusNode: _titleFocusNode,
                      textFocusNode: _textFocusNode,
                      eventLocationFocusNode: _eventLocationFocusNode,
                      onPickPhoto: () => pickInformationFormPhotos(
                        context,
                        cubit,
                        _mediaPicker,
                      ),
                      onPickDocument: () => pickInformationFormDocument(
                        context,
                        cubit,
                        _mediaPicker,
                      ),
                      onPickLocation: () => _handlePickLocation(cubit),
                      reverseGeocodeService: widget.reverseGeocodeService,
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}
