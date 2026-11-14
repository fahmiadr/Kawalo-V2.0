import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

/// One row of the Buku Tamu list (redesign 2026): initials, name, type and
/// destination, entry time and the presence pill.
class GuestCard extends StatelessWidget {
  const GuestCard({
    required this.item,
    super.key,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isSelectable = true,
  });

  final GuestItemEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  /// Whether the signed-in user may select this row (only rows they may
  /// delete); unselectable rows are dimmed in selection mode.
  final bool isSelectable;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final selectedInfo = isSelected ? ', terpilih' : '';
    final semanticLabel =
        'Data tamu ${item.displayName}, jenis ${item.displayGuestType}, '
        'tujuan ${item.displayDestination}, masuk ${item.entryClock}, '
        'status ${item.presenceLabel}$selectedInfo';

    final card = AppCard(
      onPressed: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      color: isSelected ? tones.gst.soft : tones.surface,
      border: BorderSide(
        color: isSelected ? tones.gst.color : tones.line,
        width: isSelected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildLeading(tones),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tones.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.displayGuestType} · ${item.displayDestination}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tones.ink2, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.entryClock,
                style: AppTheme.monoFigures.copyWith(
                  color: tones.ink2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              AppStatusPill(label: item.presenceLabel, kind: _pillKind(item)),
            ],
          ),
        ],
      ),
    );

    if (isSelectionMode && !isSelectable) {
      return Opacity(opacity: AppStateLayer.disabledOpacity, child: card);
    }
    return card;
  }

  Widget _buildLeading(KawaloTones tones) {
    final avatar = _circle(
      color: tones.ptt.soft,
      child: Text(
        item.initials,
        style: TextStyle(
          color: tones.ptt.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (!isSelectionMode) return avatar;
    if (!isSelectable) {
      return _circle(
        color: tones.surface2,
        child: Icon(Icons.lock_outline_rounded, size: 18, color: tones.ink3),
      );
    }
    return AppSelectionLeading(
      selected: isSelected,
      selectedChild: _circle(
        color: tones.gst.color,
        child: Icon(Icons.check_rounded, size: 20, color: tones.gst.on),
      ),
      child: avatar,
    );
  }

  static Widget _circle({required Color color, required Widget child}) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }
}

AppStatusKind _pillKind(GuestItemEntity item) {
  if (item.isExited) return AppStatusKind.neutral;
  if (item.isConfirmed) return AppStatusKind.ok;
  return AppStatusKind.warn;
}
