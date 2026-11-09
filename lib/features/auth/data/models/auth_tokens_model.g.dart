// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthTokensModel _$AuthTokensModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AuthTokensModel',
      json,
      ($checkedConvert) {
        final val = AuthTokensModel(
          accessToken: $checkedConvert('access_token', (v) => v as String),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          tokenType: $checkedConvert('token_type', (v) => v as String),
          expiresIn: $checkedConvert(
            'expires_in',
            (v) => const IntFromNumConverter().fromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'accessToken': 'access_token',
        'refreshToken': 'refresh_token',
        'tokenType': 'token_type',
        'expiresIn': 'expires_in',
      },
    );
