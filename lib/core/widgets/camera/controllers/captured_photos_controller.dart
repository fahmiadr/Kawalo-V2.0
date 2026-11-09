import 'dart:io' show File;

import 'package:flutter/painting.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';

/// Menyimpan daftar foto hasil jepretan, seleksinya, dan foto yang sedang
/// dianimasikan keluar.
///
/// Kelas ini tidak memicu rebuild; pemanggil (State) membungkus mutasi dengan
/// `setState` agar urutan pembaruan UI tetap sama persis.
class CapturedPhotosController {
  final List<AppMediaFile> captured = [];
  final List<AppMediaFile> selected = [];

  /// Path foto yang sedang menjalankan animasi pengempisan keluar.
  String? removingPath;

  bool canSelectMore(int maxSelectable) => selected.length < maxSelectable;

  /// Mengubah status seleksi [photo]. Mengembalikan `false` bila seleksi
  /// ditolak karena kuota penuh.
  bool toggleSelection(AppMediaFile photo, {required int maxSelectable}) {
    if (selected.contains(photo)) {
      selected.remove(photo);
      return true;
    }
    if (canSelectMore(maxSelectable)) {
      selected.add(photo);
      return true;
    }
    return false;
  }

  /// Menambahkan foto baru di posisi terdepan dan memilihnya selama kuota
  /// masih tersedia.
  void addCaptured(AppMediaFile photo, {required int maxSelectable}) {
    captured.insert(0, photo);
    if (canSelectMore(maxSelectable)) {
      selected.add(photo);
    }
  }

  /// Menghapus foto pada [index] seketika (tanpa animasi).
  void removeNow(int index) {
    final removed = captured.removeAt(index);
    selected.remove(removed);
  }

  /// Menandai [photo] sebagai sedang keluar dan melepasnya dari seleksi.
  void beginRemoval(AppMediaFile photo) {
    removingPath = photo.path;
    selected.remove(photo);
  }

  /// Melepas [photo] dari daftar setelah animasi keluar selesai.
  void finishRemoval(AppMediaFile photo) {
    captured.remove(photo);
    if (removingPath == photo.path) {
      removingPath = null;
    }
  }

  void clearSelection() => selected.clear();

  /// Menghapus berkas foto yang tidak diserahkan beserta cache gambarnya.
  void cleanupUnsubmitted() {
    for (final photo in captured) {
      if (photo.path != null) {
        try {
          final file = File(photo.path!);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } on Exception catch (_) {
          // Abaikan kegagalan penghapusan berkas sementara
        }
      }
    }
    captured.clear();
    selected.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
