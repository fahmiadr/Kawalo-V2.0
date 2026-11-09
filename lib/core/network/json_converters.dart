import 'package:json_annotation/json_annotation.dart';

/// Reads a JSON number as [int] even when the server sends a decimal
/// (for example `900.0`). A missing or non-numeric value still throws, so
/// use [NullableIntFromNumConverter] for optional fields.
class IntFromNumConverter implements JsonConverter<int, Object?> {
  const IntFromNumConverter();

  @override
  int fromJson(Object? json) => (json! as num).toInt();

  @override
  Object? toJson(int object) => object;
}

/// Nullable counterpart of [IntFromNumConverter]: `null` stays `null`.
class NullableIntFromNumConverter implements JsonConverter<int?, Object?> {
  const NullableIntFromNumConverter();

  @override
  int? fromJson(Object? json) => (json as num?)?.toInt();

  @override
  Object? toJson(int? object) => object;
}
