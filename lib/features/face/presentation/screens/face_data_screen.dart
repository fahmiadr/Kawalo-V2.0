import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_data_cubit.dart';
import 'package:kawalo_mobile/features/face/presentation/screens/face_registration_screen.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

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
          final busy = state.loading || state.deleting;
          if (status == null) {
            final error = state.error;
            return TaskScaffold(
              title: 'Data Wajah',
              scrollable: false,
              body: error == null
                  ? const Center(child: AppLoadingIndicator())
                  : TaskMessage(
                      icon: const Icon(Icons.error_outline_rounded),
                      kind: TaskMessageKind.bad,
                      title: 'Gagal memuat',
                      message: error,
                    ),
              footer: [
                if (error != null)
                  taskSecondary('Coba Lagi', () => unawaited(cubit.load())),
              ],
            );
          }
          final tones = KawaloTones.of(context);
          return TaskScaffold(
            title: 'Data Wajah',
            body: _Body(status: status),
            footer: [
              if (status.available && status.registered)
                taskSecondary(
                  'Daftar Ulang',
                  busy ? null : () => unawaited(_register(context, status)),
                )
              else if (status.available)
                taskPrimary(
                  'Daftarkan Wajah',
                  busy ? null : () => unawaited(_register(context, status)),
                  tone: tones.abs,
                ),
              if (status.registered)
                taskPrimary(
                  'Hapus Data Wajah',
                  busy ? null : () => unawaited(_confirmDelete(context)),
                  tone: dangerTone(tones),
                  icon: Icons.delete_outline_rounded,
                  isLoading: state.deleting,
                ),
            ],
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
        replaceExisting: status.registered,
        cameraFactory: cameraFactory,
      ),
    );
    await cubit.load();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<FaceDataCubit>();
    final confirmed = await showTaskConfirmDialog(
      context: context,
      title: 'Hapus data wajah?',
      message:
          'Template wajah dan semua foto pendaftaran Anda akan dihapus dari '
          'server. Anda harus mendaftarkan wajah lagi sebelum check-in atau '
          'check-out berikutnya.',
      confirmLabel: 'Hapus',
      tone: KawaloTones.of(context).sos,
    );
    if (confirmed) await cubit.delete();
  }
}

/// `RdWajahStatus`.
class _Body extends StatelessWidget {
  const _Body({required this.status});

  final FaceStatus status;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final registeredAt = status.registeredAt;
    final String title;
    final String detail;
    final KawaloTone tone;
    final IconData icon;
    if (!status.available) {
      (title, detail, tone, icon) = (
        'Layanan wajah belum tersedia',
        'Verifikasi wajah belum aktif di server. Hubungi admin grup.',
        tones.adm,
        Icons.info_outline_rounded,
      );
    } else if (!status.registered) {
      (title, detail, tone, icon) = (
        'Belum terdaftar',
        'Check-in dan check-out wajib memakai wajah.',
        tones.abs,
        Icons.face_outlined,
      );
    } else if (status.needsReregistration) {
      (title, detail, tone, icon) = (
        'Perlu didaftarkan ulang',
        'Data wajah lama tidak bisa dipakai lagi untuk verifikasi.',
        tones.sos,
        Icons.error_outline_rounded,
      );
    } else {
      (title, detail, tone, icon) = (
        'Terdaftar',
        [
          if (registeredAt != null)
            'Sejak ${AppDateFormat.formatDateOnly(registeredAt.toLocal())}',
          '${status.photoCount} foto',
        ].join(' · '),
        tones.abs,
        Icons.check_rounded,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskBox(
          children: [
            Row(
              children: [
                TaskIconTile(icon, tone: tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        detail,
                        style: TextStyle(color: tones.ink2, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (status.usable) ...[
          const SizedBox(height: 14),
          Text(
            'Daftar ulang bila wajah berubah banyak, misalnya setelah memakai '
            'kacamata.',
            style: TextStyle(color: tones.ink2, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
