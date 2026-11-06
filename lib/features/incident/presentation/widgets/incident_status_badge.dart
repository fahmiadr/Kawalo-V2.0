import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';

/// Badge indikator status insiden (Terbuka / Selesai) yang mematuhi kontras
/// M3 dan WCAG AA.
///
/// Menggunakan [AppTag] standar sistem Kawalo untuk konsistensi visual dengan
/// fitur Guest.
class IncidentStatusBadge extends StatelessWidget {
  /// Membuat instance [IncidentStatusBadge].
  const IncidentStatusBadge({
    required this.status,
    this.size = AppTagSize.small,
    super.key,
  });

  /// Status insiden yang ditampilkan.
  final IncidentStatus status;

  /// Ukuran tag badge.
  final AppTagSize size;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == IncidentStatus.open;
    return AppTag(
      label: isOpen ? 'Terbuka' : 'Selesai',
      variant: isOpen ? AppTagVariant.error : AppTagVariant.primary,
      size: size,
    );
  }
}
