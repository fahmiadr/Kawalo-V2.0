import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';

/// One announcement in the Informasi list (redesign 2026): category pill,
/// author and date, title and the first line of the text. Photos, files and
/// actions live on the detail screen.
class InformationCard extends StatelessWidget {
  const InformationCard({
    required this.item,
    super.key,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isSelectable = true,
  });

  final InformationItemEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  /// Whether the signed-in user may select this card (only cards they may
  /// delete); unselectable cards are dimmed in selection mode.
  final bool isSelectable;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final text = item.text?.trim() ?? '';
    final attachments = [
      if (item.photos.isNotEmpty) '${item.photos.length} foto terlampir',
      if (item.hasFileAttachment) 'berkas lampiran tersedia',
    ];
    final semanticLabel = [
      'Informasi ${item.displayTitle}',
      'kategori ${item.typeLabel}',
      'dibuat oleh ${item.displayUserName}',
      'tanggal ${item.displayFeedDt}',
      ...attachments,
      if (isSelected) 'terpilih',
    ].join(', ');

    final card = AppCard(
      onPressed: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      color: isSelected ? tones.ptt.soft : tones.surface,
      border: BorderSide(
        color: isSelected ? tones.ptt.color : tones.line,
        width: isSelected ? 2 : 1,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSelectionMode) ...[
            _buildSelectionLeading(tones),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AppStatusPill(label: item.typeLabel),
                    if (item.hasPhotos || item.hasFileAttachment) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.attach_file_rounded,
                        size: 16,
                        color: tones.ink2,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.listMeta,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tones.ink2, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tones.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tones.ink2, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (isSelectionMode && !isSelectable) {
      return Opacity(opacity: AppStateLayer.disabledOpacity, child: card);
    }
    return card;
  }

  Widget _buildSelectionLeading(KawaloTones tones) {
    Widget circle(Color color, Widget child) => Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
    if (!isSelectable) {
      return circle(
        tones.surface2,
        Icon(Icons.lock_outline_rounded, size: 18, color: tones.ink3),
      );
    }
    return AppSelectionLeading(
      selected: isSelected,
      selectedChild: circle(
        tones.ptt.color,
        Icon(Icons.check_rounded, size: 20, color: tones.ptt.on),
      ),
      child: circle(
        tones.surface2,
        Icon(Icons.circle_outlined, size: 20, color: tones.ink3),
      ),
    );
  }
}
