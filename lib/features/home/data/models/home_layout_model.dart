import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';

part 'home_layout_model.g.dart';

/// `data` of `GET/PUT /v1/me/home-layout`; [toJson] is the PUT body (and the
/// local cache), so `is_default` is read but never sent.
@JsonSerializable(fieldRename: FieldRename.snake)
class HomeLayoutModel extends Equatable {
  const HomeLayoutModel({
    this.order = const [],
    this.hidden = const [],
    this.isDefault = false,
  });

  factory HomeLayoutModel.fromJson(Map<String, dynamic> json) =>
      _$HomeLayoutModelFromJson(json);

  factory HomeLayoutModel.fromEntity(HomeLayout layout) => HomeLayoutModel(
    order: [for (final card in layout.order) card.name],
    hidden: [
      for (final card in layout.order)
        if (layout.hidden.contains(card)) card.name,
    ],
  );

  final List<String> order;
  final List<String> hidden;

  @JsonKey(includeToJson: false)
  final bool isDefault;

  HomeLayout toEntity() =>
      HomeLayout.fromKeys(order: order, hidden: hidden, isDefault: isDefault);

  Map<String, dynamic> toJson() => _$HomeLayoutModelToJson(this);

  @override
  @JsonKey(includeToJson: false)
  List<Object?> get props => [order, hidden, isDefault];

  @override
  @JsonKey(includeToJson: false)
  bool? get stringify => super.stringify;
}
