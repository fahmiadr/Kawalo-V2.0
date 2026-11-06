// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'information_local_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetInformationLocalModelCollection on Isar {
  IsarCollection<InformationLocalModel> get informationLocalModels =>
      this.collection();
}

const InformationLocalModelSchema = CollectionSchema(
  name: r'InformationLocalModel',
  id: -4490679601008872856,
  properties: {
    r'eventDuration': PropertySchema(
      id: 0,
      name: r'eventDuration',
      type: IsarType.long,
    ),
    r'eventEndDt': PropertySchema(
      id: 1,
      name: r'eventEndDt',
      type: IsarType.string,
    ),
    r'eventLocation': PropertySchema(
      id: 2,
      name: r'eventLocation',
      type: IsarType.string,
    ),
    r'eventStartDt': PropertySchema(
      id: 3,
      name: r'eventStartDt',
      type: IsarType.string,
    ),
    r'feedDt': PropertySchema(
      id: 4,
      name: r'feedDt',
      type: IsarType.string,
    ),
    r'feedFile': PropertySchema(
      id: 5,
      name: r'feedFile',
      type: IsarType.string,
    ),
    r'feedType': PropertySchema(
      id: 6,
      name: r'feedType',
      type: IsarType.string,
    ),
    r'glat': PropertySchema(
      id: 7,
      name: r'glat',
      type: IsarType.string,
    ),
    r'glong': PropertySchema(
      id: 8,
      name: r'glong',
      type: IsarType.string,
    ),
    r'groupName': PropertySchema(
      id: 9,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 10,
      name: r'id',
      type: IsarType.string,
    ),
    r'photos': PropertySchema(
      id: 11,
      name: r'photos',
      type: IsarType.stringList,
    ),
    r'text': PropertySchema(
      id: 12,
      name: r'text',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 13,
      name: r'title',
      type: IsarType.string,
    ),
    r'userEmail': PropertySchema(
      id: 14,
      name: r'userEmail',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 15,
      name: r'userName',
      type: IsarType.string,
    ),
    r'userProfilePic': PropertySchema(
      id: 16,
      name: r'userProfilePic',
      type: IsarType.string,
    )
  },
  estimateSize: _informationLocalModelEstimateSize,
  serialize: _informationLocalModelSerialize,
  deserialize: _informationLocalModelDeserialize,
  deserializeProp: _informationLocalModelDeserializeProp,
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
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'text': IndexSchema(
      id: 5145922347574273553,
      name: r'text',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'text',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'userEmail': IndexSchema(
      id: -7139880982916714350,
      name: r'userEmail',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userEmail',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'userName': IndexSchema(
      id: -1677712070637581736,
      name: r'userName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userName',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'feedDt': IndexSchema(
      id: 7742835325755882436,
      name: r'feedDt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'feedDt',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'feedType': IndexSchema(
      id: 8613721165025455693,
      name: r'feedType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'feedType',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'eventLocation': IndexSchema(
      id: -6538239573066494985,
      name: r'eventLocation',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventLocation',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _informationLocalModelGetId,
  getLinks: _informationLocalModelGetLinks,
  attach: _informationLocalModelAttach,
  version: '3.4.1',
);

int _informationLocalModelEstimateSize(
  InformationLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.eventEndDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.eventLocation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.eventStartDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.feedDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.feedFile;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.feedType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.glat;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.glong;
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
  bytesCount += 3 + object.photos.length * 3;
  {
    for (var i = 0; i < object.photos.length; i++) {
      final value = object.photos[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.text;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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

void _informationLocalModelSerialize(
  InformationLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.eventDuration);
  writer.writeString(offsets[1], object.eventEndDt);
  writer.writeString(offsets[2], object.eventLocation);
  writer.writeString(offsets[3], object.eventStartDt);
  writer.writeString(offsets[4], object.feedDt);
  writer.writeString(offsets[5], object.feedFile);
  writer.writeString(offsets[6], object.feedType);
  writer.writeString(offsets[7], object.glat);
  writer.writeString(offsets[8], object.glong);
  writer.writeString(offsets[9], object.groupName);
  writer.writeString(offsets[10], object.id);
  writer.writeStringList(offsets[11], object.photos);
  writer.writeString(offsets[12], object.text);
  writer.writeString(offsets[13], object.title);
  writer.writeString(offsets[14], object.userEmail);
  writer.writeString(offsets[15], object.userName);
  writer.writeString(offsets[16], object.userProfilePic);
}

InformationLocalModel _informationLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InformationLocalModel();
  object.eventDuration = reader.readLongOrNull(offsets[0]);
  object.eventEndDt = reader.readStringOrNull(offsets[1]);
  object.eventLocation = reader.readStringOrNull(offsets[2]);
  object.eventStartDt = reader.readStringOrNull(offsets[3]);
  object.feedDt = reader.readStringOrNull(offsets[4]);
  object.feedFile = reader.readStringOrNull(offsets[5]);
  object.feedType = reader.readStringOrNull(offsets[6]);
  object.glat = reader.readStringOrNull(offsets[7]);
  object.glong = reader.readStringOrNull(offsets[8]);
  object.groupName = reader.readStringOrNull(offsets[9]);
  object.id = reader.readString(offsets[10]);
  object.isarId = id;
  object.photos = reader.readStringList(offsets[11]) ?? [];
  object.text = reader.readStringOrNull(offsets[12]);
  object.title = reader.readStringOrNull(offsets[13]);
  object.userEmail = reader.readStringOrNull(offsets[14]);
  object.userName = reader.readStringOrNull(offsets[15]);
  object.userProfilePic = reader.readStringOrNull(offsets[16]);
  return object;
}

P _informationLocalModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
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
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringList(offset) ?? []) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _informationLocalModelGetId(InformationLocalModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _informationLocalModelGetLinks(
    InformationLocalModel object) {
  return [];
}

void _informationLocalModelAttach(
    IsarCollection<dynamic> col, Id id, InformationLocalModel object) {
  object.isarId = id;
}

extension InformationLocalModelByIndex
    on IsarCollection<InformationLocalModel> {
  Future<InformationLocalModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  InformationLocalModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<InformationLocalModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<InformationLocalModel?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(InformationLocalModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(InformationLocalModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<InformationLocalModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<InformationLocalModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension InformationLocalModelQueryWhereSort
    on QueryBuilder<InformationLocalModel, InformationLocalModel, QWhere> {
  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InformationLocalModelQueryWhere on QueryBuilder<InformationLocalModel,
    InformationLocalModel, QWhereClause> {
  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
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

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
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

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
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

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [null],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      titleEqualTo(String? title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      titleNotEqualTo(String? title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'text',
        value: [null],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'text',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      textEqualTo(String? text) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'text',
        value: [text],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      textNotEqualTo(String? text) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'text',
              lower: [],
              upper: [text],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'text',
              lower: [text],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'text',
              lower: [text],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'text',
              lower: [],
              upper: [text],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userEmail',
        value: [null],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userEmail',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userEmailEqualTo(String? userEmail) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userEmail',
        value: [userEmail],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userEmailNotEqualTo(String? userEmail) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userEmail',
              lower: [],
              upper: [userEmail],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userEmail',
              lower: [userEmail],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userEmail',
              lower: [userEmail],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userEmail',
              lower: [],
              upper: [userEmail],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userName',
        value: [null],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userNameEqualTo(String? userName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userName',
        value: [userName],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      userNameNotEqualTo(String? userName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [],
              upper: [userName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [userName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [userName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [],
              upper: [userName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'feedDt',
        value: [null],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'feedDt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedDtEqualTo(String? feedDt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'feedDt',
        value: [feedDt],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedDtNotEqualTo(String? feedDt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedDt',
              lower: [],
              upper: [feedDt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedDt',
              lower: [feedDt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedDt',
              lower: [feedDt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedDt',
              lower: [],
              upper: [feedDt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'feedType',
        value: [null],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'feedType',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedTypeEqualTo(String? feedType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'feedType',
        value: [feedType],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      feedTypeNotEqualTo(String? feedType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedType',
              lower: [],
              upper: [feedType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedType',
              lower: [feedType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedType',
              lower: [feedType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'feedType',
              lower: [],
              upper: [feedType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      eventLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventLocation',
        value: [null],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      eventLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'eventLocation',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      eventLocationEqualTo(String? eventLocation) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventLocation',
        value: [eventLocation],
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterWhereClause>
      eventLocationNotEqualTo(String? eventLocation) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventLocation',
              lower: [],
              upper: [eventLocation],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventLocation',
              lower: [eventLocation],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventLocation',
              lower: [eventLocation],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventLocation',
              lower: [],
              upper: [eventLocation],
              includeUpper: false,
            ));
      }
    });
  }
}

extension InformationLocalModelQueryFilter on QueryBuilder<
    InformationLocalModel, InformationLocalModel, QFilterCondition> {
  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventDurationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eventDuration',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventDurationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eventDuration',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventDurationEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventDurationGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventDurationLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventDurationBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventDuration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eventEndDt',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eventEndDt',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventEndDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventEndDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventEndDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventEndDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventEndDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventEndDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      eventEndDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventEndDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      eventEndDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventEndDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventEndDt',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventEndDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventEndDt',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eventLocation',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eventLocation',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventLocation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      eventLocationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      eventLocationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventLocation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventLocation',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventLocation',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eventStartDt',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eventStartDt',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventStartDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventStartDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventStartDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventStartDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventStartDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventStartDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      eventStartDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventStartDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      eventStartDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventStartDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventStartDt',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> eventStartDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventStartDt',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'feedDt',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'feedDt',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feedDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'feedDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'feedDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'feedDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'feedDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'feedDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      feedDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'feedDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      feedDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'feedDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feedDt',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'feedDt',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'feedFile',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'feedFile',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feedFile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'feedFile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'feedFile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'feedFile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'feedFile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'feedFile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      feedFileContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'feedFile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      feedFileMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'feedFile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feedFile',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedFileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'feedFile',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'feedType',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'feedType',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feedType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'feedType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'feedType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'feedType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'feedType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'feedType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      feedTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'feedType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      feedTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'feedType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feedType',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> feedTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'feedType',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'glat',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'glat',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'glat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'glat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'glat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'glat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'glat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'glat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      glatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'glat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      glatMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'glat',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'glat',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'glat',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'glong',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'glong',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'glong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'glong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'glong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'glong',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'glong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'glong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      glongContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'glong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      glongMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'glong',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'glong',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> glongIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'glong',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photos',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      photosElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      photosElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photos',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photos',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photos',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photos',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photos',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photos',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photos',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photos',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> photosLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photos',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
          QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userEmail',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userEmail',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailEqualTo(
    String? value, {
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailGreaterThan(
    String? value, {
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailLessThan(
    String? value, {
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userProfilePicIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userProfilePic',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userProfilePicIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userProfilePic',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
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

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userProfilePicIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userProfilePic',
        value: '',
      ));
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel,
      QAfterFilterCondition> userProfilePicIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userProfilePic',
        value: '',
      ));
    });
  }
}

extension InformationLocalModelQueryObject on QueryBuilder<
    InformationLocalModel, InformationLocalModel, QFilterCondition> {}

extension InformationLocalModelQueryLinks on QueryBuilder<InformationLocalModel,
    InformationLocalModel, QFilterCondition> {}

extension InformationLocalModelQuerySortBy
    on QueryBuilder<InformationLocalModel, InformationLocalModel, QSortBy> {
  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDuration', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDuration', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventEndDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventEndDt', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventEndDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventEndDt', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventStartDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventStartDt', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByEventStartDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventStartDt', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByFeedDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedDt', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByFeedDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedDt', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByFeedFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedFile', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByFeedFileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedFile', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByFeedType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedType', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByFeedTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedType', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByGlat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glat', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByGlatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glat', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByGlong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glong', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByGlongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glong', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByUserProfilePic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      sortByUserProfilePicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.desc);
    });
  }
}

extension InformationLocalModelQuerySortThenBy
    on QueryBuilder<InformationLocalModel, InformationLocalModel, QSortThenBy> {
  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDuration', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventDuration', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventEndDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventEndDt', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventEndDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventEndDt', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventLocation', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventStartDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventStartDt', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByEventStartDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventStartDt', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByFeedDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedDt', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByFeedDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedDt', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByFeedFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedFile', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByFeedFileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedFile', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByFeedType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedType', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByFeedTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feedType', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByGlat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glat', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByGlatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glat', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByGlong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glong', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByGlongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glong', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByUserProfilePic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.asc);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QAfterSortBy>
      thenByUserProfilePicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.desc);
    });
  }
}

extension InformationLocalModelQueryWhereDistinct
    on QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct> {
  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByEventDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventDuration');
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByEventEndDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventEndDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByEventLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventLocation',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByEventStartDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventStartDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByFeedDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'feedDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByFeedFile({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'feedFile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByFeedType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'feedType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByGlat({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'glat', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByGlong({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'glong', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByGroupName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByPhotos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photos');
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByUserEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByUserName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InformationLocalModel, InformationLocalModel, QDistinct>
      distinctByUserProfilePic({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userProfilePic',
          caseSensitive: caseSensitive);
    });
  }
}

extension InformationLocalModelQueryProperty on QueryBuilder<
    InformationLocalModel, InformationLocalModel, QQueryProperty> {
  QueryBuilder<InformationLocalModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<InformationLocalModel, int?, QQueryOperations>
      eventDurationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventDuration');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      eventEndDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventEndDt');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      eventLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventLocation');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      eventStartDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventStartDt');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      feedDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'feedDt');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      feedFileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'feedFile');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      feedTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'feedType');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      glatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'glat');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      glongProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'glong');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<InformationLocalModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InformationLocalModel, List<String>, QQueryOperations>
      photosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photos');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      userEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userEmail');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }

  QueryBuilder<InformationLocalModel, String?, QQueryOperations>
      userProfilePicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userProfilePic');
    });
  }
}
