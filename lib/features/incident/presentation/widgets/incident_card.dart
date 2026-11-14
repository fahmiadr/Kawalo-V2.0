import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';

/// One row of the incident list (`.it` in `rd.css`): tone icon, title,
/// reporter and time, status pill.
class IncidentCard extends StatelessWidget {
  const IncidentCard({required this.incident, required this.onTap, super.key});

  final IncidentEntity incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final photos = incident.photos.length;
    final subtitle = [
      incident.displayReporter,
      incident.displayRelativeTime,
      if (photos > 0) '$photos foto',
    ].join(' · ');

    return Semantics(
      button: true,
      label:
          'Insiden ${incident.displayTitle}, ${incident.displayStatusLabel}, '
          '$subtitle',
      excludeSemantics: true,
      child: Material(
        color: tones.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tones.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tones.inc.soft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.report_outlined,
                    size: 20,
                    color: tones.inc.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tones.ink2, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppStatusPill(
                  label: incident.displayStatusLabel,
                  kind: incident.isOpen ? AppStatusKind.warn : AppStatusKind.ok,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
