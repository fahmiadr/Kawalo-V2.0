import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';

/// App bar khusus untuk layar detail aktifitas operasional tenaga kerja
/// yang mengimplementasikan [AppHomeAppBar] dengan tombol kembali dan
/// tier status pembaruan waktu tanpa bilah pencarian.
class OperationalDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Membuat instance [OperationalDetailAppBar].
  const OperationalDetailAppBar({
    required this.greeting,
    this.title = 'Detail operasional',
    this.showBackButton = true,
    this.onBackPressed,
    super.key,
  });

  /// Status pembaruan waktu atau greeting di tier atas.
  final String greeting;

  /// Judul halaman pada tier kedua.
  final String title;

  /// Menentukan apakah tombol kembali ditampilkan.
  final bool showBackButton;

  /// Callback saat tombol navigasi kembali ditekan.
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppHomeAppBar.defaultPreferredHeight);

  @override
  Widget build(BuildContext context) {
    return AppHomeAppBar(
      greeting: greeting,
      title: title,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      showTrailing: false,
    );
  }
}
