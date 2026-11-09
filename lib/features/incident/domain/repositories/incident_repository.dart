import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/create_incident_data.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_detail_result.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_list_result.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_query_params.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/post_incident_reply_data.dart';

/// Kontrak repositori murni Dart untuk seluruh operasi data fitur Insiden.
///
/// Bertindak sebagai batas abstraksi (Port) domain yang tidak bergantung
/// pada framework eksternal, Dio, maupun implementasi UI.
abstract class IncidentRepository {
  /// Mengambil daftar ringkasan laporan insiden berdasarkan parameter filter
  /// grup & status.
  Future<Either<Failure, IncidentListResult>> getIncidents(
    IncidentQueryParams params,
  );

  /// Mengambil detail lengkap insiden beserta riwayat awal pesan thread.
  Future<Either<Failure, IncidentDetailResult>> getIncidentDetail({
    required String incidentId,
    AppCancellationToken? cancelToken,
  });

  /// Membuat laporan insiden baru.
  Future<Either<Failure, IncidentEntity>> createIncident(
    CreateIncidentData data,
  );

  /// Membuka koneksi real-time stream (SSE) untuk memantau pesan balasan baru,
  /// penyelesaian thread, atau penghapusan insiden secara foreground.
  Stream<Either<Failure, IncidentStreamEvent>> watchIncidentReplies({
    required String incidentId,
    String? lastEventId,
    AppCancellationToken? cancelToken,
  });

  /// Mengirimkan pesan balasan atau foto baru pada thread insiden.
  Future<Either<Failure, IncidentReplyEntity>> postIncidentReply(
    PostIncidentReplyData data,
  );

  /// Menyelesaikan insiden dan mengunci thread diskusi ke mode read-only.
  ///
  /// Jika insiden telah diselesaikan oleh pengguna lain secara bersamaan,
  /// operasi akan mengembalikan [ServerFailure] dengan HTTP 409 Conflict.
  Future<Either<Failure, IncidentEntity>> resolveIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  });

  /// Menghapus laporan insiden secara administratif (soft-delete).
  ///
  /// Hanya boleh diakses oleh pengguna dengan hak administratif.
  Future<Either<Failure, void>> deleteIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  });
}
