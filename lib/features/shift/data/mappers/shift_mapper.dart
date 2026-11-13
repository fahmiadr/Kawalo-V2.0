import 'package:kawalo_mobile/features/shift/data/models/shift_model.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';

abstract final class ShiftMapper {
  /// `null` for a row without a uid or with an unreadable clock.
  static ShiftEntity? toEntity(ShiftModel model) {
    final start = ShiftClock.tryParse(model.startTime);
    final end = ShiftClock.tryParse(model.endTime);
    if (model.uid.isEmpty || start == null || end == null) return null;

    return ShiftEntity(
      uid: model.uid,
      name: model.name,
      startTime: start,
      endTime: end,
      color: model.color,
      description: model.description,
    );
  }

  static List<ShiftEntity> toEntityList(Iterable<ShiftModel> models) => [
    for (final model in models) ?toEntity(model),
  ];
}
