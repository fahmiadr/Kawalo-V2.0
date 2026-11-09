import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_action_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_source_bottom_sheet.dart';

/// Memilih foto (kamera/galeri) lalu menambahkannya ke [cubit].
Future<void> pickInformationFormPhotos(
  BuildContext context,
  InformationFormCubit cubit,
  MediaPickerService mediaPicker,
) async {
  final source = await InformationPhotoSourceBottomSheet.show(context);
  if (source == null || !context.mounted) return;

  if (cubit.state.isPhotoLimitReached) {
    AppSnackbar.show(
      context,
      message:
          'Maksimal '
          '${InformationFormState.maxPhotosLimit} foto dapat dilampirkan.',
    );
    return;
  }

  try {
    final remainingSlots = cubit.state.remainingPhotoSlots;
    List<AppMediaFile> files;

    if (source == InformationPhotoSource.camera) {
      files = await mediaPicker.captureMultiImagesFromCamera(
        context,
        alreadyAttachedCount: cubit.state.photos.length,
      );
    } else {
      files = await mediaPicker.pickMultiImagesFromGallery(
        limit: remainingSlots,
      );
    }

    if (files.isEmpty || !context.mounted) return;

    final mediaItems = files
        .map(InformationFormMediaItem.fromAppMediaFile)
        .toList();
    final addedCount = cubit.onAddMediaPhotos(mediaItems);
    if (!context.mounted) return;

    if (addedCount > 0) {
      AppSnackbar.show(
        context,
        message: addedCount == 1
            ? 'Foto berhasil ditambahkan ke lampiran.'
            : '$addedCount foto berhasil ditambahkan ke lampiran.',
      );
    } else if (cubit.state.photosError != null) {
      AppSnackbar.show(context, message: cubit.state.photosError!);
    }
  } on Exception catch (_) {
    if (context.mounted) {
      AppSnackbar.show(
        context,
        message: 'Gagal memproses foto. Silakan coba lagi.',
      );
    }
  }
}

/// Memilih satu dokumen lampiran lalu menyimpannya ke [cubit].
Future<void> pickInformationFormDocument(
  BuildContext context,
  InformationFormCubit cubit,
  MediaPickerService mediaPicker,
) async {
  final file = await mediaPicker.pickDocumentFile();
  if (file == null || !context.mounted) return;

  final mediaItem = InformationFormMediaItem.fromAppMediaFile(file);
  cubit.onSetDocumentMedia(mediaItem);

  if (context.mounted) {
    AppSnackbar.show(
      context,
      message: 'Dokumen "${mediaItem.name}" berhasil dipilih.',
    );
  }
}

/// Meminta konfirmasi lalu menghapus seluruh foto lampiran dari [cubit].
Future<void> clearAllInformationFormPhotos(
  BuildContext context,
  InformationFormCubit cubit,
) async {
  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: 'Hapus semua foto?',
    message: 'Seluruh foto lampiran akan dihapus dari formulir.',
    confirmText: 'Hapus semua',
  );
  if (confirmed == true && context.mounted) {
    cubit.onClearAllPhotos();
    AppSnackbar.show(context, message: 'Seluruh foto lampiran telah dihapus.');
  }
}

/// Membuka penampil gambar untuk foto pada [index] bila sudah selesai dimuat.
void viewInformationFormPhoto(
  BuildContext context,
  InformationFormCubit cubit,
  int index,
) {
  final photos = cubit.state.photos;
  if (index < 0 || index >= photos.length) return;
  if (photos[index].isLoading) return;
  AppImageViewer.show(
    context,
    imageUrls: photos.map((p) => p.displaySource).toList(),
    initialIndex: index,
    heroTagPrefix: 'info_form_photo',
  );
}

/// Menampilkan menu aksi (lihat, jadikan utama, geser, hapus) untuk foto.
void showInformationFormPhotoActionMenu(
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
