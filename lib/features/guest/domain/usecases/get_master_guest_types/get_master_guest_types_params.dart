import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Parameter wrapper untuk eksekusi pengambilan master tipe tamu.
class GetMasterGuestTypesParams extends Equatable {
  /// Membuat instance [GetMasterGuestTypesParams].
  const GetMasterGuestTypesParams({this.cancelToken});

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  @override
  List<Object?> get props => [cancelToken];
}
