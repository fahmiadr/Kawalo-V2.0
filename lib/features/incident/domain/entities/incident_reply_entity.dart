import 'package:equatable/equatable.dart';

/// Entitas domain yang merepresentasikan satu pesan atau balasan dalam
/// thread diskusi realtime insiden.
class IncidentReplyEntity extends Equatable {
  /// Membuat instance [IncidentReplyEntity].
  const IncidentReplyEntity({
    required this.id,
    required this.incidentId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.photos = const [],
  });

  /// ID unik pesan balasan.
  final String id;

  /// ID insiden yang dikaitkan.
  final String incidentId;

  /// ID pengguna pengirim pesan.
  final String senderId;

  /// Nama lengkap pengguna pengirim pesan.
  final String senderName;

  /// Role pengguna saat mengirim pesan (misal: 'ADMIN', 'GUARD').
  final String senderRole;

  /// Isi pesan teks diskusi.
  final String message;

  /// Daftar URL foto bukti yang dilampirkan bersama balasan (maksimal 2).
  final List<String> photos;

  /// Waktu pengiriman pesan balasan.
  final DateTime createdAt;

  /// Membuat duplikasi entitas dengan beberapa field yang diperbarui.
  IncidentReplyEntity copyWith({
    String? id,
    String? incidentId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? message,
    List<String>? photos,
    DateTime? createdAt,
  }) {
    return IncidentReplyEntity(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    incidentId,
    senderId,
    senderName,
    senderRole,
    message,
    photos,
    createdAt,
  ];
}
