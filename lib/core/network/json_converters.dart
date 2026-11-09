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

/// Reads an optional string field that the server may send as a JSON number
/// (for example GPS coordinates). `null` stays `null`; strings pass through.
class StringFromNumOrStringConverter
    implements JsonConverter<String?, Object?> {
  const StringFromNumOrStringConverter();

  @override
  String? fromJson(Object? json) => switch (json) {
    null => null,
    final String value => value,
    final num value => value.toString(),
    _ => throw FormatException('Expected a string or number, got $json'),
  };

  @override
  Object? toJson(String? object) => object;
}
