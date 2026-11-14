import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_inline_banner.dart';

/// Shown while the realtime (SSE) stream reconnects.
class IncidentDetailReconnectingBanner extends StatelessWidget {
  const IncidentDetailReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: AppInlineBanner(
        message: 'Menyambung ulang… balasan baru belum tampil.',
        leading: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: tones.warn),
        ),
      ),
    );
  }
}
