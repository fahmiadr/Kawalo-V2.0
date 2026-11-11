import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';

/// Kontrak repositori murni domain untuk operasional Push-to-Talk.
///
/// Mengisolasi seluruh interaksi native platform channel dan jaringan WebSocket
/// dari domain layer (100% pure Dart tanpa dependensi UI / Dio).
abstract class PttRepository {
  /// Bergabung ke saluran PTT grup dengan kredensial aktif.
  Future<Either<Failure, void>> joinChannel({
    required String channelUrl,
    required String groupUid,
    required String token,
  });

  /// Keluar dari saluran PTT dan menghentikan layanan latar belakang.
  Future<Either<Failure, void>> leaveChannel();

  /// Mengirim permintaan hak bicara (Floor Request).
  Future<Either<Failure, void>> startTransmission({required String requestId});

  /// Melepaskan hak bicara (Floor Release).
  Future<Either<Failure, void>> stopTransmission();

  /// Memperbarui token akses pada native service setelah rotasi token JWT.
  Future<Either<Failure, void>> updateAuthToken(String token);

  /// Mengecek apakah izin mikrofon (RECORD_AUDIO) telah diberikan.
  Future<bool> hasRecordAudioPermission();

  /// Meminta izin runtime mikrofon (RECORD_AUDIO) kepada pengguna.
  Future<bool> requestRecordAudioPermission();

  /// Aliran perubahan status pendudukan saluran (Floor State).
  Stream<PttFloorStateEntity> watchFloorState();

  /// Aliran perubahan status konektivitas soket latar belakang.
  Stream<PttConnectionStatus> watchConnectionStatus();

  /// Aliran perubahan jumlah anggota yang terhubung ke saluran.
  Stream<int> watchMemberCount();

  /// Aliran event transmisi mentah (Granted, Denied, Revoked).
  Stream<Map<String, dynamic>> watchTransmissionEvents();

  /// Emits when the native service's reconnect was refused with HTTP 401, i.e.
  /// the token it holds expired while the socket was down.
  Stream<void> watchAuthRejected();
}
