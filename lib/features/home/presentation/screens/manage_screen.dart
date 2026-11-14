import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/attendance_location_screen.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/attendance_setting_screen.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/manual_requests_screen.dart';
import 'package:kawalo_mobile/features/forecast/presentation/screens/forecast_screen.dart';
import 'package:kawalo_mobile/features/group/presentation/screens/personnel_screen.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/screens/schedule_admin_screen.dart';
import 'package:kawalo_mobile/features/shift/presentation/screens/shift_screen.dart';

/// "Kelola" (ADMIN/SUPER_ADMIN only, from the "Lainnya" card): one entry per
/// existing admin screen. Replaces the old Beranda "Manajemen" section.
class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.manage),
    builder: (_) => const ManageScreen(),
  );

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    void push(Route<void> route) => Navigator.of(context).push(route);

    final items = <(IconData, String, String, VoidCallback)>[
      (
        Icons.calendar_month_outlined,
        'Shift',
        'Jam kerja tiap shift',
        () => push(ShiftScreen.route()),
      ),
      (
        Icons.group_outlined,
        'Jadwal Tim',
        'Susun jadwal anggota',
        () => push(
          ScheduleAdminScreen.route(
            onForecast: (ctx) => Navigator.of(ctx).push(ForecastScreen.route()),
          ),
        ),
      ),
      (
        Icons.auto_fix_high_outlined,
        'Forecast Jadwal',
        'Buat jadwal otomatis',
        () => push(ForecastScreen.route()),
      ),
      (
        Icons.face_outlined,
        'Absen Manual',
        'Laporan wajah gagal',
        () => push(ManualRequestsScreen.route()),
      ),
      (
        Icons.location_on_outlined,
        'Titik Absen',
        'Satu titik dan radius untuk semua shift',
        () => push(AttendanceLocationScreen.route()),
      ),
      (
        Icons.shield_outlined,
        'Batas Kemiripan Wajah',
        'Pengaturan absensi wajah',
        () => push(AttendanceSettingScreen.route()),
      ),
      (
        Icons.insert_chart_outlined,
        'Laporan Absensi',
        'Ringkasan dan rincian',
        () => push(AttendanceScreen.route()),
      ),
      (
        Icons.group_outlined,
        'Personil',
        'Anggota grup',
        () => push(PersonnelScreen.route()),
      ),
      (
        Icons.map_outlined,
        'Titik Patroli',
        'Titik dan radius patroli',
        () => AppSnackbar.showInProgress(context),
      ),
    ];

    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppBar(
        backgroundColor: tones.background,
        title: const Text('Kelola'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final (icon, title, subtitle, onTap) = items[i];
          return Material(
            color: tones.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: tones.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tones.adm.soft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, size: 20, color: tones.adm.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: tones.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(color: tones.ink2, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: tones.ink2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
