import 'package:kawalo_mobile/core/security/models/security_violation_type.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';

/// Ekstensi lapisan presentasi untuk [SecurityViolationType].
///
/// Menyediakan pemetaan teks antarmuka Material 3 (judul, deskripsi) dan ikon
/// representatif tanpa mencemari model domain di `core/security/models/`.
extension SecurityViolationUiExtension on SecurityViolationType {
  /// Judul pelanggaran keamanan untuk antarmuka pengguna.
  String get displayTitle => switch (this) {
        SecurityViolationType.rootOrJailbreak =>
          'Perangkat tidak memenuhi standar keamanan',
        SecurityViolationType.mockLocation => 'Lokasi tiruan terdeteksi',
        SecurityViolationType.unofficialStore =>
          'Aplikasi tidak resmi terdeteksi',
      };

  /// Deskripsi edukatif yang menjelaskan alasan penguncian dan tindakan
  /// perbaikan yang harus diambil pengguna.
  String get displayDescription => switch (this) {
        SecurityViolationType.rootOrJailbreak =>
          'Perangkat Anda terindikasi telah dimodifikasi. Demi '
              'melindungi keamanan data Anda, aplikasi '
              'tidak dapat dibuka di perangkat ini.',
        SecurityViolationType.mockLocation =>
          'Perangkat Anda menggunakan penyedia lokasi tiruan. Nonaktifkan '
              'aplikasi pemalsu lokasi atau opsi lokasi tiruan di '
              'pengaturan perangkat untuk melanjutkan.',
        SecurityViolationType.unofficialStore =>
          'Aplikasi ini tidak dipasang dari toko aplikasi resmi. Untuk '
              'melindungi data Anda dari risiko aplikasi modifikasi, pasang '
              'aplikasi resmi.',
      };

  /// Path vektor SVG representatif Kawalo yang menggambarkan tipe pelanggaran.
  String get icon => switch (this) {
        SecurityViolationType.rootOrJailbreak => KawaloVectors.shieldOffFilled,
        SecurityViolationType.mockLocation =>
          KawaloVectors.gpsDisconnectedFilled,
        SecurityViolationType.unofficialStore => KawaloVectors.shieldXFilled,
      };
}
