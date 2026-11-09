import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';

/// Konten gambar satu halaman `AppImageViewer` (jaringan, berkas lokal, atau
/// placeholder). [onImageResolved] dipanggil dengan provider gambar yang
/// berhasil dirujuk agar pemilik dapat mencatat ukuran aslinya.
class ImageViewerImageContent extends StatelessWidget {
  const ImageViewerImageContent({
    required this.imageUrl,
    required this.onImageResolved,
    super.key,
  });

  final String imageUrl;
  final ValueChanged<ImageProvider> onImageResolved;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        imageBuilder: (context, imageProvider) {
          onImageResolved(imageProvider);
          return Image(image: imageProvider, fit: BoxFit.contain);
        },
        placeholder: (_, _) => const Center(
          child: AppImagePlaceholder(width: 120, height: 120, iconSize: 48),
        ),
        errorWidget: (_, _, _) => const Center(
          child: AppImagePlaceholder(width: 120, height: 120, iconSize: 48),
        ),
      );
    }

    if (!kIsWeb && File(imageUrl).existsSync()) {
      final fileImage = FileImage(File(imageUrl));
      onImageResolved(fileImage);
      return Image(
        image: fileImage,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: AppImagePlaceholder(width: 120, height: 120, iconSize: 48),
        ),
      );
    }

    return const Center(
      child: AppImagePlaceholder(width: 120, height: 120, iconSize: 48),
    );
  }
}
