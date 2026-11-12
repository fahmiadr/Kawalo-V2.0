import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/face_photos_cubit.dart';

/// Gallery of a member's face registration photos. Tapping a thumbnail opens
/// the shared full-screen viewer.
class FacePhotosSheet extends StatelessWidget {
  const FacePhotosSheet({required this.name, required this.cubit, super.key});

  final String name;
  final FacePhotosCubit cubit;

  /// The sheet owns [cubit] and closes it (which deletes the temporary
  /// files) when dismissed.
  static Future<void> show({
    required BuildContext context,
    required String name,
    required FacePhotosCubit cubit,
  }) async {
    unawaited(cubit.load());
    try {
      await showAppBottomSheet<void>(
        context: context,
        child: FacePhotosSheet(name: name, cubit: cubit),
      );
    } finally {
      await cubit.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space200,
        0,
        AppSpacing.space200,
        AppSpacing.space300,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Foto registrasi wajah',
            style: theme.typography.emphasized.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            name,
            style: theme.typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap200,
          BlocBuilder<FacePhotosCubit, FacePhotosState>(
            bloc: cubit,
            builder: (context, state) => switch (state.phase) {
              FacePhotosPhase.loading => const Padding(
                padding: AppSpacing.paddingVertical200,
                child: Center(child: AppLoadingIndicator()),
              ),
              FacePhotosPhase.failure => _Message(
                state.errorMessage ?? 'Foto registrasi tidak dapat dimuat.',
              ),
              FacePhotosPhase.loaded when state.paths.isEmpty => const _Message(
                'Belum ada foto registrasi wajah untuk anggota ini.',
              ),
              FacePhotosPhase.loaded => Wrap(
                spacing: AppSpacing.space100,
                runSpacing: AppSpacing.space100,
                children: [
                  for (var i = 0; i < state.paths.length; i++)
                    _Thumbnail(
                      path: state.paths[i],
                      label:
                          'Foto registrasi ${i + 1} dari ${state.paths.length}',
                      onTap: () => AppImageViewer.show(
                        context,
                        imageUrls: state.paths,
                        initialIndex: i,
                      ),
                    ),
                ],
              ),
            },
          ),
          AppSpacing.vGap200,
          AppButton(
            style: AppButtonColor.tonal,
            shape: AppButtonShape.square,
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.path,
    required this.label,
    required this.onTap,
  });

  final String path;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: AppRadius.borderMedium,
          child: Image.file(
            File(path),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            cacheWidth: 288,
            errorBuilder: (_, _, _) => const SizedBox(width: 96, height: 96),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: AppSpacing.paddingVertical200,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.typeScale.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
