import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/incident_module.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_form_dialog.dart';

/// Halaman / dialog wrapper untuk pelaporan insiden baru operasional.
///
/// Menyediakan rute standar [route] yang mendelegasikan ke [IncidentFormDialog]
/// agar pengalaman antarmuka konsisten dan serasi dengan modul Guest dan
/// Information.
class CreateIncidentScreen extends StatelessWidget {
  /// Membuat instance [CreateIncidentScreen].
  const CreateIncidentScreen({super.key, this.cubit, this.mediaPickerService});

  /// Instance [IncidentFormCubit] opsional.
  final IncidentFormCubit? cubit;

  /// Layanan pemilihan media opsional untuk kamera & galeri.
  final MediaPickerService? mediaPickerService;

  /// Factory rute navigasi standar [CreateIncidentScreen].
  static Route<IncidentEntity?> route({
    IncidentFormCubit? cubit,
    MediaPickerService? mediaPickerService,
  }) {
    return AppPageRoute.forwardBackward<IncidentEntity?>(
      settings: const RouteSettings(name: AppRouteNames.incidentCreate),
      builder: (context) {
        if (cubit != null) {
          return IncidentFormDialog(
            cubit: cubit,
            mediaPickerService: mediaPickerService,
          );
        }
        final module = context.read<IncidentModule>();
        return BlocProvider<IncidentFormCubit>(
          create: (context) => module.createIncidentFormCubit(
            uploadRepository: context.read<UploadRepository>(),
          ),
          child: IncidentFormDialog(mediaPickerService: mediaPickerService),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IncidentFormDialog(
      cubit: cubit,
      mediaPickerService: mediaPickerService,
    );
  }
}
