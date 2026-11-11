// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptt_transcript_local_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetPttTranscriptLocalModelCollection on Isar {
  IsarCollection<PttTranscriptLocalModel> get pttTranscriptLocalModels =>
      this.collection();
}

const PttTranscriptLocalModelSchema = CollectionSchema(
  name: r'PttTranscriptLocalModel',
  id: -5456858745414515697,
  properties: {
    r'attempts': PropertySchema(id: 0, name: r'attempts', type: IsarType.long),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'locale': PropertySchema(id: 2, name: r'locale', type: IsarType.string),
    r'nextAttemptAt': PropertySchema(
      id: 3,
      name: r'nextAttemptAt',
      type: IsarType.dateTime,
    ),
    r'requestId': PropertySchema(
      id: 4,
      name: r'requestId',
      type: IsarType.string,
    ),
    r'state': PropertySchema(id: 5, name: r'state', type: IsarType.string),
    r'status': PropertySchema(id: 6, name: r'status', type: IsarType.string),
    r'text': PropertySchema(id: 7, name: r'text', type: IsarType.string),
  },

  estimateSize: _pttTranscriptLocalModelEstimateSize,
  serialize: _pttTranscriptLocalModelSerialize,
  deserialize: _pttTranscriptLocalModelDeserialize,
  deserializeProp: _pttTranscriptLocalModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'requestId': IndexSchema(
      id: 938047444593699237,
      name: r'requestId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'requestId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _pttTranscriptLocalModelGetId,
  getLinks: _pttTranscriptLocalModelGetLinks,
  attach: _pttTranscriptLocalModelAttach,
  version: '3.4.1',
);

int _pttTranscriptLocalModelEstimateSize(
  PttTranscriptLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.locale;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.requestId.length * 3;
  bytesCount += 3 + object.state.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.text;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _pttTranscriptLocalModelSerialize(
  PttTranscriptLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attempts);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.locale);
  writer.writeDateTime(offsets[3], object.nextAttemptAt);
  writer.writeString(offsets[4], object.requestId);
  writer.writeString(offsets[5], object.state);
  writer.writeString(offsets[6], object.status);
  writer.writeString(offsets[7], object.text);
}

PttTranscriptLocalModel _pttTranscriptLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PttTranscriptLocalModel();
  object.attempts = reader.readLong(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.isarId = id;
  object.locale = reader.readStringOrNull(offsets[2]);
  object.nextAttemptAt = reader.readDateTime(offsets[3]);
  object.requestId = reader.readString(offsets[4]);
  object.state = reader.readString(offsets[5]);
  object.status = reader.readString(offsets[6]);
  object.text = reader.readStringOrNull(offsets[7]);
  return object;
}

P _pttTranscriptLocalModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pttTranscriptLocalModelGetId(PttTranscriptLocalModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _pttTranscriptLocalModelGetLinks(
  PttTranscriptLocalModel object,
) {
  return [];
}

void _pttTranscriptLocalModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  PttTranscriptLocalModel object,
) {
  object.isarId = id;
}

extension PttTranscriptLocalModelByIndex
    on IsarCollection<PttTranscriptLocalModel> {
  Future<PttTranscriptLocalModel?> getByRequestId(String requestId) {
    return getByIndex(r'requestId', [requestId]);
  }

  PttTranscriptLocalModel? getByRequestIdSync(String requestId) {
    return getByIndexSync(r'requestId', [requestId]);
  }

  Future<bool> deleteByRequestId(String requestId) {
    return deleteByIndex(r'requestId', [requestId]);
  }

  bool deleteByRequestIdSync(String requestId) {
    return deleteByIndexSync(r'requestId', [requestId]);
  }

  Future<List<PttTranscriptLocalModel?>> getAllByRequestId(
    List<String> requestIdValues,
  ) {
    final values = requestIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'requestId', values);
  }

  List<PttTranscriptLocalModel?> getAllByRequestIdSync(
    List<String> requestIdValues,
  ) {
    final values = requestIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'requestId', values);
  }

  Future<int> deleteAllByRequestId(List<String> requestIdValues) {
    final values = requestIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'requestId', values);
  }

  int deleteAllByRequestIdSync(List<String> requestIdValues) {
    final values = requestIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'requestId', values);
  }

  Future<Id> putByRequestId(PttTranscriptLocalModel object) {
    return putByIndex(r'requestId', object);
  }

  Id putByRequestIdSync(
    PttTranscriptLocalModel object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'requestId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRequestId(List<PttTranscriptLocalModel> objects) {
    return putAllByIndex(r'requestId', objects);
  }

  List<Id> putAllByRequestIdSync(
    List<PttTranscriptLocalModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'requestId', objects, saveLinks: saveLinks);
  }
}

extension PttTranscriptLocalModelQueryWhereSort
    on QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QWhere> {
  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterWhere>
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension PttTranscriptLocalModelQueryWhere
    on
        QueryBuilder<
          PttTranscriptLocalModel,
          PttTranscriptLocalModel,
          QWhereClause
        > {
  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  requestIdEqualTo(String requestId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'requestId', value: [requestId]),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  requestIdNotEqualTo(String requestId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'requestId',
                lower: [],
                upper: [requestId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'requestId',
                lower: [requestId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'requestId',
                lower: [requestId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'requestId',
                lower: [],
                upper: [requestId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  createdAtGreaterThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  createdAtLessThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterWhereClause
  >
  createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PttTranscriptLocalModelQueryFilter
    on
        QueryBuilder<
          PttTranscriptLocalModel,
          PttTranscriptLocalModel,
          QFilterCondition
        > {
  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  attemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'attempts', value: value),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  attemptsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'attempts',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  attemptsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'attempts',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  attemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attempts',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'locale'),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'locale'),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'locale',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'locale',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'locale', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  localeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'locale', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  nextAttemptAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextAttemptAt', value: value),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  nextAttemptAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextAttemptAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  nextAttemptAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextAttemptAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  nextAttemptAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextAttemptAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'requestId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'requestId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'requestId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'requestId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'requestId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'requestId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'requestId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'requestId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'requestId', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  requestIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'requestId', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'state',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'state',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'state', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'state', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'text'),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'text'),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<
    PttTranscriptLocalModel,
    PttTranscriptLocalModel,
    QAfterFilterCondition
  >
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }
}

extension PttTranscriptLocalModelQueryObject
    on
        QueryBuilder<
          PttTranscriptLocalModel,
          PttTranscriptLocalModel,
          QFilterCondition
        > {}

extension PttTranscriptLocalModelQueryLinks
    on
        QueryBuilder<
          PttTranscriptLocalModel,
          PttTranscriptLocalModel,
          QFilterCondition
        > {}

extension PttTranscriptLocalModelQuerySortBy
    on QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QSortBy> {
  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByRequestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByRequestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension PttTranscriptLocalModelQuerySortThenBy
    on
        QueryBuilder<
          PttTranscriptLocalModel,
          PttTranscriptLocalModel,
          QSortThenBy
        > {
  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByRequestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByRequestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QAfterSortBy>
  thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension PttTranscriptLocalModelQueryWhereDistinct
    on
        QueryBuilder<
          PttTranscriptLocalModel,
          PttTranscriptLocalModel,
          QDistinct
        > {
  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attempts');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByLocale({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locale', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextAttemptAt');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByRequestId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requestId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PttTranscriptLocalModel, PttTranscriptLocalModel, QDistinct>
  distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }
}

extension PttTranscriptLocalModelQueryProperty
    on
        QueryBuilder<
          PttTranscriptLocalModel,
          PttTranscriptLocalModel,
          QQueryProperty
        > {
  QueryBuilder<PttTranscriptLocalModel, int, QQueryOperations>
  isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, int, QQueryOperations>
  attemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attempts');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, String?, QQueryOperations>
  localeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locale');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, DateTime, QQueryOperations>
  nextAttemptAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextAttemptAt');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, String, QQueryOperations>
  requestIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requestId');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, String, QQueryOperations>
  stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<PttTranscriptLocalModel, String?, QQueryOperations>
  textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }
}
