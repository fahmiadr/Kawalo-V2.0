import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_detail_screen.dart'
    show IncidentDetailScreen;

/// Bubble pesan diskusi pada thread insiden [IncidentDetailScreen].
///
/// Membedakan pengirim saat ini (isMe) vs pengguna lain / admin,
/// mendukung lampiran foto galeri, serta reflow header otomatis saat
/// penskalaan teks 200%.
class IncidentThreadBubble extends StatelessWidget {
  /// Membuat instance [IncidentThreadBubble].
  const IncidentThreadBubble({
    required this.reply,
    required this.isMe,
    super.key,
  });

  /// Entitas pesan balasan.
  final IncidentReplyEntity reply;

  /// Penanda apakah pesan ini dikirimkan oleh pengguna yang sedang aktif
  /// (sesi lokal).
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isEnlargedText = textScale > 1.3;

    final hour = reply.createdAt.hour.toString().padLeft(2, '0');
    final minute = reply.createdAt.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';
    final roleUpper = reply.senderRole.toUpperCase();
    final isAdmin = roleUpper == 'ADMIN';

    final bubbleColor =
        isMe ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh;
    final textColor =
        isMe ? colorScheme.onPrimaryContainer : colorScheme.onSurface;
    final metaColor = isMe
        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;

    final roleBadge = AppTag(
      label: isAdmin ? 'ADMIN' : 'PETUGAS',
      variant: isAdmin ? AppTagVariant.tertiary : AppTagVariant.secondary,
      size: AppTagSize.small,
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.space50,
          horizontal: AppSpacing.space200,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.all(AppSpacing.space150),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMe ? AppRadius.lg : AppRadius.xs),
            bottomRight: Radius.circular(isMe ? AppRadius.xs : AppRadius.lg),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Nama Pengirim + Role Badge + Waktu (Reflow-aware)
            if (isEnlargedText) ...[
              Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          reply.senderName,
                          style: emphasizedScale.labelMedium.copyWith(
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.hGapXs,
                      roleBadge,
                    ],
                  ),
                  AppSpacing.vGap25,
                  Text(
                    formattedTime,
                    style: typeScale.labelSmall.copyWith(
                      color: metaColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      reply.senderName,
                      style: emphasizedScale.labelMedium.copyWith(
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.hGapXs,
                  roleBadge,
                  AppSpacing.hGapSm,
                  Text(
                    formattedTime,
                    style: typeScale.labelSmall.copyWith(
                      color: metaColor,
                    ),
                  ),
                ],
              ),
            ],

            // Pesan Teks
            if (reply.message.trim().isNotEmpty) ...[
              AppSpacing.vGap50,
              SelectableText(
                reply.message,
                style: typeScale.bodyMedium.copyWith(
                  color: textColor,
                ),
              ),
            ],

            // Galeri Foto Lampiran Balasan
            if (reply.photos.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Wrap(
                spacing: AppSpacing.space100,
                runSpacing: AppSpacing.space100,
                alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                children: List.generate(reply.photos.length, (photoIdx) {
                  final photoUrl = reply.photos[photoIdx];
                  return GestureDetector(
                    onTap: () {
                      AppImageViewer.show(
                        context,
                        imageUrls: reply.photos,
                        initialIndex: photoIdx,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: AppRadius.borderMedium,
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(
                          width: 80,
                          height: 80,
                          child: AppImagePlaceholder(),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
