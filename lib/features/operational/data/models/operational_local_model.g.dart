// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operational_local_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetOperationalLocalModelCollection on Isar {
  IsarCollection<OperationalLocalModel> get operationalLocalModels =>
      this.collection();
}

const OperationalLocalModelSchema = CollectionSchema(
  name: r'OperationalLocalModel',
  id: 5649122263245287042,
  properties: {
    r'dutyDate': PropertySchema(
      id: 0,
      name: r'dutyDate',
      type: IsarType.string,
    ),
    r'groupName': PropertySchema(
      id: 1,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 2,
      name: r'id',
      type: IsarType.string,
    ),
    r'latestDuty': PropertySchema(
      id: 3,
      name: r'latestDuty',
      type: IsarType.string,
    ),
    r'latestDutyDt': PropertySchema(
      id: 4,
      name: r'latestDutyDt',
      type: IsarType.string,
    ),
    r'latestState': PropertySchema(
      id: 5,
      name: r'latestState',
      type: IsarType.string,
    ),
    r'latestStateDt': PropertySchema(
      id: 6,
      name: r'latestStateDt',
      type: IsarType.string,
    ),
    r'searchTokens': PropertySchema(
      id: 7,
      name: r'searchTokens',
      type: IsarType.string,
    ),
    r'timeline': PropertySchema(
      id: 8,
      name: r'timeline',
      type: IsarType.objectList,
      target: r'DutyTimelineLocalModel',
    ),
    r'totalActivities': PropertySchema(
      id: 9,
      name: r'totalActivities',
      type: IsarType.long,
    ),
    r'userEmail': PropertySchema(
      id: 10,
      name: r'userEmail',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 11,
      name: r'userName',
      type: IsarType.string,
    ),
    r'userProfilePic': PropertySchema(
      id: 12,
      name: r'userProfilePic',
      type: IsarType.string,
    )
  },
  estimateSize: _operationalLocalModelEstimateSize,
  serialize: _operationalLocalModelSerialize,
  deserialize: _operationalLocalModelDeserialize,
  deserializeProp: _operationalLocalModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'searchTokens': IndexSchema(
      id: 2062148741461982474,
      name: r'searchTokens',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'searchTokens',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'dutyDate': IndexSchema(
      id: -158660757936517259,
      name: r'dutyDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dutyDate',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'DutyTimelineLocalModel': DutyTimelineLocalModelSchema},
  getId: _operationalLocalModelGetId,
  getLinks: _operationalLocalModelGetLinks,
  attach: _operationalLocalModelAttach,
  version: '3.4.1',
);

int _operationalLocalModelEstimateSize(
  OperationalLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.dutyDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.groupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.latestDuty;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.latestDutyDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.latestState;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.latestStateDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.searchTokens;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.timeline.length * 3;
  {
    final offsets = allOffsets[DutyTimelineLocalModel]!;
    for (var i = 0; i < object.timeline.length; i++) {
      final value = object.timeline[i];
      bytesCount +=
          DutyTimelineLocalModelSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.userEmail.length * 3;
  {
    final value = object.userName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userProfilePic;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _operationalLocalModelSerialize(
  OperationalLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dutyDate);
  writer.writeString(offsets[1], object.groupName);
  writer.writeString(offsets[2], object.id);
  writer.writeString(offsets[3], object.latestDuty);
  writer.writeString(offsets[4], object.latestDutyDt);
  writer.writeString(offsets[5], object.latestState);
  writer.writeString(offsets[6], object.latestStateDt);
  writer.writeString(offsets[7], object.searchTokens);
  writer.writeObjectList<DutyTimelineLocalModel>(
    offsets[8],
    allOffsets,
    DutyTimelineLocalModelSchema.serialize,
    object.timeline,
  );
  writer.writeLong(offsets[9], object.totalActivities);
  writer.writeString(offsets[10], object.userEmail);
  writer.writeString(offsets[11], object.userName);
  writer.writeString(offsets[12], object.userProfilePic);
}

OperationalLocalModel _operationalLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OperationalLocalModel();
  object.dutyDate = reader.readStringOrNull(offsets[0]);
  object.groupName = reader.readStringOrNull(offsets[1]);
  object.id = reader.readString(offsets[2]);
  object.isarId = id;
  object.latestDuty = reader.readStringOrNull(offsets[3]);
  object.latestDutyDt = reader.readStringOrNull(offsets[4]);
  object.latestState = reader.readStringOrNull(offsets[5]);
  object.latestStateDt = reader.readStringOrNull(offsets[6]);
  object.searchTokens = reader.readStringOrNull(offsets[7]);
  object.timeline = reader.readObjectList<DutyTimelineLocalModel>(
        offsets[8],
        DutyTimelineLocalModelSchema.deserialize,
        allOffsets,
        DutyTimelineLocalModel(),
      ) ??
      [];
  object.totalActivities = reader.readLong(offsets[9]);
  object.userEmail = reader.readString(offsets[10]);
  object.userName = reader.readStringOrNull(offsets[11]);
  object.userProfilePic = reader.readStringOrNull(offsets[12]);
  return object;
}

P _operationalLocalModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readObjectList<DutyTimelineLocalModel>(
            offset,
            DutyTimelineLocalModelSchema.deserialize,
            allOffsets,
            DutyTimelineLocalModel(),
          ) ??
          []) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _operationalLocalModelGetId(OperationalLocalModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _operationalLocalModelGetLinks(
    OperationalLocalModel object) {
  return [];
}

void _operationalLocalModelAttach(
    IsarCollection<dynamic> col, Id id, OperationalLocalModel object) {
  object.isarId = id;
}

extension OperationalLocalModelByIndex
    on IsarCollection<OperationalLocalModel> {
  Future<OperationalLocalModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  OperationalLocalModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<OperationalLocalModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<OperationalLocalModel?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(OperationalLocalModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(OperationalLocalModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<OperationalLocalModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<OperationalLocalModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension OperationalLocalModelQueryWhereSort
    on QueryBuilder<OperationalLocalModel, OperationalLocalModel, QWhere> {
  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OperationalLocalModelQueryWhere on QueryBuilder<OperationalLocalModel,
    OperationalLocalModel, QWhereClause> {
  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
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

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      searchTokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'searchTokens',
        value: [null],
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      searchTokensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'searchTokens',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      searchTokensEqualTo(String? searchTokens) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'searchTokens',
        value: [searchTokens],
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      searchTokensNotEqualTo(String? searchTokens) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchTokens',
              lower: [],
              upper: [searchTokens],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchTokens',
              lower: [searchTokens],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchTokens',
              lower: [searchTokens],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchTokens',
              lower: [],
              upper: [searchTokens],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      dutyDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dutyDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      dutyDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dutyDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      dutyDateEqualTo(String? dutyDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dutyDate',
        value: [dutyDate],
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterWhereClause>
      dutyDateNotEqualTo(String? dutyDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dutyDate',
              lower: [],
              upper: [dutyDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dutyDate',
              lower: [dutyDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dutyDate',
              lower: [dutyDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dutyDate',
              lower: [],
              upper: [dutyDate],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OperationalLocalModelQueryFilter on QueryBuilder<
    OperationalLocalModel, OperationalLocalModel, QFilterCondition> {
  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dutyDate',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dutyDate',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dutyDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dutyDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dutyDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dutyDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dutyDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dutyDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      dutyDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dutyDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      dutyDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dutyDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dutyDate',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> dutyDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dutyDate',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      groupNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      groupNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latestDuty',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latestDuty',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestDuty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latestDuty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latestDuty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latestDuty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'latestDuty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'latestDuty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestDutyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'latestDuty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestDutyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'latestDuty',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestDuty',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'latestDuty',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latestDutyDt',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latestDutyDt',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestDutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latestDutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latestDutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latestDutyDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'latestDutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'latestDutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestDutyDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'latestDutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestDutyDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'latestDutyDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestDutyDt',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestDutyDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'latestDutyDt',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latestState',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latestState',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latestState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latestState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latestState',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'latestState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'latestState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestStateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'latestState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestStateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'latestState',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestState',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'latestState',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latestStateDt',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latestStateDt',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestStateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latestStateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latestStateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latestStateDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'latestStateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'latestStateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestStateDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'latestStateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      latestStateDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'latestStateDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestStateDt',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> latestStateDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'latestStateDt',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'searchTokens',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'searchTokens',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'searchTokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'searchTokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'searchTokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'searchTokens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'searchTokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'searchTokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      searchTokensContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'searchTokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      searchTokensMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'searchTokens',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'searchTokens',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> searchTokensIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'searchTokens',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> timelineLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeline',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> timelineIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeline',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> timelineIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeline',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> timelineLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeline',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> timelineLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeline',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> timelineLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timeline',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> totalActivitiesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalActivities',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> totalActivitiesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalActivities',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> totalActivitiesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalActivities',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> totalActivitiesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalActivities',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      userEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      userEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      userNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      userNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userProfilePic',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userProfilePic',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userProfilePic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userProfilePic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userProfilePic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userProfilePic',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userProfilePic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userProfilePic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      userProfilePicContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userProfilePic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      userProfilePicMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userProfilePic',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userProfilePic',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
      QAfterFilterCondition> userProfilePicIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userProfilePic',
        value: '',
      ));
    });
  }
}

extension OperationalLocalModelQueryObject on QueryBuilder<
    OperationalLocalModel, OperationalLocalModel, QFilterCondition> {
  QueryBuilder<OperationalLocalModel, OperationalLocalModel,
          QAfterFilterCondition>
      timelineElement(FilterQuery<DutyTimelineLocalModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'timeline');
    });
  }
}

extension OperationalLocalModelQueryLinks on QueryBuilder<OperationalLocalModel,
    OperationalLocalModel, QFilterCondition> {}

extension OperationalLocalModelQuerySortBy
    on QueryBuilder<OperationalLocalModel, OperationalLocalModel, QSortBy> {
  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByDutyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dutyDate', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByDutyDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dutyDate', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestDuty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDuty', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestDutyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDuty', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestDutyDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDutyDt', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestDutyDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDutyDt', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestState', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestState', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestStateDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestStateDt', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByLatestStateDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestStateDt', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortBySearchTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchTokens', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortBySearchTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchTokens', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByTotalActivities() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalActivities', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByTotalActivitiesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalActivities', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByUserProfilePic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      sortByUserProfilePicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.desc);
    });
  }
}

extension OperationalLocalModelQuerySortThenBy
    on QueryBuilder<OperationalLocalModel, OperationalLocalModel, QSortThenBy> {
  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByDutyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dutyDate', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByDutyDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dutyDate', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestDuty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDuty', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestDutyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDuty', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestDutyDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDutyDt', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestDutyDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestDutyDt', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestState', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestState', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestStateDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestStateDt', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByLatestStateDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestStateDt', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenBySearchTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchTokens', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenBySearchTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchTokens', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByTotalActivities() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalActivities', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByTotalActivitiesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalActivities', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByUserProfilePic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.asc);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QAfterSortBy>
      thenByUserProfilePicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.desc);
    });
  }
}

extension OperationalLocalModelQueryWhereDistinct
    on QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct> {
  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByDutyDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dutyDate', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByGroupName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByLatestDuty({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestDuty', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByLatestDutyDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestDutyDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByLatestState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestState', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByLatestStateDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestStateDt',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctBySearchTokens({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'searchTokens', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByTotalActivities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalActivities');
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByUserEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByUserName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalLocalModel, OperationalLocalModel, QDistinct>
      distinctByUserProfilePic({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userProfilePic',
          caseSensitive: caseSensitive);
    });
  }
}

extension OperationalLocalModelQueryProperty on QueryBuilder<
    OperationalLocalModel, OperationalLocalModel, QQueryProperty> {
  QueryBuilder<OperationalLocalModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      dutyDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dutyDate');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<OperationalLocalModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      latestDutyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestDuty');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      latestDutyDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestDutyDt');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      latestStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestState');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      latestStateDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestStateDt');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      searchTokensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'searchTokens');
    });
  }

  QueryBuilder<OperationalLocalModel, List<DutyTimelineLocalModel>,
      QQueryOperations> timelineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeline');
    });
  }

  QueryBuilder<OperationalLocalModel, int, QQueryOperations>
      totalActivitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalActivities');
    });
  }

  QueryBuilder<OperationalLocalModel, String, QQueryOperations>
      userEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userEmail');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }

  QueryBuilder<OperationalLocalModel, String?, QQueryOperations>
      userProfilePicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userProfilePic');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

const DutyTimelineLocalModelSchema = Schema(
  name: r'DutyTimelineLocalModel',
  id: 5168455244218244411,
  properties: {
    r'duty': PropertySchema(
      id: 0,
      name: r'duty',
      type: IsarType.string,
    ),
    r'dutyDt': PropertySchema(
      id: 1,
      name: r'dutyDt',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 2,
      name: r'id',
      type: IsarType.string,
    ),
    r'journeyUid': PropertySchema(
      id: 3,
      name: r'journeyUid',
      type: IsarType.string,
    ),
    r'state': PropertySchema(
      id: 4,
      name: r'state',
      type: IsarType.string,
    ),
    r'stateDt': PropertySchema(
      id: 5,
      name: r'stateDt',
      type: IsarType.string,
    )
  },
  estimateSize: _dutyTimelineLocalModelEstimateSize,
  serialize: _dutyTimelineLocalModelSerialize,
  deserialize: _dutyTimelineLocalModelDeserialize,
  deserializeProp: _dutyTimelineLocalModelDeserializeProp,
);

int _dutyTimelineLocalModelEstimateSize(
  DutyTimelineLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.duty;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dutyDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.journeyUid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.state;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.stateDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dutyTimelineLocalModelSerialize(
  DutyTimelineLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.duty);
  writer.writeString(offsets[1], object.dutyDt);
  writer.writeString(offsets[2], object.id);
  writer.writeString(offsets[3], object.journeyUid);
  writer.writeString(offsets[4], object.state);
  writer.writeString(offsets[5], object.stateDt);
}

DutyTimelineLocalModel _dutyTimelineLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DutyTimelineLocalModel();
  object.duty = reader.readStringOrNull(offsets[0]);
  object.dutyDt = reader.readStringOrNull(offsets[1]);
  object.id = reader.readString(offsets[2]);
  object.journeyUid = reader.readStringOrNull(offsets[3]);
  object.state = reader.readStringOrNull(offsets[4]);
  object.stateDt = reader.readStringOrNull(offsets[5]);
  return object;
}

P _dutyTimelineLocalModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DutyTimelineLocalModelQueryFilter on QueryBuilder<
    DutyTimelineLocalModel, DutyTimelineLocalModel, QFilterCondition> {
  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'duty',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'duty',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'duty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'duty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      dutyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'duty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      dutyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'duty',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duty',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'duty',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dutyDt',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dutyDt',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dutyDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      dutyDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dutyDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      dutyDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dutyDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dutyDt',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> dutyDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dutyDt',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'journeyUid',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'journeyUid',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'journeyUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'journeyUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'journeyUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'journeyUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'journeyUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'journeyUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      journeyUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'journeyUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      journeyUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'journeyUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'journeyUid',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> journeyUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'journeyUid',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'state',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'state',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'state',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      stateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      stateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'state',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stateDt',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stateDt',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stateDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      stateDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stateDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
          QAfterFilterCondition>
      stateDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stateDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stateDt',
        value: '',
      ));
    });
  }

  QueryBuilder<DutyTimelineLocalModel, DutyTimelineLocalModel,
      QAfterFilterCondition> stateDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stateDt',
        value: '',
      ));
    });
  }
}

extension DutyTimelineLocalModelQueryObject on QueryBuilder<
    DutyTimelineLocalModel, DutyTimelineLocalModel, QFilterCondition> {}
