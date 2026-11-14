import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';

/// "15.02", the Indonesian clock notation used across the redesign.
String formatIncidentClock(DateTime time) {
  final local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}.'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// Reply bubble (`.bub` in `rd.css`); the guard's own replies sit on the
/// right in the incident tone.
class IncidentThreadBubble extends StatelessWidget {
  const IncidentThreadBubble({
    required this.reply,
    required this.isMe,
    super.key,
  });

  final IncidentReplyEntity reply;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final isAdmin = reply.senderRole.toUpperCase() == 'ADMIN';
    final sender = isMe ? 'Anda' : reply.senderName;
    final meta = [sender, if (isAdmin && !isMe) 'Admin'].join(' · ');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? tones.inc.soft : tones.surface,
          borderRadius: BorderRadius.circular(18),
          border: isMe ? null : Border.all(color: tones.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$meta · '),
                  TextSpan(
                    text: formatIncidentClock(reply.createdAt),
                    style: AppTheme.monoFigures,
                  ),
                ],
              ),
              style: TextStyle(
                color: tones.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (reply.message.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              SelectableText(
                reply.message,
                style: TextStyle(color: tones.ink, fontSize: 14, height: 1.4),
              ),
            ],
            if (reply.photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < reply.photos.length; i++)
                    _ReplyPhoto(photos: reply.photos, index: i),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyPhoto extends StatelessWidget {
  const _ReplyPhoto({required this.photos, required this.index});

  final List<String> photos;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Semantics(
      button: true,
      label: 'Lihat foto balasan ke-${index + 1}',
      child: GestureDetector(
        onTap: () => AppImageViewer.show(
          context,
          imageUrls: photos,
          initialIndex: index,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: photos[index],
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (_, _) => const SizedBox.square(
              dimension: 80,
              child: AppImagePlaceholder(),
            ),
            errorWidget: (_, _, _) => Container(
              width: 80,
              height: 80,
              color: tones.surface2,
              child: Icon(Icons.broken_image_outlined, color: tones.ink3),
            ),
          ),
        ),
      ),
    );
  }
}
