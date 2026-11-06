import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Parameter input command object untuk GetGroupMembersUseCase.
class GetGroupMembersParams extends Equatable {
  /// Membuat instance [GetGroupMembersParams].
  const GetGroupMembersParams({this.cancelToken});

  /// Token pembatalan request asinkron yang framework-agnostik.
  final AppCancellationToken? cancelToken;

  @override
  List<Object?> get props => [cancelToken];
}
