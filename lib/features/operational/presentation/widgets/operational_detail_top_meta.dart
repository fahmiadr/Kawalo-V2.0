import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

/// Komponen bagian metadata atas pada halaman detail operasional tenaga kerja,
/// memuat tag nama grup.
class OperationalDetailTopMeta extends StatelessWidget {
  /// Membuat instance [OperationalDetailTopMeta].
  const OperationalDetailTopMeta({required this.item, super.key});

  /// Data tenaga kerja operasional yang ditampilkan.
  final OperationalItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AppTag(
        label: item.displayGroupName,
        variant: AppTagVariant.secondary,
      ),
    );
  }
}
