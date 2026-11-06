import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

/// Komponen bagian metadata atas pada halaman detail tamu,
/// memuat tag nama grup.
class GuestDetailTopMeta extends StatelessWidget {
  /// Membuat instance [GuestDetailTopMeta].
  const GuestDetailTopMeta({
    required this.item,
    super.key,
  });

  /// Data tamu yang ditampilkan.
  final GuestItemEntity item;

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: item.displayGroupName,
      variant: AppTagVariant.secondary,
    );
  }
}
