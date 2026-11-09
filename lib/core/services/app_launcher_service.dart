/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:kawalo_mobile/core/widgets/app_static_map.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mode peluncuran URL di peramban atau aplikasi eksternal.
///
/// Menentukan cara tautan web dibuka oleh sistem operasi: di dalam
/// web view internal aplikasi, peramban bawaan eksternal, atau in-app
/// browser view (Safari View Controller di iOS atau Custom Tabs di Android).
enum AppLaunchMode {
  /// Menyerahkan penanganan peluncuran ke platform bawaan.
  platformDefault,

  /// Membuka tautan di dalam web view internal aplikasi.
  inAppWebView,

  /// Membuka tautan di luar aplikasi melalui peramban eksternal perangkat.
  externalApplication,

  /// Membuka tautan via in-app browser (Safari View Controller / Custom Tabs).
  inAppBrowserView,
}

extension _AppLaunchModeX on AppLaunchMode {
  LaunchMode toUrlLauncher() {
    switch (this) {
      case AppLaunchMode.platformDefault:
        return LaunchMode.platformDefault;
      case AppLaunchMode.inAppWebView:
        return LaunchMode.inAppWebView;
      case AppLaunchMode.externalApplication:
        return LaunchMode.externalApplication;
      case AppLaunchMode.inAppBrowserView:
        return LaunchMode.inAppBrowserView;
    }
  }
}

/// Memeriksa apakah sebuah [url] dapat diluncurkan oleh sistem operasi.
///
/// Mengembalikan `true` jika sistem operasi memiliki penangan intent
/// atau aplikasi yang terdaftar untuk menangani skema dari [url].
typedef CanLaunchUrlFn = Future<bool> Function(Uri url);

/// Meluncurkan [url] dengan konfigurasi [mode] tertentu.
///
/// Parameter [webOnlyWindowName] digunakan untuk menentukan target window
/// saat berjalan pada platform web.
///
/// Mengembalikan `true` jika peluncuran berhasil diinisiasi oleh sistem.
typedef LaunchUrlFn =
    Future<bool> Function(
      Uri url, {
      LaunchMode mode,
      String? webOnlyWindowName,
    });

/// Kontrak layanan peluncur intent eksternal terpadu di aplikasi Kawalo.
///
/// Mengelola seluruh interaksi intent keluar dari aplikasi, meliputi:
/// - Pengaturan perizinan aplikasi di sistem operasi ([openAppSettings]).
/// - Pengaturan GPS dan sensor lokasi perangkat ([openLocationSettings]).
/// - Penampil koordinat pada aplikasi peta eksternal ([openMap]).
/// - Peramban web eksternal maupun in-app ([openBrowser]).
/// - Aplikasi pemanggil telepon perangkat ([openDialer]).
/// - Aplikasi pengirim surel (*email client*) perangkat ([openEmail]).
///
/// Seluruh metode dirancang mengikuti pola Command Invocation dan mengembalikan
/// `Future<bool>` yang menandakan keberhasilan inisiasi intent tanpa melempar
/// unhandled exception ke lapisan UI.
@immutable
abstract interface class AppLauncherService {
  /// Membuka halaman pengaturan aplikasi pada sistem operasi.
  ///
  /// Berguna untuk mengarahkan pengguna secara langsung ke menu izin aplikasi
  /// ketika izin esensial (seperti kamera atau lokasi) dinonaktifkan.
  ///
  /// Mengembalikan `true` jika halaman pengaturan berhasil dibuka.
  Future<bool> openAppSettings();

  /// Membuka halaman pengaturan sakelar GPS atau lokasi perangkat.
  ///
  /// Berguna saat perangkat berada dalam mode hemat daya atau sensor lokasi
  /// dimatikan oleh pengguna sebelum melakukan absensi atau pelacakan.
  ///
  /// Mengembalikan `true` jika halaman pengaturan lokasi berhasil dibuka.
  Future<bool> openLocationSettings();

  /// Membuka koordinat [latitude] dan [longitude] pada aplikasi peta eksternal.
  ///
  /// Menampilkan penanda peta opsional dengan label [title] jika diberikan.
  ///
  /// Memvalidasi batas fisik koordinat bumi melalui
  /// [AppSanitizer.isValidCoordinates].
  ///
  /// Mengembalikan `false` jika koordinat tidak valid (misal `NaN`,
  /// `isInfinite`, atau berada di luar rentang geografis $-90.0 \dots 90.0$
  /// latitude dan $-180.0 \dots 180.0$ longitude).
  ///
  /// Menggunakan urutan fallback platform:
  /// 1. Apple Maps pada platform iOS dan macOS.
  /// 2. Intent skema `geo:` pada platform Android.
  /// 3. Google Maps Web universal untuk seluruh platform lain atau jika
  ///    aplikasi peta native tidak terpasang.
  ///
  /// Mengembalikan `true` jika aplikasi peta berhasil dibuka.
  Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? title,
  });

  /// Membuka tautan [url] web di peramban dengan [mode] yang ditentukan.
  ///
  /// Parameter [mode] menentukan target peramban, dengan nilai default
  /// [AppLaunchMode.externalApplication].
  ///
  /// Memvalidasi bahwa [url] memiliki skema mutlak sebelum mencoba
  /// meluncurkan. Mengembalikan `false` jika [url] tidak memiliki skema atau
  /// jika sistem operasi gagal meluncurkan tautan.
  Future<bool> openBrowser(
    Uri url, {
    AppLaunchMode mode = AppLaunchMode.externalApplication,
  });

  /// Membuka aplikasi pemanggil telepon (*Dialer*) dengan [phoneNumber].
  ///
  /// Membersihkan dan menormalisasi [phoneNumber] menggunakan
  /// [AppSanitizer.cleanPhone] sesuai standar penomoran E.164.
  ///
  /// Mengembalikan `false` jika [phoneNumber] kosong atau tidak memuat digit
  /// angka yang valid. Mengembalikan `true` jika pemanggil telepon berhasil
  /// diluncurkan.
  Future<bool> openDialer(String phoneNumber);

  /// Membuka aplikasi surel (*Email Client*) ke alamat tujuan [email].
  ///
  /// Menyertakan [subject] dan [body] surel jika diberikan.
  ///
  /// Membersihkan dan memvalidasi format [email] menggunakan
  /// [AppSanitizer.cleanEmail] sesuai format standar RFC 5322.
  ///
  /// Mengembalikan `false` jika format [email] tidak valid. Mengembalikan
  /// `true` jika aplikasi komposer surel berhasil dibuka.
  Future<bool> openEmail(String email, {String? subject, String? body});
}

/// Implementasi standar [AppLauncherService] berbasis platform dan
/// `url_launcher`.
///
/// Menyediakan implementasi aman (*fail-safe*) yang menangani seluruh
/// kegagalan platform secara internal tanpa melempar exception ke lapisan UI.
///
/// Mendukung Pure Dependency Injection dengan konstruktor konstan
/// [DefaultAppLauncherService.new]. Seluruh delegator fungsi dan platform
/// geolocator dapat diinjeksi untuk kebutuhan pengujian unit tanpa
/// ketergantungan pada platform channels.
///
/// Contoh penggunaan dengan Pure Dependency Injection:
///
/// ```dart
/// class MyWidget extends StatelessWidget {
///   const MyWidget({
///     super.key,
///     this.launcherService = const DefaultAppLauncherService(),
///   });
///
///   final AppLauncherService launcherService;
///
///   Future<void> _handleOpenMap() async {
///     await launcherService.openMap(
///       latitude: -6.2088,
///       longitude: 106.8456,
///       title: 'Kantor Kawalo',
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ElevatedButton(
///       onPressed: _handleOpenMap,
///       child: const Text('Buka Peta'),
///     );
///   }
/// }
/// ```
@immutable
final class DefaultAppLauncherService implements AppLauncherService {
  /// Membuat instans [DefaultAppLauncherService].
  ///
  /// Menerima delegator fungsi [canLaunch] dan [launch] serta
  /// [geolocatorPlatform] opsional untuk memfasilitasi pengujian unit
  /// terisolasi. Jika [geolocatorPlatform] bernilai `null`, instans akan
  /// menggunakan [GeolocatorPlatform.instance] bawaan secara dinamis saat
  /// runtime.
  const DefaultAppLauncherService({
    CanLaunchUrlFn canLaunch = canLaunchUrl,
    LaunchUrlFn launch = launchUrl,
    GeolocatorPlatform? geolocatorPlatform,
  }) : _canLaunch = canLaunch,
       _launch = launch,
       _geolocatorPlatform = geolocatorPlatform;

  final CanLaunchUrlFn _canLaunch;
  final LaunchUrlFn _launch;
  final GeolocatorPlatform? _geolocatorPlatform;

  GeolocatorPlatform get _geolocator =>
      _geolocatorPlatform ?? GeolocatorPlatform.instance;

  Future<bool> _safePlatformAction(Future<bool> Function() platformFn) async {
    try {
      return await platformFn();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() =>
      _safePlatformAction(_geolocator.openAppSettings);

  @override
  Future<bool> openLocationSettings() =>
      _safePlatformAction(_geolocator.openLocationSettings);

  @override
  Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? title,
  }) async {
    if (!AppSanitizer.isValidCoordinates(
      latitude: latitude,
      longitude: longitude,
    )) {
      return false;
    }

    final coords = '$latitude,$longitude';
    final hasTitle = title != null && title.isNotEmpty;

    // 1. Android geo URI (memicu intent pemilih peta bawaan perangkat)
    final geoUri = Uri(
      scheme: 'geo',
      path: coords,
      query: hasTitle
          ? 'q=$coords(${Uri.encodeComponent(title)})'
          : 'q=$coords',
    );

    // 2. Apple Maps URL (iOS & macOS)
    final appleMapsUri = Uri.https('maps.apple.com', '/', <String, String>{
      if (hasTitle) 'q': title,
      'll': coords,
    });

    // 3. Google Maps Web universal URL (Android, iOS, Web, Desktop)
    final googleMapsUrl = Uri.https(
      'www.google.com',
      '/maps/search/',
      <String, String>{
        'api': '1',
        'query': hasTitle ? '$coords ($title)' : coords,
      },
    );

    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        if (await openBrowser(appleMapsUri)) return true;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        if (await openBrowser(geoUri)) return true;
      }
    }

    return await openBrowser(googleMapsUrl);
  }

  @override
  Future<bool> openBrowser(
    Uri url, {
    AppLaunchMode mode = AppLaunchMode.externalApplication,
  }) async {
    if (!url.hasScheme || url.scheme.isEmpty) return false;
    try {
      if (await _canLaunch(url)) {
        return await _launch(url, mode: mode.toUrlLauncher());
      }
      return false;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openDialer(String phoneNumber) async {
    final cleanNumber = AppSanitizer.cleanPhone(phoneNumber);
    if (cleanNumber == null) return false;
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    return await openBrowser(uri);
  }

  @override
  Future<bool> openEmail(String email, {String? subject, String? body}) async {
    final cleanEmail = AppSanitizer.cleanEmail(email);
    if (cleanEmail == null) return false;
    final queryParameters = <String, String>{
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (body != null && body.isNotEmpty) 'body': body,
    };
    final uri = Uri(
      scheme: 'mailto',
      path: cleanEmail,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return await openBrowser(uri);
  }
}
