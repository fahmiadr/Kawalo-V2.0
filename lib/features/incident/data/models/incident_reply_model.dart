import 'package:equatable/equatable.dart';

/// Pure DTO model untuk pesan balasan thread insiden (`IncidentReplyDto`).
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class IncidentReplyModel extends Equatable {
  /// Membuat instance [IncidentReplyModel].
  const IncidentReplyModel({
    required this.id,
    required this.incidentId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.photos = const [],
  });

  /// Mengonversi JSON Map dari backend menjadi objek [IncidentReplyModel].
  factory IncidentReplyModel.fromJson(Map<String, dynamic> json) {
    return IncidentReplyModel(
      id: json['id'] as String,
      incidentId: (json['incident_id'] ?? json['incidentId'] ?? '') as String,
      senderId: (json['sender_id'] ?? json['senderId'] ?? '') as String,
      senderName: (json['sender_name'] ?? json['senderName'] ?? '') as String,
      senderRole: (json['sender_role'] ?? json['senderRole'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      photos: json['photos'] != null
          ? (json['photos'] as List<dynamic>).map((e) => e.toString()).toList()
          : const [],
      createdAt: (json['created_at'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()) as String,
    );
  }

  /// ID unik balasan.
  final String id;

  /// ID insiden terkait.
  final String incidentId;

  /// ID pengguna pengirim.
  final String senderId;

  /// Nama lengkap pengirim.
  final String senderName;

  /// Role pengirim ('admin', 'guard').
  final String senderRole;

  /// Pesan teks.
  final String message;

  /// Daftar URL foto lampiran balasan.
  final List<String> photos;

  /// ISO 8601 timestamp saat balasan dikirimkan.
  final String createdAt;

  /// Mengonversi objek ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incident_id': incidentId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'message': message,
      'photos': photos,
      'created_at': createdAt,
    };
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
