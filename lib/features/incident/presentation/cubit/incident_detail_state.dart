import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Status siklus hidup tampilan detail insiden.
enum IncidentDetailStatus { initial, loading, success, failure }

/// State representasi layar detail insiden dan thread realtime.
class IncidentDetailState extends Equatable {
  /// Membuat instance [IncidentDetailState].
  const IncidentDetailState({
    this.status = IncidentDetailStatus.initial,
    this.incident,
    this.replies = const [],
    this.isReconnecting = false,
    this.isPostingReply = false,
    this.isResolving = false,
    this.isDeleting = false,
    this.isReadOnly = false,
    this.isTerminated = false,
    this.draftMessage = '',
    this.draftPhotos = const [],
    this.errorMessage,
    this.conflictNotice,
    this.infoNotice,
  });

  /// Status loading/sukses/gagal layar.
  final IncidentDetailStatus status;

  /// Entitas laporan insiden utama.
  final IncidentEntity? incident;

  /// Daftar riwayat pesan balasan di dalam thread (diurutkan kronologis).
  final List<IncidentReplyEntity> replies;

  /// Penanda apakah socket SSE sedang dalam proses rekoneksi otomatis
  /// (misal dead-zone).
  final bool isReconnecting;

  /// Penanda apakah aplikasi sedang dalam proses pengiriman balasan ke API.
  final bool isPostingReply;

  /// Penanda apakah aplikasi sedang dalam proses penyelesaian insiden.
  final bool isResolving;

  /// Penanda apakah aplikasi sedang dalam proses penghapusan insiden.
  final bool isDeleting;

  /// Penanda apakah thread dikunci dalam status read-only (telah diselesaikan).
  final bool isReadOnly;

  /// Penanda apakah insiden telah dihapus secara administratif, memicu pop
  /// navigasi.
  final bool isTerminated;

  /// Draf pesan teks yang sedang diketik (dipertahankan sampai HTTP 201
  /// konfirmasi).
  final String draftMessage;

  /// Foto lampiran draf sebelum dikirimkan.
  final List<IncidentMediaItem> draftPhotos;

  /// Pesan kesalahan teknis atau jaringan.
  final String? errorMessage;

  /// Pemberitahuan konflik resolusi (insiden sudah diselesaikan pihak lain).
  final String? conflictNotice;

  /// Pemberitahuan informatif umum (toast/banner).
  final String? infoNotice;

  /// Apakah layar sedang dalam tahap pemuatan awal.
  bool get isLoading => status == IncidentDetailStatus.loading;

  /// Apakah ada foto draf yang sedang diunggah.
  bool get isUploadingPhotos => draftPhotos.any((p) => p.isUploading);

  /// ID event balasan terakhir yang diterima (untuk reconnect Last-Event-ID).
  String? get latestReplyId => replies.isNotEmpty ? replies.last.id : null;

  /// Membuat duplikasi state dengan beberapa properti yang dimutasi.
  IncidentDetailState copyWith({
    IncidentDetailStatus? status,
    IncidentEntity? incident,
    List<IncidentReplyEntity>? replies,
    bool? isReconnecting,
    bool? isPostingReply,
    bool? isResolving,
    bool? isDeleting,
    bool? isReadOnly,
    bool? isTerminated,
    String? draftMessage,
    List<IncidentMediaItem>? draftPhotos,
    String? Function()? errorMessage,
    String? Function()? conflictNotice,
    String? Function()? infoNotice,
  }) {
    return IncidentDetailState(
      status: status ?? this.status,
      incident: incident ?? this.incident,
      replies: replies ?? this.replies,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      isPostingReply: isPostingReply ?? this.isPostingReply,
      isResolving: isResolving ?? this.isResolving,
      isDeleting: isDeleting ?? this.isDeleting,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isTerminated: isTerminated ?? this.isTerminated,
      draftMessage: draftMessage ?? this.draftMessage,
      draftPhotos: draftPhotos ?? this.draftPhotos,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      conflictNotice: conflictNotice != null
          ? conflictNotice()
          : this.conflictNotice,
      infoNotice: infoNotice != null ? infoNotice() : this.infoNotice,
    );
  }

  @override
  List<Object?> get props => [
    status,
    incident,
    replies,
    isReconnecting,
    isPostingReply,
    isResolving,
    isDeleting,
    isReadOnly,
    isTerminated,
    draftMessage,
    draftPhotos,
    errorMessage,
    conflictNotice,
    infoNotice,
  ];
}
