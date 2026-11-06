import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

/// Command Object (Request Model) untuk mengeksekusi operasi
/// check-out tamu.
///
/// Memvalidasi parameter [id] dan memastikan otorisasi pengguna aktif
/// atas entitas target sebelum diteruskan ke lapisan repositori data.
class CheckoutGuestParams extends Equatable {
  /// Membuat instance [CheckoutGuestParams].
  const CheckoutGuestParams({
    required this.id,
    required this.session,
    required this.item,
    this.qrUid,
    this.cancelToken,
  });

  /// Identifier data tamu yang akan di-checkout (wajib).
  final String id;

  /// Sesi pengguna aktif yang mengeksekusi check-out.
  final AuthSessionEntity? session;

  /// Entitas tamu target untuk verifikasi otorisasi dan status keluar.
  final GuestItemEntity? item;

  /// Kode akses QR khusus tamu (opsional).
  final String? qrUid;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Pola regex untuk memvalidasi GuestId numerik / slug backend.
  static final RegExp _idRegex = RegExp(r'^[a-zA-Z0-9_-]+$');

  /// Memvalidasi apakah format [id] memenuhi kaidah domain dan API backend.
  bool get isValidId => id.isNotEmpty && _idRegex.hasMatch(id);

  /// Menandakan apakah [session] berhak melakukan check-out terhadap [item].
  bool get isAuthorized {
    final target = item;
    if (target == null || target.id != id) return false;
    return target.canBeCheckedOutBySession(session);
  }

  @override
  List<Object?> get props => [id, session, item, qrUid, cancelToken];
}
