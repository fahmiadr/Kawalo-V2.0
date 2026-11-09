import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Operasi murni pada daftar foto lampiran formulir informasi. Setiap method
/// mengembalikan daftar baru dan tidak pernah memodifikasi masukan.
class InformationFormPhotos {
  const InformationFormPhotos._();

  /// Pesan batas jumlah foto yang dapat dilampirkan.
  static String limitMessage(int maxPhotos) =>
      'Maksimal $maxPhotos foto dapat dilampirkan.';

  /// Apakah [a] dan [b] merujuk ke berkas yang sama (item yang masih
  /// dimuat tidak pernah dianggap sama).
  static bool isSameMedia(
    InformationFormMediaItem a,
    InformationFormMediaItem b,
  ) {
    return !a.isLoading &&
        !b.isLoading &&
        (a.displaySource == b.displaySource ||
            (a.path != null && a.path == b.path) ||
            (a.remoteUrl != null && a.remoteUrl == b.remoteUrl));
  }

  /// Memilih item dari [items] yang dapat ditambahkan ke [current] tanpa
  /// melewati [maxPhotos] dan tanpa duplikat.
  ///
  /// `error` terisi (dan `added` kosong) bila tidak ada slot tersisa atau
  /// semua item sudah ada dalam lampiran.
  static ({List<InformationFormMediaItem> added, String? error}) planAdd(
    List<InformationFormMediaItem> current,
    List<InformationFormMediaItem> items, {
    required int maxPhotos,
  }) {
    final availableSlots = (maxPhotos - current.length).clamp(0, maxPhotos);
    if (availableSlots <= 0) {
      return (added: const [], error: limitMessage(maxPhotos));
    }

    final added = <InformationFormMediaItem>[];
    for (final item in items) {
      if (added.length >= availableSlots) break;

      final isDuplicate =
          !item.isLoading &&
          (current.any((p) => isSameMedia(p, item)) ||
              added.any((p) => isSameMedia(p, item)));

      if (!isDuplicate) {
        added.add(item);
      }
    }

    if (added.isEmpty) {
      return (
        added: const [],
        error: items.length == 1
            ? 'Foto tersebut sudah ada dalam lampiran.'
            : 'Foto yang dipilih sudah ada dalam lampiran.',
      );
    }
    return (added: added, error: null);
  }

  /// Mengganti item ber-id [targetId] dengan [newItem]; `null` bila id tidak
  /// ditemukan.
  static List<InformationFormMediaItem>? replaceById(
    List<InformationFormMediaItem> current,
    String targetId,
    InformationFormMediaItem newItem,
  ) {
    final index = current.indexWhere((p) => p.id == targetId);
    if (index == -1) return null;
    return List<InformationFormMediaItem>.from(current)..[index] = newItem;
  }

  /// Menghapus item pada [index]; `null` bila indeks di luar rentang.
  static List<InformationFormMediaItem>? removeAt(
    List<InformationFormMediaItem> current,
    int index,
  ) {
    if (index < 0 || index >= current.length) return null;
    return List<InformationFormMediaItem>.from(current)..removeAt(index);
  }

  /// Memindahkan item dari [oldIndex] ke [newIndex]; `null` bila salah satu
  /// indeks di luar rentang atau keduanya sama.
  static List<InformationFormMediaItem>? reorder(
    List<InformationFormMediaItem> current,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < 0 || oldIndex >= current.length) return null;
    if (newIndex < 0 || newIndex >= current.length) return null;
    if (oldIndex == newIndex) return null;

    final updated = List<InformationFormMediaItem>.from(current);
    updated.insert(newIndex, updated.removeAt(oldIndex));
    return updated;
  }

  /// URL/key yang dikirim ke backend: berkas lokal diberi URL CDN tiruan
  /// (mock upload), berkas remote memakai URL aslinya.
  static List<String> payloadUrls(
    List<InformationFormMediaItem> current, {
    DateTime Function() now = DateTime.now,
  }) {
    return current.map((item) {
      if (item.isLocal) {
        final timestamp = now().millisecondsSinceEpoch;
        return 'https://cdn.kawalo.internal/feeds/photos/'
            '${timestamp}_${item.name}';
      }
      return item.remoteUrl ?? item.displaySource;
    }).toList();
  }

  /// Validasi saat submit: batas jumlah, dan tidak boleh ada foto yang masih
  /// diproses.
  static String? validate(
    List<InformationFormMediaItem> current, {
    required int maxPhotos,
  }) {
    if (current.length > maxPhotos) return limitMessage(maxPhotos);
    if (current.any((p) => p.isLoading)) {
      return 'Tunggu hingga semua foto selesai diproses.';
    }
    return null;
  }
}
