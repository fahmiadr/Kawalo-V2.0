import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';

/// Entitas bisnis utama yang merepresentasikan sebuah laporan insiden
/// operasional.
///
/// Bertanggung jawab atas integritas data laporan insiden dan memusatkan
/// seluruh kebijakan aturan otorisasi domain (RBAC/ABAC).
class IncidentEntity extends Equatable {
  /// Membuat instance [IncidentEntity].
  const IncidentEntity({
    required this.id,
    required this.groupId,
    required this.title,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
    this.description,
    this.category,
    this.glat,
    this.glong,
    this.photos = const [],
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedAt,
    this.deletedAt,
    this.updatedAt,
  });

  /// ID unik insiden (UUID).
  final String id;

  /// ID grup tempat insiden terjadi (multi-tenancy scoping).
  final String groupId;

  /// Judul laporan insiden.
  final String title;

  /// Penjelasan detail mengenai peristiwa insiden.
  final String? description;

  /// Kategori klasifikasi insiden.
  final IncidentCategory? category;

  /// Titik garis lintang GPS lokasi insiden.
  final double? glat;

  /// Titik garis bujur GPS lokasi insiden.
  final double? glong;

  /// Daftar URL foto bukti insiden.
  final List<String> photos;

  /// Status siklus hidup insiden (open / resolved).
  final IncidentStatus status;

  /// ID pengguna pelapor insiden.
  final String createdBy;

  /// Nama lengkap pengguna pelapor insiden.
  final String? createdByName;

  /// ID pengguna yang menyelesaikan/menutup insiden.
  final String? resolvedBy;

  /// Nama pengguna yang menyelesaikan/menutup insiden.
  final String? resolvedByName;

  /// Waktu penyelesaian insiden.
  final DateTime? resolvedAt;

  /// Waktu soft-delete insiden (jika telah dihapus oleh Admin).
  final DateTime? deletedAt;

  /// Waktu pembuatan laporan insiden.
  final DateTime createdAt;

  /// Waktu pembaruan data insiden terakhir.
  final DateTime? updatedAt;

  /// Menandakan apakah insiden masih aktif dan diskusi thread terbuka.
  bool get isOpen => status == IncidentStatus.open && !isDeleted;

  /// Menandakan apakah insiden telah selesai dan diskusi thread ditutup.
  bool get isResolved => status == IncidentStatus.resolved && !isDeleted;

  /// Menandakan apakah insiden telah dihapus secara administratif
  /// (soft delete).
  bool get isDeleted => deletedAt != null;

  /// Kebijakan domain: Sesi berhak membuat laporan insiden jika memiliki
  /// grup aktif.
  static bool canBeCreatedBySession(AuthSessionEntity? session) {
    if (session == null) return false;
    final groupUid = session.groupUid;
    return groupUid != null && groupUid.trim().isNotEmpty;
  }

  /// Kebijakan domain: Sesi berhak melihat insiden hanya jika berada pada grup
  /// yang sama; server membatasi per grup (`group_uid` token), termasuk admin.
  bool canBeViewedBySession(AuthSessionEntity? session) {
    if (session == null) return false;
    return session.groupUid == groupId;
  }

  /// Kebijakan domain: Pengguna dapat membalas thread jika insiden masih
  /// terbuka dan pengguna memiliki hak akses melihat insiden tersebut.
  bool canReplyBySession(AuthSessionEntity? session) {
    return isOpen && canBeViewedBySession(session);
  }

  /// Kebijakan domain: Pengguna (Guard maupun Admin) dapat menyelesaikan
  /// insiden jika insiden masih terbuka dan memiliki hak akses pada grup
  /// tersebut.
  bool canBeResolvedBySession(AuthSessionEntity? session) {
    return isOpen && canBeViewedBySession(session);
  }

  /// Kebijakan domain: Hanya Administrator yang berhak menghapus insiden.
  bool canBeDeletedBySession(AuthSessionEntity? session) {
    if (session == null) return false;
    return session.allowAdmin;
  }

  /// Membuat duplikasi entitas dengan beberapa field yang diperbarui.
  IncidentEntity copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    IncidentCategory? category,
    double? glat,
    double? glong,
    List<String>? photos,
    IncidentStatus? status,
    String? createdBy,
    String? createdByName,
    String? resolvedBy,
    String? resolvedByName,
    DateTime? resolvedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncidentEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      glat: glat ?? this.glat,
      glong: glong ?? this.glong,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    title,
    description,
    category,
    glat,
    glong,
    photos,
    status,
    createdBy,
    createdByName,
    resolvedBy,
    resolvedByName,
    resolvedAt,
    deletedAt,
    createdAt,
    updatedAt,
  ];
}
