import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/admin_page_chrome.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/presentation/extensions/shift_ui_extension.dart';

/// One shift row: a colour bar, the name, and "07:00–15:00 · 8 jam" (or
/// "berakhir besok" for an overnight shift). Tappable only for managers.
class ShiftCard extends StatelessWidget {
  const ShiftCard({required this.shift, super.key, this.onTap});

  final ShiftEntity shift;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final detail = shift.endsNextDay
        ? '${shift.displayTimeRange} · berakhir besok'
        : shift.displaySchedule;
    return AdminListTile(
      onTap: onTap,
      semanticLabel: '${shift.name}, $detail',
      leading: Container(
        key: const ValueKey('shift_color_tile'),
        width: 14,
        height: 40,
        decoration: BoxDecoration(
          color: shift.accentColor ?? tones.surface2,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      title: shift.name,
      subtitle: detail,
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right_rounded, color: tones.ink2),
    );
  }
}
