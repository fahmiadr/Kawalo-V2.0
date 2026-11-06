import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_reply_model.dart';

/// Pure DTO model untuk respon detail insiden beserta daftar balasan
/// awalnya (`IncidentDetailDto`).
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class IncidentDetailModel extends Equatable {
  /// Membuat instance [IncidentDetailModel].
  const IncidentDetailModel({
    required this.incident,
    this.replies = const [],
  });

  /// Mengonversi JSON Map dari backend menjadi objek [IncidentDetailModel].
  factory IncidentDetailModel.fromJson(Map<String, dynamic> json) {
    final IncidentModel incident;
    if (json.containsKey('incident') &&
        json['incident'] is Map<String, dynamic>) {
      incident =
          IncidentModel.fromJson(json['incident'] as Map<String, dynamic>);
    } else {
      incident = IncidentModel.fromJson(json);
    }

    final rawReplies = json['replies'] as List<dynamic>? ?? const [];
    final replies = rawReplies
        .whereType<Map<String, dynamic>>()
        .map(IncidentReplyModel.fromJson)
        .toList();

    return IncidentDetailModel(
      incident: incident,
      replies: replies,
    );
  }

  /// Data DTO header laporan insiden.
  final IncidentModel incident;

  /// Daftar DTO riwayat pesan balasan di dalam thread insiden.
  final List<IncidentReplyModel> replies;

  /// Mengonversi objek ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'incident': incident.toJson(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [incident, replies];
}
