import 'package:equatable/equatable.dart';

/// Pure DTO model untuk parameter identifikasi data tamu
/// sesuai kontrak backend `GuestIdParamsDto`.
///
/// Digunakan untuk kebutuhan request path parameter HTTP endpoint
/// `DELETE /v1/guests/:id`.
class GuestIdParamsModel extends Equatable {
  /// Membuat instance [GuestIdParamsModel].
  const GuestIdParamsModel({required this.id});

  /// Identifier numerik unik data tamu untuk path parameter.
  final String id;

  @override
  List<Object?> get props => [id];
}
