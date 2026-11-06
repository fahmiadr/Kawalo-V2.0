/// Target environment aplikasi (Dev, Staging, Prod).
enum AppEnvironment {
  dev('.env.dev'),
  staging('.env.staging'),
  prod('.env.prod');

  const AppEnvironment(this.envFileName);

  /// Nama file konfigurasi dotenv yang berkorespondensi.
  final String envFileName;

  /// Mengecek apakah environment aktif adalah development.
  bool get isDev => this == AppEnvironment.dev;

  /// Mengecek apakah environment aktif adalah staging.
  bool get isStaging => this == AppEnvironment.staging;

  /// Mengecek apakah environment aktif adalah production.
  bool get isProd => this == AppEnvironment.prod;
}
