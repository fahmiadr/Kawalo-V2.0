import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';

/// Parameter nilai (Command Object) untuk mengeksekusi operasi
/// penghapusan sekumpulan informasi (batch).
///
/// Memvalidasi parameter [ids] agar selaras dengan aturan backend
/// `DeleteBatchInformationDto` (koleksi numerik `^[0-9]+$`).
class DeleteBatchInformationParams extends Equatable {
  /// Membuat instance [DeleteBatchInformationParams].
  ///
  /// [session] dan [items] dipakai use case untuk otorisasi penghapusan.
  const DeleteBatchInformationParams({
    required this.ids,
    required this.session,
    required this.items,
    this.cancelToken,
  });

  /// Daftar identifier numerik informasi / feed.
  final List<String> ids;

  /// Sesi pengguna yang menjalankan aksi (null jika tidak terautentikasi).
  final AuthSessionEntity? session;

  /// Entitas informasi yang akan dihapus, dipakai untuk memeriksa
  /// kepemilikan setiap [ids].
  final List<InformationItemEntity> items;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Pola regex untuk memvalidasi FeedId numerik backend.
  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  /// Memvalidasi apakah seluruh [ids] tidak kosong dan berformat angka valid.
  bool get isValid => ids.isNotEmpty && ids.every(_numericRegex.hasMatch);

  /// Menandakan apakah [session] berhak menghapus seluruh [ids]
  /// (fail-closed: satu saja tidak berhak atau tidak terverifikasi → false).
  bool get isAuthorized {
    final itemsById = {for (final item in items) item.id: item};
    return ids.every((id) {
      final item = itemsById[id];
      return item != null && item.canBeDeletedBySession(session);
    });
  }

  @override
  List<Object?> get props => [ids, session, items, cancelToken];
}
