# Build & Security Guide - Flavors & Code Obfuscation

## 1. Running Environments (Flavors)

Kawalo Mobile menggunakan arsitektur modern `--dart-define-from-file` untuk menginjeksi environment variable saat *compile-time*. File `.env.*` tidak lagi dibundle mentah ke dalam asset aplikasi demi keamanan kredensial.

> [!TIP]
> **VS Code**: Jika menggunakan VS Code, cukup pilih flavor dari menu *Run & Debug* (F5). Parameter `--dart-define-from-file` sudah otomatis terpasang via `.vscode/launch.json`.

### Development
```bash
flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev
```

### Staging
```bash
flutter run -t lib/main_staging.dart --dart-define-from-file=.env.staging
```

### Production
```bash
flutter run -t lib/main_prod.dart --dart-define-from-file=.env.prod
```

---

## 2. Secure Storage (JWT & Credentials)
Semua token sensitif disimpan di penyimpanan terenkripsi:
- **Android**: `EncryptedSharedPreferences` via Android Keystore.
- **iOS**: `Keychain` dengan proteksi `first_unlock`.

---

## 3. Production Release Build with Code Obfuscation

Untuk mencegah reverse engineering logika bisnis, jalankan build rilis dengan parameter resmi `--obfuscate` dan `--split-debug-info`:

### Build Release Otomatis (Single Unified Entry Point)
Gunakan satu perintah terpadu berbasis Dart dengan Quality Gates otomatis (`flutter analyze` & `flutter test`):
```bash
# Otomatis mendeteksi OS (Android di Windows/Linux, iOS di macOS):
dart run tool/build.dart

# Atau tentukan platform spesifik:
dart run tool/build.dart --platform=android
dart run tool/build.dart --platform=ios
dart run tool/build.dart --platform=android --type=apk
```

### Manual Build Commands
```bash
# Android App Bundle (AAB):
flutter build appbundle --release -t lib/main_prod.dart \
  --dart-define-from-file=.env.prod \
  --obfuscate \
  --split-debug-info=./build/symbols/android

# iOS IPA:
flutter build ipa --release -t lib/main_prod.dart \
  --dart-define-from-file=.env.prod \
  --obfuscate \
  --split-debug-info=./build/symbols/ios
```

> [!IMPORTANT]
> **Penyimpanan Simbol Debug (De-Symbolication)**:
> File simbol yang dihasilkan di `./build/symbols/android` dan `./build/symbols/ios` **TIDAK** boleh disertakan ke dalam publik. Simpan file ini secara privat di repository CI/CD atau upload ke dashboard crash reporting (Firebase Crashlytics / Sentry) untuk membaca stack trace dari pengguna produksi.

---

## 4. Debug Artifact & Logger Striping

1. **Dead-Code Elimination (Tree-Shaking)**:
   - Pada mode `--release`, konstanta `kDebugMode` otomatis bernilai `false` pada tahap kompilasi Dart AOT.
   - Kompiler secara fisik memotong (*dead-code stripping*) percabangan `if (kDebugMode)` sehingga tidak ada byte kode debug yang tersisa dalam biner mesin.

2. **Zero-Leak Logging**:
   - `LogInterceptor` pada `ApiClient` hanya diaktifkan saat `kDebugMode == true`.
   - Pada biner rilis produksi, tidak ada token otentikasi, URL request, payload body, maupun data rahasia personil yang dicetak ke Android Logcat atau iOS Console log.
