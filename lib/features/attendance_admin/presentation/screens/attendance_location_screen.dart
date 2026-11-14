import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/attendance_admin/attendance_admin_module.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_location_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/attendance_location_section.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';
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
    final tones = KawaloTones.of(context);

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
          backgroundColor: tones.background,
          appBar: AppBar(
            backgroundColor: tones.background,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Titik Absen'),
                Text(
                  'Berlaku untuk semua shift',
                  style: TextStyle(
                    color: tones.ink2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isAdmin && state.isLoaded
              ? AppTaskFooter(
                  children: [
                    AppTaskButton(
                      label: 'Simpan Titik',
                      icon: Icons.check_rounded,
                      tone: tones.adm,
                      isLoading: state.saving,
                      onPressed: state.canSave
                          ? () => unawaited(_cubit.save())
                          : null,
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
    final tones = KawaloTones.of(context);
    final note = TextStyle(color: tones.ink2, fontSize: 14, height: 1.4);
    final location = state.location;
    final configured = location?.configured ?? false;
    final updatedBy = location?.updatedBy;
    // A non-admin has nothing to pick, so an unset point shows only the note.
    final showForm = isAdmin || configured;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        if (!configured) ...[
          TaskBox(
            key: const ValueKey('location_unset'),
            soft: true,
            children: [
              Text(
                'Titik absen belum diatur',
                style: TextStyle(
                  color: tones.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                isAdmin
                    ? 'Selama belum diatur, absen memakai lokasi lama dari '
                          'shift bila ada.'
                    : 'Admin belum menentukan titik absen.',
                style: note,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (showForm)
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
        const SizedBox(height: 14),
        Text(
          'Semua shift absen di titik ini. Absen hanya sah di dalam radius '
          'titik.',
          style: note,
        ),
        if (!isAdmin && configured) ...[
          const SizedBox(height: 8),
          Text('Hanya admin yang dapat mengubah titik absen.', style: note),
        ],
        if (configured && updatedBy != null) ...[
          const SizedBox(height: 8),
          Text(
            'Terakhir diubah oleh $updatedBy pada '
            '${AppDateFormat.formatRawDate(location?.updatedAt)}',
            style: note,
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
    final color = KawaloTones.of(context).surface2;

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
