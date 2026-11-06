import 'package:equatable/equatable.dart';

/// Pure DTO model untuk payload pengiriman balasan thread insiden
/// (`PostIncidentReplyDto`).
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class PostIncidentReplyModel extends Equatable {
  /// Membuat instance [PostIncidentReplyModel].
  const PostIncidentReplyModel({
    required this.message,
    this.photos = const [],
  });

  /// Pesan balasan teks.
  final String message;

  /// Daftar URL foto lampiran balasan (maksimal 2).
  final List<String> photos;

  /// Mengonversi ke Map JSON untuk dikirim via HTTP POST.
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'photos': photos,
    };
  }

  @override
  List<Object?> get props => [message, photos];
}
