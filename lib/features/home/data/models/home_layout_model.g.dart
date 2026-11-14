// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_layout_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeLayoutModel _$HomeLayoutModelFromJson(Map<String, dynamic> json) =>
    HomeLayoutModel(
      order:
          (json['order'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      hidden:
          (json['hidden'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isDefault: json['is_default'] as bool? ?? false,
    );

Map<String, dynamic> _$HomeLayoutModelToJson(HomeLayoutModel instance) =>
    <String, dynamic>{'order': instance.order, 'hidden': instance.hidden};
