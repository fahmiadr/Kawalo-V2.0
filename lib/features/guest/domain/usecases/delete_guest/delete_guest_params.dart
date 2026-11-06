import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

/// Parameter nilai (Command Object) untuk mengeksekusi operasi
/// penghapusan data tamu.
///
/// Memvalidasi parameter [id] agar selaras dengan aturan backend
/// `GuestIdParamsDto` (pola regex numerik `^[0-9]+$`).
class DeleteGuestParams extends Equatable {
  /// Membuat instance [DeleteGuestParams].
  ///
  /// [session] dan [item] dipakai use case untuk otorisasi penghapusan.
  const DeleteGuestParams({
    required this.id,
    required this.session,
    required this.item,
    this.cancelToken,
  });

  /// Identifier numerik data tamu.
  final String id;

  /// Sesi pengguna yang menjalankan aksi (null jika tidak terautentikasi).
  final AuthSessionEntity? session;

  /// Entitas tamu yang akan dihapus, dipakai untuk memeriksa kepemilikan.
  /// Null berarti item tidak dapat diverifikasi.
  final GuestItemEntity? item;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Pola regex untuk memvalidasi GuestId numerik backend.
  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  /// Memvalidasi apakah format [id] memenuhi kaidah domain dan API backend.
  bool get isValidId => id.isNotEmpty && _numericRegex.hasMatch(id);

  /// Menandakan apakah [session] berhak menghapus [item] (fail-closed).
  bool get isAuthorized {
    final target = item;
    if (target == null || target.id != id) return false;
    return target.canBeDeletedBySession(session);
  }

  @override
  List<Object?> get props => [id, session, item, cancelToken];
}
