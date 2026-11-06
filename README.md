# Kawalo Mobile (Kawalo-V2.0)
Kawalo Version 2.0 - with new hope

A Flutter mobile application built with Feature-First and Clean Architecture.

---

## Quick Start (Developer Setup)

Ikuti langkah mudah di bawah ini untuk memulai pengembangan:

### 1. Siapkan Environment Konfigurasi
Salin file template environment development lokal:
```bash
cp .env.dev.example .env.dev
```
*(Sesuaikan variabel di dalam `.env.dev` jika Anda memerlukan endpoint backend custom).*

### 2. Unduh Dependensi
```bash
flutter pub get
```

### 3. Jalankan Aplikasi
* **Menggunakan VS Code (Rekomendasi)**:
  Buka tab **Run & Debug** (F5) dan pilih target:
  - `Kawalo Mobile (Dev)`
  - `Kawalo Mobile (Staging)`
  - `Kawalo Mobile (Prod)`

* **Menggunakan Terminal / CLI**:
  ```bash
  # Development:
  flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev

  # Staging:
  flutter run -t lib/main_staging.dart --dart-define-from-file=.env.staging

  # Production:
  flutter run -t lib/main_prod.dart --dart-define-from-file=.env.prod
  ```

---

## Panduan Build Rilis & Keamanan
Untuk detail mengenai *build flavors*, *obfuscation*, *Quality Gates*, dan rilis APK/AAB/IPA otomatis, silakan baca [BUILD_GUIDE.md](BUILD_GUIDE.md).
