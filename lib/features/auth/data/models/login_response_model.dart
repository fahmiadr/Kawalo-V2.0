import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';

part 'login_response_model.g.dart';

/// Model respons login untuk pertukaran JSON dengan backend
/// (`LoginResponseDto`).
@JsonSerializable(createToJson: false, checked: true)
class LoginResponseModel extends Equatable {
  const LoginResponseModel({required this.user, required this.tokens});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseModelFromJson(json);

  final UserModel user;
  final AuthTokensModel tokens;

  @override
  List<Object?> get props => [user, tokens];
}
