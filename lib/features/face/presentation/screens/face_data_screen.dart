import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_data_cubit.dart';
import 'package:kawalo_mobile/features/face/presentation/screens/face_registration_screen.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';

/// "Pengaturan > Data Wajah": registration status, register, and delete.
class FaceDataScreen extends StatelessWidget {
  const FaceDataScreen({
    required this.repository,
    super.key,
    this.cameraFactory,
  });

  static const String routeName = AppRouteNames.faceData;

  final FaceRepository repository;
  final FaceCamera Function()? cameraFactory;

  static Route<void> route({required FaceRepository repository}) =>
      AppPageRoute.forwardBackward<void>(
        settings: const RouteSettings(name: routeName),
        builder: (_) => FaceDataScreen(repository: repository),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FaceDataCubit(repository: repository)..load(),
      child: BlocConsumer<FaceDataCubit, FaceDataState>(
        listenWhen: (previous, current) =>
            current.deleted ||
            (current.error != null && current.status != null),
        listener: (context, state) => AppSnackbar.show(
          context,
          message: state.deleted
              ? 'Data wajah berhasil dihapus'
              : state.error ?? '',
        ),
        builder: (context, state) {
          final cubit = context.read<FaceDataCubit>();
          final status = state.status;
          return Scaffold(
            appBar: AppBar(title: const Text('Data Wajah')),
            body: SafeArea(
              child: status == null
                  ? Center(
                      child: state.error == null
                          ? const AppLoadingIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(
                                AppSpacing.space300,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.error!,
                                    textAlign: TextAlign.center,
                                  ),
                                  AppSpacing.vGap200,
                                  AppButton(
                                    onPressed: () => unawaited(cubit.load()),
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                    )
                  : _Body(
                      status: status,
                      busy: state.loading || state.deleting,
                      onRegister: () => unawaited(_register(context, status)),
                      onDelete: () => unawaited(_confirmDelete(context)),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _register(BuildContext context, FaceStatus status) async {
    final cubit = context.read<FaceDataCubit>();
    await Navigator.of(context).push(
      FaceRegistrationScreen.route(
        repository: repository,
        replaceExisting: status.needsReregistration,
        cameraFactory: cameraFactory,
      ),
    );
    await cubit.load();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<FaceDataCubit>();
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Hapus data wajah?',
      message:
          'Template wajah dan semua foto pendaftaran Anda akan dihapus dari '
          'server. Anda harus mendaftarkan wajah lagi sebelum check-in atau '
          'check-out berikutnya.',
      confirmText: 'Hapus Data Wajah',
    );
    if (confirmed ?? false) await cubit.delete();
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.status,
    required this.busy,
    required this.onRegister,
    required this.onDelete,
  });

  final FaceStatus status;
  final bool busy;
  final VoidCallback onRegister;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final registeredAt = status.registeredAt;
    final String value;
    if (!status.registered) {
      value = 'Belum terdaftar';
    } else if (status.needsReregistration) {
      value = 'Perlu didaftarkan ulang';
    } else {
      value = registeredAt == null
          ? 'Terdaftar · ${status.photoCount} foto'
          : 'Terdaftar sejak ${AppDateFormat.formatDateOnly(registeredAt.toLocal())} '
                '· ${status.photoCount} foto';
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space200),
      children: [
        FaceInfoCard(
          children: [
            FaceInfoRow(
              icon: KawaloVectors.userShield01,
              label: 'Status wajah',
              value: value,
            ),
          ],
        ),
        AppSpacing.vGap300,
        if (status.available && !status.usable) ...[
          AppButton(
            size: AppButtonSize.md,
            enabled: !busy,
            onPressed: onRegister,
            child: Text(
              status.registered ? 'Daftarkan Ulang Wajah' : 'Daftarkan Wajah',
            ),
          ),
          AppSpacing.vGap100,
        ],
        if (status.registered)
          AppButton(
            size: AppButtonSize.md,
            enabled: !busy,
            decoration: AppButtonDecoration(
              backgroundColor: WidgetStatePropertyAll(colors.error),
              foregroundColor: WidgetStatePropertyAll(colors.onError),
            ),
            onPressed: onDelete,
            child: const Text('Hapus Data Wajah'),
          ),
      ],
    );
  }
}
