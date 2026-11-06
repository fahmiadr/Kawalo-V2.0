import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';

/// Model respons standar API yang memetakan envelope respons backend Kawalo
/// (`api-response.ts`).
class ApiResponseModel<T> extends Equatable {
  /// Membuat instance [ApiResponseModel].
  const ApiResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.details,
  });

  /// Mengonversi map JSON ke [ApiResponseModel] dan mem-parse payload generic.
  ///
  /// Melempar [FormatException] bila field "success" bukan boolean.
  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    final successVal = json['success'];
    if (successVal is! bool) {
      throw const FormatException('Field "success" harus berupa boolean');
    }

    final messageVal = (json['message'] as String?) ?? '';
    final rawData = json['data'];

    return ApiResponseModel<T>(
      success: successVal,
      message: messageVal,
      data: successVal && fromJsonT != null && rawData != null
          ? fromJsonT(rawData)
          : null,
      errorCode: json['error_code'] as String?,
      details: json['details'],
    );
  }

  /// Helper untuk memvalidasi keberhasilan dan langsung membuka payload [data].
  ///
  /// Melempar [ServerException] jika `success == false` atau data kosong.
  static T unwrap<T>(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final response = ApiResponseModel<T>.fromJson(json, fromJsonT);
    if (!response.success) {
      throw ServerException(
        response.message.isNotEmpty
            ? response.message
            : 'Operasi gagal diproses server',
        null,
        response.errorCode,
        response.details,
      );
    }
    if (response.data == null && null is! T) {
      throw const ServerException('Payload respons kosong dari server');
    }
    return response.data as T;
  }

  /// Status indikator keberhasilan respon API.
  final bool success;

  /// Pesan dari server.
  final String message;

  /// Payload data bertipe generik [T].
  final T? data;

  /// Kode error semantik dari sistem backend.
  final String? errorCode;

  /// Detail error diagnostik teknis tambahan.
  final Object? details;

  @override
  List<Object?> get props => [success, message, data, errorCode, details];
}
