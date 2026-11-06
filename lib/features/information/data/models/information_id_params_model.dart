import 'package:equatable/equatable.dart';

/// Pure DTO model untuk parameter identifikasi informasi / feed
/// sesuai kontrak backend `InformationIdParamsDto`.
///
/// Digunakan untuk kebutuhan request path parameter HTTP endpoint
/// `DELETE /v1/information/:id` dan `PATCH /v1/information/:id`.
class InformationIdParamsModel extends Equatable {
  /// Membuat instance [InformationIdParamsModel].
  const InformationIdParamsModel({required this.id});

  /// Identifier numerik unik feed informasi untuk path parameter.
  final String id;

  @override
  List<Object?> get props => [id];
}
