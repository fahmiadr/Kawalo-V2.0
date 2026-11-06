import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';

/// Parameter nilai (Command Object) untuk mengeksekusi operasi
/// penghapusan informasi.
///
/// Memvalidasi parameter [id] agar selaras dengan aturan backend
/// `InformationIdParamsDto` (pola regex numerik `^[0-9]+$`).
class DeleteInformationParams extends Equatable {
  /// Membuat instance [DeleteInformationParams].
  ///
  /// [session] dan [item] dipakai use case untuk otorisasi penghapusan.
  const DeleteInformationParams({
    required this.id,
    required this.session,
    required this.item,
    this.cancelToken,
  });

  /// Identifier numerik informasi / feed.
  final String id;

  /// Sesi pengguna yang menjalankan aksi (null jika tidak terautentikasi).
  final AuthSessionEntity? session;

  /// Entitas informasi yang akan dihapus, dipakai untuk memeriksa
  /// kepemilikan. Null berarti item tidak dapat diverifikasi.
  final InformationItemEntity? item;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Pola regex untuk memvalidasi FeedId numerik backend.
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
