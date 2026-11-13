import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/attendance_admin/attendance_admin_module.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_location_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/attendance_location_section.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/attendance_panel.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/app_map_picker_dialog.dart';

/// Admin screen to set the one attendance point of the group; every shift
/// checks in at it. The API rejects writes from other roles, so non-admins
/// only see the point.
class AttendanceLocationScreen extends StatefulWidget {
  const AttendanceLocationScreen({super.key, this.cubit});

  static const String routeName = AppRouteNames.attendanceLocation;

  /// Test injection; defaults to the [AttendanceLocationCubit] of the tree.
  final AttendanceLocationCubit? cubit;

  /// Needs an [AttendanceAdminModule] and a [UserSessionCubit] above the
  /// navigator.
  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: routeName),
    builder: (context) => BlocProvider<AttendanceLocationCubit>(
      create: (context) =>
          context.read<AttendanceAdminModule>().createLocationCubit(),
      child: const AttendanceLocationScreen(),
    ),
  );

  @override
  State<AttendanceLocationScreen> createState() =>
      _AttendanceLocationScreenState();
}

class _AttendanceLocationScreenState extends State<AttendanceLocationScreen> {
  final _name = TextEditingController();

  AttendanceLocationCubit get _cubit =>
      widget.cubit ?? context.read<AttendanceLocationCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_cubit.load());
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPoint() async {
    final state = _cubit.state;
    final picked = await AppMapPickerDialog.show(
      context,
      initialLatitude: state.latitude,
      initialLongitude: state.longitude,
      autoTriggerGps: !state.hasPoint,
    );
    if (picked == null) return;
    _cubit.setCoordinates(picked.latitude, picked.longitude);
    // Prefill the name from the street address only when the admin has not
    // typed one.
    final address = picked.address;
    if (_name.text.trim().isEmpty && address != null) {
      _name.text = address.length > AttendanceLocationCubit.nameMax
          ? address.substring(0, AttendanceLocationCubit.nameMax)
          : address;
      _cubit.setLocationName(_name.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.watch<UserSessionCubit?>()?.state?.isAdminRole ?? false;
    final colors = AppTheme.of(context).colorScheme;

    return BlocConsumer<AttendanceLocationCubit, AttendanceLocationState>(
      bloc: _cubit,
      listenWhen: (a, b) =>
          a.noticeSeq != b.noticeSeq || a.location != b.location,
      listener: (context, state) {
        if (_name.text != state.locationName) _name.text = state.locationName;
        final notice = state.notice;
        if (notice != null) AppSnackbar.show(context, message: notice);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.surface,
          appBar: const AppHomeAppBar(
            title: 'Titik Absen',
            showBackButton: true,
            showTrailing: false,
          ),
          bottomNavigationBar: isAdmin && state.isLoaded
              ? AppPageActions(
                  children: [
                    AppButton(
                      size: AppButtonSize.md,
                      enabled: state.canSave,
                      onPressed: () => unawaited(_cubit.save()),
                      child: Text(state.saving ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            child: switch (state.phase) {
              AttendanceLocationPhase.loading => const _Skeleton(),
              AttendanceLocationPhase.failure => ListErrorState(
                noun: 'titik absen',
                message: state.errorMessage ?? 'Terjadi kesalahan.',
                onRetry: () => unawaited(_cubit.load()),
              ),
              AttendanceLocationPhase.loaded => _Content(
                state: state,
                isAdmin: isAdmin,
                nameController: _name,
                onPickPoint: () => unawaited(_pickPoint()),
                cubit: _cubit,
              ),
            },
          ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.isAdmin,
    required this.nameController,
    required this.onPickPoint,
    required this.cubit,
  });

  final AttendanceLocationState state;
  final bool isAdmin;
  final TextEditingController nameController;
  final VoidCallback onPickPoint;
  final AttendanceLocationCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colors = theme.colorScheme;
    final text = theme.typeScale;
    final location = state.location;
    final configured = location?.configured ?? false;
    final updatedBy = location?.updatedBy;
    // A non-admin has nothing to pick, so an unset point shows only the note.
    final showForm = isAdmin || configured;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space200),
      children: [
        AttendancePanel(
          color: colors.surfaceContainerLow,
          child: Text(
            'Semua shift absen di titik ini. Absen hanya sah di dalam radius '
            'titik.',
            style: text.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        if (!configured) ...[
          AppSpacing.vGapSm,
          AttendancePanel(
            key: const ValueKey('location_unset'),
            color: colors.surfaceContainerHigh,
            child: Text(
              isAdmin
                  ? 'Belum ada titik absen. Tentukan titik agar absen hanya '
                        'sah di dalam radius.'
                  : 'Belum ada titik absen. Admin belum menentukannya.',
              style: text.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
        if (!isAdmin && configured) ...[
          AppSpacing.vGapSm,
          AttendancePanel(
            color: colors.surfaceContainerHigh,
            child: Text(
              'Hanya admin yang dapat mengubah titik absen.',
              style: text.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
        if (showForm) ...[
          AppSpacing.vGap300,
          AttendanceLocationSection(
            state: state,
            locationNameController: nameController,
            enabled: isAdmin && !state.saving,
            onPickPoint: onPickPoint,
            onLocationNameChanged: cubit.setLocationName,
            onRadiusPreset: cubit.selectRadiusPreset,
            onRadiusCustom: cubit.selectCustomRadius,
            onRadiusText: cubit.setRadiusText,
          ),
        ],
        if (configured && updatedBy != null) ...[
          AppSpacing.vGap300,
          Text(
            'Terakhir diubah oleh $updatedBy pada '
            '${AppDateFormat.formatRawDate(location?.updatedAt)}',
            style: text.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.of(context).colorScheme.surfaceContainerHigh;

    Widget bar(double height, [double? width]) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderMedium,
      ),
    );

    return Semantics(
      label: 'Memuat titik absen',
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.space200),
          children: [
            bar(64),
            AppSpacing.vGap300,
            bar(140),
            AppSpacing.vGap200,
            bar(56),
            AppSpacing.vGap200,
            bar(48),
          ],
        ),
      ),
    );
  }
}
