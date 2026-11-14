import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_inline_banner.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_thread_bubble.dart';

/// Replaces the composer once the incident is resolved: replies are closed.
class IncidentResolvedBanner extends StatelessWidget {
  const IncidentResolvedBanner({required this.incident, super.key});

  final IncidentEntity incident;

  @override
  Widget build(BuildContext context) {
    final resolvedAt = incident.resolvedAt;
    final when = resolvedAt != null
        ? ' pukul ${formatIncidentClock(resolvedAt)}'
        : '';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: AppInlineBanner(
          message:
              'Diselesaikan ${incident.displayResolver}$when. '
              'Balasan ditutup.',
          kind: AppInlineBannerKind.info,
          icon: Icons.check_circle_outline_rounded,
        ),
      ),
    );
  }
}
