// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseModel _$LoginResponseModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LoginResponseModel',
      json,
      ($checkedConvert) {
        final val = LoginResponseModel(
          user: $checkedConvert(
              'user', (v) => UserModel.fromJson(v as Map<String, dynamic>)),
          tokens: $checkedConvert('tokens',
              (v) => AuthTokensModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );
