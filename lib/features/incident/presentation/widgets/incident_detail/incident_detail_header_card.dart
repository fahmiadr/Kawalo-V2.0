import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_location_chip.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_thread_bubble.dart';

/// Top of the incident thread: photos, status and reporter, description,
/// location with a "Peta" button, then the "Balasan" section label.
class IncidentDetailHeaderCard extends StatelessWidget {
  const IncidentDetailHeaderCard({
    required this.incident,
    required this.repliesCount,
    super.key,
    this.launcher = const DefaultAppLauncherService(),
  });

  final IncidentEntity incident;
  final int repliesCount;
  final AppLauncherService launcher;

  Future<void> _openMap(BuildContext context, double lat, double long) async {
    final opened = await launcher.openMap(
      latitude: lat,
      longitude: long,
      title: incident.displayTitle,
    );
    if (!opened && context.mounted) {
      AppSnackbar.show(context, message: 'Aplikasi peta tidak dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final lat = incident.glat;
    final long = incident.glong;
    final description = incident.description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (incident.photos.isNotEmpty) ...[
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: incident.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _Photo(photos: incident.photos, index: i),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          incident.displayTitle,
          style: TextStyle(
            color: tones.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AppStatusPill(
              label: incident.displayStatusLabel,
              kind: incident.isOpen ? AppStatusKind.warn : AppStatusKind.ok,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${incident.displayReporter} · '),
                    TextSpan(
                      text: formatIncidentClock(incident.createdAt),
                      style: AppTheme.monoFigures,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tones.ink2, fontSize: 14),
              ),
            ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 14),
          SelectableText(
            description,
            style: TextStyle(color: tones.ink, fontSize: 15, height: 1.45),
          ),
        ],
        if (lat != null && long != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Flexible(
                child: AppStatusPill(
                  label: formatIncidentCoordinates(lat, long),
                  icon: Icons.place_outlined,
                ),
              ),
              const SizedBox(width: 10),
              AppTaskButton(
                label: 'Peta',
                variant: AppTaskButtonVariant.secondary,
                size: AppTaskButtonSize.small,
                semanticLabel: 'Buka lokasi insiden di peta',
                onPressed: () => unawaited(_openMap(context, lat, long)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          repliesCount > 0 ? 'BALASAN ($repliesCount)' : 'BALASAN',
          style: TextStyle(
            color: tones.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.84,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photos, required this.index});

  final List<String> photos;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Semantics(
      button: true,
      label: 'Lihat foto insiden ke-${index + 1}',
      child: GestureDetector(
        onTap: () => AppImageViewer.show(
          context,
          imageUrls: photos,
          initialIndex: index,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: photos[index],
            width: 150,
            height: 110,
            fit: BoxFit.cover,
            placeholder: (_, _) => const SizedBox(
              width: 150,
              height: 110,
              child: AppImagePlaceholder(),
            ),
            errorWidget: (_, _, _) => Container(
              width: 150,
              height: 110,
              color: tones.surface2,
              child: Icon(Icons.broken_image_outlined, color: tones.ink3),
            ),
          ),
        ),
      ),
    );
  }
}
