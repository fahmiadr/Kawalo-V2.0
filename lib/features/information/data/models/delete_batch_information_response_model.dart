import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kawalo_mobile/core/network/json_converters.dart';

part 'delete_batch_information_response_model.g.dart';

/// Pure DTO model untuk response batch delete informasi
/// sesuai kontrak backend `DeleteBatchInformationResponseDto`.
///
/// Merupakan Pure DTO tanpa logika bisnis dan tanpa sanitasi. Sanitasi
/// didelegasikan ke mapper pada Anti-Corruption Layer.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DeleteBatchInformationResponseModel extends Equatable {
  const DeleteBatchInformationResponseModel({required this.deletedCount});

  factory DeleteBatchInformationResponseModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$DeleteBatchInformationResponseModelFromJson(json);

  /// Jumlah informasi yang dihapus sesuai response server.
  ///
  /// A missing count falls back to 0, matching the data source, which already
  /// returns a zero count when the response carries no data.
  @IntFromNumConverter()
  @JsonKey(defaultValue: 0)
  final int deletedCount;

  @override
  List<Object?> get props => [deletedCount];
}
