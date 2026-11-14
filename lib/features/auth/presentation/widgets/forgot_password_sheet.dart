import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';

/// There is no reset endpoint yet (no e-mail provider decided), so the sheet
/// sends the user to their group admin instead.
class ForgotPasswordSheet extends StatelessWidget {
  const ForgotPasswordSheet({super.key});

  static Future<void> show(BuildContext context) => showAppBottomSheet<void>(
    context: context,
    child: const ForgotPasswordSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lupa password?',
              style: TextStyle(
                color: tones.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hubungi admin grup Anda untuk mengatur ulang password. '
              'Reset lewat e-mail belum tersedia.',
              style: TextStyle(color: tones.ink2, fontSize: 15),
            ),
            const SizedBox(height: 12),
            AppTaskButton(
              label: 'Mengerti',
              size: AppTaskButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
