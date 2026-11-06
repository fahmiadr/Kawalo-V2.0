// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_local_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetGuestLocalModelCollection on Isar {
  IsarCollection<GuestLocalModel> get guestLocalModels => this.collection();
}

const GuestLocalModelSchema = CollectionSchema(
  name: r'GuestLocalModel',
  id: 1735977787913184700,
  properties: {
    r'groupName': PropertySchema(
      id: 0,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'guestAckDt': PropertySchema(
      id: 1,
      name: r'guestAckDt',
      type: IsarType.string,
    ),
    r'guestAddress': PropertySchema(
      id: 2,
      name: r'guestAddress',
      type: IsarType.string,
    ),
    r'guestCategory': PropertySchema(
      id: 3,
      name: r'guestCategory',
      type: IsarType.string,
    ),
    r'guestCheckoutByEmail': PropertySchema(
      id: 4,
      name: r'guestCheckoutByEmail',
      type: IsarType.string,
    ),
    r'guestCheckoutByName': PropertySchema(
      id: 5,
      name: r'guestCheckoutByName',
      type: IsarType.string,
    ),
    r'guestCreatorEmail': PropertySchema(
      id: 6,
      name: r'guestCreatorEmail',
      type: IsarType.string,
    ),
    r'guestCreatorName': PropertySchema(
      id: 7,
      name: r'guestCreatorName',
      type: IsarType.string,
    ),
    r'guestDestination': PropertySchema(
      id: 8,
      name: r'guestDestination',
      type: IsarType.string,
    ),
    r'guestDt': PropertySchema(
      id: 9,
      name: r'guestDt',
      type: IsarType.string,
    ),
    r'guestIdentity': PropertySchema(
      id: 10,
      name: r'guestIdentity',
      type: IsarType.string,
    ),
    r'guestIdentityType': PropertySchema(
      id: 11,
      name: r'guestIdentityType',
      type: IsarType.string,
    ),
    r'guestName': PropertySchema(
      id: 12,
      name: r'guestName',
      type: IsarType.string,
    ),
    r'guestNumber': PropertySchema(
      id: 13,
      name: r'guestNumber',
      type: IsarType.string,
    ),
    r'guestOutDt': PropertySchema(
      id: 14,
      name: r'guestOutDt',
      type: IsarType.string,
    ),
    r'guestPhoto': PropertySchema(
      id: 15,
      name: r'guestPhoto',
      type: IsarType.string,
    ),
    r'guestPurpose': PropertySchema(
      id: 16,
      name: r'guestPurpose',
      type: IsarType.string,
    ),
    r'guestToUserEmail': PropertySchema(
      id: 17,
      name: r'guestToUserEmail',
      type: IsarType.string,
    ),
    r'guestToUserName': PropertySchema(
      id: 18,
      name: r'guestToUserName',
      type: IsarType.string,
    ),
    r'guestType': PropertySchema(
      id: 19,
      name: r'guestType',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 20,
      name: r'id',
      type: IsarType.string,
    ),
    r'qrUid': PropertySchema(
      id: 21,
      name: r'qrUid',
      type: IsarType.string,
    )
  },
  estimateSize: _guestLocalModelEstimateSize,
  serialize: _guestLocalModelSerialize,
  deserialize: _guestLocalModelDeserialize,
  deserializeProp: _guestLocalModelDeserializeProp,
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
    r'guestName': IndexSchema(
      id: 2996057018528647875,
      name: r'guestName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestName',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestNumber': IndexSchema(
      id: -6084855758737296661,
      name: r'guestNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestNumber',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestIdentity': IndexSchema(
      id: 6643770316782273735,
      name: r'guestIdentity',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestIdentity',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestIdentityType': IndexSchema(
      id: 1845731139835425730,
      name: r'guestIdentityType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestIdentityType',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestDt': IndexSchema(
      id: -2810885368020786267,
      name: r'guestDt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestDt',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'guestPurpose': IndexSchema(
      id: 212728384490547875,
      name: r'guestPurpose',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestPurpose',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestDestination': IndexSchema(
      id: -6279419778154029059,
      name: r'guestDestination',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestDestination',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestToUserEmail': IndexSchema(
      id: -1579049051045480246,
      name: r'guestToUserEmail',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestToUserEmail',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestToUserName': IndexSchema(
      id: 3857429599725290753,
      name: r'guestToUserName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestToUserName',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestCreatorEmail': IndexSchema(
      id: 3216848185990283743,
      name: r'guestCreatorEmail',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestCreatorEmail',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestCreatorName': IndexSchema(
      id: -5882448344665427420,
      name: r'guestCreatorName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestCreatorName',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestCategory': IndexSchema(
      id: -7629390168672276211,
      name: r'guestCategory',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestCategory',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'qrUid': IndexSchema(
      id: 1548034150758703993,
      name: r'qrUid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'qrUid',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestAddress': IndexSchema(
      id: -3173956803355601667,
      name: r'guestAddress',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestAddress',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestType': IndexSchema(
      id: 2938590280996667168,
      name: r'guestType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestType',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestCheckoutByEmail': IndexSchema(
      id: 1057102194036815760,
      name: r'guestCheckoutByEmail',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestCheckoutByEmail',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'guestCheckoutByName': IndexSchema(
      id: -5301852255983547173,
      name: r'guestCheckoutByName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'guestCheckoutByName',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _guestLocalModelGetId,
  getLinks: _guestLocalModelGetLinks,
  attach: _guestLocalModelAttach,
  version: '3.4.1',
);

int _guestLocalModelEstimateSize(
  GuestLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.groupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestAckDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestCategory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestCheckoutByEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestCheckoutByName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestCreatorEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestCreatorName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestDestination;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestIdentity;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestIdentityType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestOutDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestPhoto;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestPurpose;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestToUserEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestToUserName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.guestType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.qrUid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _guestLocalModelSerialize(
  GuestLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.groupName);
  writer.writeString(offsets[1], object.guestAckDt);
  writer.writeString(offsets[2], object.guestAddress);
  writer.writeString(offsets[3], object.guestCategory);
  writer.writeString(offsets[4], object.guestCheckoutByEmail);
  writer.writeString(offsets[5], object.guestCheckoutByName);
  writer.writeString(offsets[6], object.guestCreatorEmail);
  writer.writeString(offsets[7], object.guestCreatorName);
  writer.writeString(offsets[8], object.guestDestination);
  writer.writeString(offsets[9], object.guestDt);
  writer.writeString(offsets[10], object.guestIdentity);
  writer.writeString(offsets[11], object.guestIdentityType);
  writer.writeString(offsets[12], object.guestName);
  writer.writeString(offsets[13], object.guestNumber);
  writer.writeString(offsets[14], object.guestOutDt);
  writer.writeString(offsets[15], object.guestPhoto);
  writer.writeString(offsets[16], object.guestPurpose);
  writer.writeString(offsets[17], object.guestToUserEmail);
  writer.writeString(offsets[18], object.guestToUserName);
  writer.writeString(offsets[19], object.guestType);
  writer.writeString(offsets[20], object.id);
  writer.writeString(offsets[21], object.qrUid);
}

GuestLocalModel _guestLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GuestLocalModel();
  object.groupName = reader.readStringOrNull(offsets[0]);
  object.guestAckDt = reader.readStringOrNull(offsets[1]);
  object.guestAddress = reader.readStringOrNull(offsets[2]);
  object.guestCategory = reader.readStringOrNull(offsets[3]);
  object.guestCheckoutByEmail = reader.readStringOrNull(offsets[4]);
  object.guestCheckoutByName = reader.readStringOrNull(offsets[5]);
  object.guestCreatorEmail = reader.readStringOrNull(offsets[6]);
  object.guestCreatorName = reader.readStringOrNull(offsets[7]);
  object.guestDestination = reader.readStringOrNull(offsets[8]);
  object.guestDt = reader.readStringOrNull(offsets[9]);
  object.guestIdentity = reader.readStringOrNull(offsets[10]);
  object.guestIdentityType = reader.readStringOrNull(offsets[11]);
  object.guestName = reader.readStringOrNull(offsets[12]);
  object.guestNumber = reader.readStringOrNull(offsets[13]);
  object.guestOutDt = reader.readStringOrNull(offsets[14]);
  object.guestPhoto = reader.readStringOrNull(offsets[15]);
  object.guestPurpose = reader.readStringOrNull(offsets[16]);
  object.guestToUserEmail = reader.readStringOrNull(offsets[17]);
  object.guestToUserName = reader.readStringOrNull(offsets[18]);
  object.guestType = reader.readStringOrNull(offsets[19]);
  object.id = reader.readString(offsets[20]);
  object.isarId = id;
  object.qrUid = reader.readStringOrNull(offsets[21]);
  return object;
}

P _guestLocalModelDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
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
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _guestLocalModelGetId(GuestLocalModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _guestLocalModelGetLinks(GuestLocalModel object) {
  return [];
}

void _guestLocalModelAttach(
    IsarCollection<dynamic> col, Id id, GuestLocalModel object) {
  object.isarId = id;
}

extension GuestLocalModelByIndex on IsarCollection<GuestLocalModel> {
  Future<GuestLocalModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  GuestLocalModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<GuestLocalModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<GuestLocalModel?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(GuestLocalModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(GuestLocalModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<GuestLocalModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<GuestLocalModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension GuestLocalModelQueryWhereSort
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QWhere> {
  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GuestLocalModelQueryWhere
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QWhereClause> {
  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestName',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNameEqualTo(String? guestName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestName',
        value: [guestName],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNameNotEqualTo(String? guestName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestName',
              lower: [],
              upper: [guestName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestName',
              lower: [guestName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestName',
              lower: [guestName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestName',
              lower: [],
              upper: [guestName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestNumber',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestNumber',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNumberEqualTo(String? guestNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestNumber',
        value: [guestNumber],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestNumberNotEqualTo(String? guestNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestNumber',
              lower: [],
              upper: [guestNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestNumber',
              lower: [guestNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestNumber',
              lower: [guestNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestNumber',
              lower: [],
              upper: [guestNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestIdentity',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestIdentity',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityEqualTo(String? guestIdentity) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestIdentity',
        value: [guestIdentity],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityNotEqualTo(String? guestIdentity) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentity',
              lower: [],
              upper: [guestIdentity],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentity',
              lower: [guestIdentity],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentity',
              lower: [guestIdentity],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentity',
              lower: [],
              upper: [guestIdentity],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestIdentityType',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestIdentityType',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityTypeEqualTo(String? guestIdentityType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestIdentityType',
        value: [guestIdentityType],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestIdentityTypeNotEqualTo(String? guestIdentityType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentityType',
              lower: [],
              upper: [guestIdentityType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentityType',
              lower: [guestIdentityType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentityType',
              lower: [guestIdentityType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestIdentityType',
              lower: [],
              upper: [guestIdentityType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestDt',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestDt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDtEqualTo(String? guestDt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestDt',
        value: [guestDt],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDtNotEqualTo(String? guestDt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDt',
              lower: [],
              upper: [guestDt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDt',
              lower: [guestDt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDt',
              lower: [guestDt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDt',
              lower: [],
              upper: [guestDt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestPurposeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestPurpose',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestPurposeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestPurpose',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestPurposeEqualTo(String? guestPurpose) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestPurpose',
        value: [guestPurpose],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestPurposeNotEqualTo(String? guestPurpose) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestPurpose',
              lower: [],
              upper: [guestPurpose],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestPurpose',
              lower: [guestPurpose],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestPurpose',
              lower: [guestPurpose],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestPurpose',
              lower: [],
              upper: [guestPurpose],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDestinationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestDestination',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDestinationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestDestination',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDestinationEqualTo(String? guestDestination) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestDestination',
        value: [guestDestination],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestDestinationNotEqualTo(String? guestDestination) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDestination',
              lower: [],
              upper: [guestDestination],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDestination',
              lower: [guestDestination],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDestination',
              lower: [guestDestination],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestDestination',
              lower: [],
              upper: [guestDestination],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestToUserEmail',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestToUserEmail',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserEmailEqualTo(String? guestToUserEmail) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestToUserEmail',
        value: [guestToUserEmail],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserEmailNotEqualTo(String? guestToUserEmail) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserEmail',
              lower: [],
              upper: [guestToUserEmail],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserEmail',
              lower: [guestToUserEmail],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserEmail',
              lower: [guestToUserEmail],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserEmail',
              lower: [],
              upper: [guestToUserEmail],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestToUserName',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestToUserName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserNameEqualTo(String? guestToUserName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestToUserName',
        value: [guestToUserName],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestToUserNameNotEqualTo(String? guestToUserName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserName',
              lower: [],
              upper: [guestToUserName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserName',
              lower: [guestToUserName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserName',
              lower: [guestToUserName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestToUserName',
              lower: [],
              upper: [guestToUserName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCreatorEmail',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestCreatorEmail',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorEmailEqualTo(String? guestCreatorEmail) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCreatorEmail',
        value: [guestCreatorEmail],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorEmailNotEqualTo(String? guestCreatorEmail) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorEmail',
              lower: [],
              upper: [guestCreatorEmail],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorEmail',
              lower: [guestCreatorEmail],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorEmail',
              lower: [guestCreatorEmail],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorEmail',
              lower: [],
              upper: [guestCreatorEmail],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCreatorName',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestCreatorName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorNameEqualTo(String? guestCreatorName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCreatorName',
        value: [guestCreatorName],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCreatorNameNotEqualTo(String? guestCreatorName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorName',
              lower: [],
              upper: [guestCreatorName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorName',
              lower: [guestCreatorName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorName',
              lower: [guestCreatorName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCreatorName',
              lower: [],
              upper: [guestCreatorName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCategory',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestCategory',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCategoryEqualTo(String? guestCategory) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCategory',
        value: [guestCategory],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCategoryNotEqualTo(String? guestCategory) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCategory',
              lower: [],
              upper: [guestCategory],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCategory',
              lower: [guestCategory],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCategory',
              lower: [guestCategory],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCategory',
              lower: [],
              upper: [guestCategory],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      qrUidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'qrUid',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      qrUidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'qrUid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      qrUidEqualTo(String? qrUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'qrUid',
        value: [qrUid],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      qrUidNotEqualTo(String? qrUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'qrUid',
              lower: [],
              upper: [qrUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'qrUid',
              lower: [qrUid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'qrUid',
              lower: [qrUid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'qrUid',
              lower: [],
              upper: [qrUid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestAddress',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestAddress',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestAddressEqualTo(String? guestAddress) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestAddress',
        value: [guestAddress],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestAddressNotEqualTo(String? guestAddress) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestAddress',
              lower: [],
              upper: [guestAddress],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestAddress',
              lower: [guestAddress],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestAddress',
              lower: [guestAddress],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestAddress',
              lower: [],
              upper: [guestAddress],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestType',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestType',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestTypeEqualTo(String? guestType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestType',
        value: [guestType],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestTypeNotEqualTo(String? guestType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestType',
              lower: [],
              upper: [guestType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestType',
              lower: [guestType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestType',
              lower: [guestType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestType',
              lower: [],
              upper: [guestType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCheckoutByEmail',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestCheckoutByEmail',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByEmailEqualTo(String? guestCheckoutByEmail) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCheckoutByEmail',
        value: [guestCheckoutByEmail],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByEmailNotEqualTo(String? guestCheckoutByEmail) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByEmail',
              lower: [],
              upper: [guestCheckoutByEmail],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByEmail',
              lower: [guestCheckoutByEmail],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByEmail',
              lower: [guestCheckoutByEmail],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByEmail',
              lower: [],
              upper: [guestCheckoutByEmail],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCheckoutByName',
        value: [null],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'guestCheckoutByName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByNameEqualTo(String? guestCheckoutByName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'guestCheckoutByName',
        value: [guestCheckoutByName],
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterWhereClause>
      guestCheckoutByNameNotEqualTo(String? guestCheckoutByName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByName',
              lower: [],
              upper: [guestCheckoutByName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByName',
              lower: [guestCheckoutByName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByName',
              lower: [guestCheckoutByName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'guestCheckoutByName',
              lower: [],
              upper: [guestCheckoutByName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension GuestLocalModelQueryFilter
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QFilterCondition> {
  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameEqualTo(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameGreaterThan(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameLessThan(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameBetween(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameStartsWith(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameEndsWith(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestAckDt',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestAckDt',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestAckDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestAckDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestAckDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestAckDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestAckDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestAckDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestAckDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestAckDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestAckDt',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAckDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestAckDt',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestAddress',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestAddress',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestCategory',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestCategory',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestCheckoutByEmail',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestCheckoutByEmail',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCheckoutByEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestCheckoutByEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestCheckoutByEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestCheckoutByEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestCheckoutByEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestCheckoutByEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestCheckoutByEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestCheckoutByEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCheckoutByEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestCheckoutByEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestCheckoutByName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestCheckoutByName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCheckoutByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestCheckoutByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestCheckoutByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestCheckoutByName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestCheckoutByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestCheckoutByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestCheckoutByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestCheckoutByName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCheckoutByName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCheckoutByNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestCheckoutByName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestCreatorEmail',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestCreatorEmail',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCreatorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestCreatorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestCreatorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestCreatorEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestCreatorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestCreatorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestCreatorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestCreatorEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCreatorEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestCreatorEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestCreatorName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestCreatorName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCreatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestCreatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestCreatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestCreatorName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestCreatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestCreatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestCreatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestCreatorName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestCreatorName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestCreatorNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestCreatorName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestDestination',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestDestination',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestDestination',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestDestination',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestDestination',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestDestination',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestDestination',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestDestination',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestDestination',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestDestination',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestDestination',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDestinationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestDestination',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestDt',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestDt',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestDt',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestDt',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestIdentity',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestIdentity',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestIdentity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestIdentity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestIdentity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestIdentity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestIdentity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestIdentity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestIdentity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestIdentity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestIdentity',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestIdentity',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestIdentityType',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestIdentityType',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestIdentityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestIdentityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestIdentityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestIdentityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestIdentityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestIdentityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestIdentityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestIdentityType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestIdentityType',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestIdentityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestIdentityType',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestNumber',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestNumber',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestOutDt',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestOutDt',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestOutDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestOutDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestOutDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestOutDt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestOutDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestOutDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestOutDt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestOutDt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestOutDt',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestOutDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestOutDt',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestPhoto',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestPhoto',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestPhoto',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestPhoto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestPhoto',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestPhoto',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPhotoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestPhoto',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestPurpose',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestPurpose',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestPurpose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestPurpose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestPurpose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestPurpose',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestPurpose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestPurpose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestPurpose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestPurpose',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestPurpose',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestPurposeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestPurpose',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestToUserEmail',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestToUserEmail',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestToUserEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestToUserEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestToUserEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestToUserEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestToUserEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestToUserEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestToUserEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestToUserEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestToUserEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestToUserEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestToUserName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestToUserName',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestToUserName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestToUserName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestToUserName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestToUserName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestToUserName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestToUserName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestToUserName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestToUserName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestToUserName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestToUserNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestToUserName',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guestType',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guestType',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guestType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guestType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guestType',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      guestTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guestType',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idEqualTo(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idStartsWith(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idEndsWith(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      isarIdGreaterThan(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      isarIdLessThan(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      isarIdBetween(
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

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'qrUid',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'qrUid',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'qrUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'qrUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'qrUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'qrUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'qrUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'qrUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'qrUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'qrUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'qrUid',
        value: '',
      ));
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterFilterCondition>
      qrUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'qrUid',
        value: '',
      ));
    });
  }
}

extension GuestLocalModelQueryObject
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QFilterCondition> {}

extension GuestLocalModelQueryLinks
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QFilterCondition> {}

extension GuestLocalModelQuerySortBy
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QSortBy> {
  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestAckDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAckDt', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestAckDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAckDt', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAddress', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAddress', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCategory', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCategory', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCheckoutByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByEmail', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCheckoutByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByEmail', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCheckoutByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCheckoutByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCreatorEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorEmail', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCreatorEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorEmail', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCreatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestCreatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestDestination() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDestination', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestDestinationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDestination', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> sortByGuestDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDt', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDt', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestIdentity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentity', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestIdentityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentity', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestIdentityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentityType', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestIdentityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentityType', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestNumber', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestNumber', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestOutDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestOutDt', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestOutDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestOutDt', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhoto', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhoto', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestPurpose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPurpose', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestPurposeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPurpose', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestToUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserEmail', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestToUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserEmail', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestToUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestToUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestType', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByGuestTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestType', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> sortByQrUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrUid', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      sortByQrUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrUid', Sort.desc);
    });
  }
}

extension GuestLocalModelQuerySortThenBy
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QSortThenBy> {
  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestAckDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAckDt', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestAckDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAckDt', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAddress', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestAddress', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCategory', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCategory', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCheckoutByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByEmail', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCheckoutByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByEmail', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCheckoutByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCheckoutByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCheckoutByName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCreatorEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorEmail', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCreatorEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorEmail', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCreatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestCreatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestCreatorName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestDestination() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDestination', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestDestinationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDestination', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> thenByGuestDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDt', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDt', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestIdentity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentity', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestIdentityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentity', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestIdentityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentityType', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestIdentityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestIdentityType', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestNumber', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestNumber', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestOutDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestOutDt', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestOutDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestOutDt', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhoto', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPhoto', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestPurpose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPurpose', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestPurposeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestPurpose', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestToUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserEmail', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestToUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserEmail', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestToUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserName', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestToUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestToUserName', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestType', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByGuestTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestType', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy> thenByQrUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrUid', Sort.asc);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QAfterSortBy>
      thenByQrUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrUid', Sort.desc);
    });
  }
}

extension GuestLocalModelQueryWhereDistinct
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct> {
  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct> distinctByGroupName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestAckDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestAckDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestAddress', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestCategory',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestCheckoutByEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestCheckoutByEmail',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestCheckoutByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestCheckoutByName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestCreatorEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestCreatorEmail',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestCreatorName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestCreatorName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestDestination({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestDestination',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct> distinctByGuestDt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestIdentity({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestIdentity',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestIdentityType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestIdentityType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct> distinctByGuestName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestOutDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestOutDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestPhoto({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestPhoto', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestPurpose({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestPurpose', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestToUserEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestToUserEmail',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct>
      distinctByGuestToUserName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestToUserName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct> distinctByGuestType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GuestLocalModel, GuestLocalModel, QDistinct> distinctByQrUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'qrUid', caseSensitive: caseSensitive);
    });
  }
}

extension GuestLocalModelQueryProperty
    on QueryBuilder<GuestLocalModel, GuestLocalModel, QQueryProperty> {
  QueryBuilder<GuestLocalModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations> groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestAckDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestAckDt');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestAddress');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestCategory');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestCheckoutByEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestCheckoutByEmail');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestCheckoutByNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestCheckoutByName');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestCreatorEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestCreatorEmail');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestCreatorNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestCreatorName');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestDestinationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestDestination');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations> guestDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestDt');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestIdentityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestIdentity');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestIdentityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestIdentityType');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations> guestNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestName');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestNumber');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestOutDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestOutDt');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestPhotoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestPhoto');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestPurposeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestPurpose');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestToUserEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestToUserEmail');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations>
      guestToUserNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestToUserName');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations> guestTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestType');
    });
  }

  QueryBuilder<GuestLocalModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GuestLocalModel, String?, QQueryOperations> qrUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'qrUid');
    });
  }
}
