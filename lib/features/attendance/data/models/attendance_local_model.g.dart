// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_local_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetAttendanceLocalModelCollection on Isar {
  IsarCollection<AttendanceLocalModel> get attendanceLocalModels =>
      this.collection();
}

const AttendanceLocalModelSchema = CollectionSchema(
  name: r'AttendanceLocalModel',
  id: 4441021616396493380,
  properties: {
    r'attendanceDt': PropertySchema(
      id: 0,
      name: r'attendanceDt',
      type: IsarType.string,
    ),
    r'attendanceType': PropertySchema(
      id: 1,
      name: r'attendanceType',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 2,
      name: r'category',
      type: IsarType.string,
    ),
    r'diffMinutes': PropertySchema(
      id: 3,
      name: r'diffMinutes',
      type: IsarType.long,
    ),
    r'earlyLeaveMinutes': PropertySchema(
      id: 4,
      name: r'earlyLeaveMinutes',
      type: IsarType.long,
    ),
    r'faceVerified': PropertySchema(
      id: 5,
      name: r'faceVerified',
      type: IsarType.bool,
    ),
    r'groupName': PropertySchema(
      id: 6,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'hasPhoto': PropertySchema(id: 7, name: r'hasPhoto', type: IsarType.bool),
    r'id': PropertySchema(id: 8, name: r'id', type: IsarType.string),
    r'latitude': PropertySchema(
      id: 9,
      name: r'latitude',
      type: IsarType.string,
    ),
    r'locationName': PropertySchema(
      id: 10,
      name: r'locationName',
      type: IsarType.string,
    ),
    r'longitude': PropertySchema(
      id: 11,
      name: r'longitude',
      type: IsarType.string,
    ),
    r'shiftColor': PropertySchema(
      id: 12,
      name: r'shiftColor',
      type: IsarType.string,
    ),
    r'shiftName': PropertySchema(
      id: 13,
      name: r'shiftName',
      type: IsarType.string,
    ),
    r'shiftTimeWindow': PropertySchema(
      id: 14,
      name: r'shiftTimeWindow',
      type: IsarType.string,
    ),
    r'userDuty': PropertySchema(
      id: 15,
      name: r'userDuty',
      type: IsarType.string,
    ),
    r'userEmail': PropertySchema(
      id: 16,
      name: r'userEmail',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 17,
      name: r'userName',
      type: IsarType.string,
    ),
    r'userProfilePic': PropertySchema(
      id: 18,
      name: r'userProfilePic',
      type: IsarType.string,
    ),
  },

  estimateSize: _attendanceLocalModelEstimateSize,
  serialize: _attendanceLocalModelSerialize,
  deserialize: _attendanceLocalModelDeserialize,
  deserializeProp: _attendanceLocalModelDeserializeProp,
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
        ),
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
        ),
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
        ),
      ],
    ),
    r'attendanceDt': IndexSchema(
      id: 6372055994788142268,
      name: r'attendanceDt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'attendanceDt',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'attendanceType': IndexSchema(
      id: -4225268920595181690,
      name: r'attendanceType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'attendanceType',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
    r'locationName': IndexSchema(
      id: 6386693373177518139,
      name: r'locationName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'locationName',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
    r'shiftName': IndexSchema(
      id: -6936267744118447295,
      name: r'shiftName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'shiftName',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _attendanceLocalModelGetId,
  getLinks: _attendanceLocalModelGetLinks,
  attach: _attendanceLocalModelAttach,
  version: '3.4.1',
);

int _attendanceLocalModelEstimateSize(
  AttendanceLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.attendanceDt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.attendanceType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.category.length * 3;
  {
    final value = object.groupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.latitude;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.locationName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.longitude;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.shiftColor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.shiftName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.shiftTimeWindow;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userDuty;
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

void _attendanceLocalModelSerialize(
  AttendanceLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.attendanceDt);
  writer.writeString(offsets[1], object.attendanceType);
  writer.writeString(offsets[2], object.category);
  writer.writeLong(offsets[3], object.diffMinutes);
  writer.writeLong(offsets[4], object.earlyLeaveMinutes);
  writer.writeBool(offsets[5], object.faceVerified);
  writer.writeString(offsets[6], object.groupName);
  writer.writeBool(offsets[7], object.hasPhoto);
  writer.writeString(offsets[8], object.id);
  writer.writeString(offsets[9], object.latitude);
  writer.writeString(offsets[10], object.locationName);
  writer.writeString(offsets[11], object.longitude);
  writer.writeString(offsets[12], object.shiftColor);
  writer.writeString(offsets[13], object.shiftName);
  writer.writeString(offsets[14], object.shiftTimeWindow);
  writer.writeString(offsets[15], object.userDuty);
  writer.writeString(offsets[16], object.userEmail);
  writer.writeString(offsets[17], object.userName);
  writer.writeString(offsets[18], object.userProfilePic);
}

AttendanceLocalModel _attendanceLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AttendanceLocalModel();
  object.attendanceDt = reader.readStringOrNull(offsets[0]);
  object.attendanceType = reader.readStringOrNull(offsets[1]);
  object.category = reader.readString(offsets[2]);
  object.diffMinutes = reader.readLong(offsets[3]);
  object.earlyLeaveMinutes = reader.readLongOrNull(offsets[4]);
  object.faceVerified = reader.readBoolOrNull(offsets[5]);
  object.groupName = reader.readStringOrNull(offsets[6]);
  object.hasPhoto = reader.readBoolOrNull(offsets[7]);
  object.id = reader.readString(offsets[8]);
  object.isarId = id;
  object.latitude = reader.readStringOrNull(offsets[9]);
  object.locationName = reader.readStringOrNull(offsets[10]);
  object.longitude = reader.readStringOrNull(offsets[11]);
  object.shiftColor = reader.readStringOrNull(offsets[12]);
  object.shiftName = reader.readStringOrNull(offsets[13]);
  object.shiftTimeWindow = reader.readStringOrNull(offsets[14]);
  object.userDuty = reader.readStringOrNull(offsets[15]);
  object.userEmail = reader.readStringOrNull(offsets[16]);
  object.userName = reader.readStringOrNull(offsets[17]);
  object.userProfilePic = reader.readStringOrNull(offsets[18]);
  return object;
}

P _attendanceLocalModelDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _attendanceLocalModelGetId(AttendanceLocalModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _attendanceLocalModelGetLinks(
  AttendanceLocalModel object,
) {
  return [];
}

void _attendanceLocalModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  AttendanceLocalModel object,
) {
  object.isarId = id;
}

extension AttendanceLocalModelByIndex on IsarCollection<AttendanceLocalModel> {
  Future<AttendanceLocalModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  AttendanceLocalModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<AttendanceLocalModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<AttendanceLocalModel?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(AttendanceLocalModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(AttendanceLocalModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<AttendanceLocalModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(
    List<AttendanceLocalModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension AttendanceLocalModelQueryWhereSort
    on QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QWhere> {
  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AttendanceLocalModelQueryWhere
    on QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QWhereClause> {
  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
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

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
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

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'id', value: [id]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'userEmail', value: [null]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'userEmail',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userEmailEqualTo(String? userEmail) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'userEmail', value: [userEmail]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userEmailNotEqualTo(String? userEmail) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userEmail',
                lower: [],
                upper: [userEmail],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userEmail',
                lower: [userEmail],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userEmail',
                lower: [userEmail],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userEmail',
                lower: [],
                upper: [userEmail],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'userName', value: [null]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'userName',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userNameEqualTo(String? userName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'userName', value: [userName]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  userNameNotEqualTo(String? userName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userName',
                lower: [],
                upper: [userName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userName',
                lower: [userName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userName',
                lower: [userName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userName',
                lower: [],
                upper: [userName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'attendanceDt', value: [null]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'attendanceDt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceDtEqualTo(String? attendanceDt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'attendanceDt',
          value: [attendanceDt],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceDtNotEqualTo(String? attendanceDt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceDt',
                lower: [],
                upper: [attendanceDt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceDt',
                lower: [attendanceDt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceDt',
                lower: [attendanceDt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceDt',
                lower: [],
                upper: [attendanceDt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'attendanceType', value: [null]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'attendanceType',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceTypeEqualTo(String? attendanceType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'attendanceType',
          value: [attendanceType],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  attendanceTypeNotEqualTo(String? attendanceType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceType',
                lower: [],
                upper: [attendanceType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceType',
                lower: [attendanceType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceType',
                lower: [attendanceType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'attendanceType',
                lower: [],
                upper: [attendanceType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  locationNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'locationName', value: [null]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  locationNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'locationName',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  locationNameEqualTo(String? locationName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'locationName',
          value: [locationName],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  locationNameNotEqualTo(String? locationName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'locationName',
                lower: [],
                upper: [locationName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'locationName',
                lower: [locationName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'locationName',
                lower: [locationName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'locationName',
                lower: [],
                upper: [locationName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  shiftNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'shiftName', value: [null]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  shiftNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'shiftName',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  shiftNameEqualTo(String? shiftName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'shiftName', value: [shiftName]),
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterWhereClause>
  shiftNameNotEqualTo(String? shiftName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'shiftName',
                lower: [],
                upper: [shiftName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'shiftName',
                lower: [shiftName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'shiftName',
                lower: [shiftName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'shiftName',
                lower: [],
                upper: [shiftName],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension AttendanceLocalModelQueryFilter
    on
        QueryBuilder<
          AttendanceLocalModel,
          AttendanceLocalModel,
          QFilterCondition
        > {
  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'attendanceDt'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'attendanceDt'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'attendanceDt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'attendanceDt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'attendanceDt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attendanceDt',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'attendanceDt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'attendanceDt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'attendanceDt',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'attendanceDt',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'attendanceDt', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceDtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'attendanceDt', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'attendanceType'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'attendanceType'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'attendanceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'attendanceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'attendanceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attendanceType',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'attendanceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'attendanceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'attendanceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'attendanceType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'attendanceType', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  attendanceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'attendanceType', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  diffMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'diffMinutes', value: value),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  diffMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'diffMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  diffMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'diffMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  diffMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'diffMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  earlyLeaveMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'earlyLeaveMinutes'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  earlyLeaveMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'earlyLeaveMinutes'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  earlyLeaveMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'earlyLeaveMinutes', value: value),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  earlyLeaveMinutesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'earlyLeaveMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  earlyLeaveMinutesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'earlyLeaveMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  earlyLeaveMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'earlyLeaveMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  faceVerifiedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'faceVerified'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  faceVerifiedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'faceVerified'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  faceVerifiedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'faceVerified', value: value),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'groupName',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'groupName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  hasPhotoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'hasPhoto'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  hasPhotoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'hasPhoto'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  hasPhotoEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasPhoto', value: value),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
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
    AttendanceLocalModel,
    AttendanceLocalModel,
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
    AttendanceLocalModel,
    AttendanceLocalModel,
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
    AttendanceLocalModel,
    AttendanceLocalModel,
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latitude',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'latitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'latitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'latitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'latitude',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'latitude', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  latitudeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'latitude', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'locationName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'locationName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'locationName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'locationName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'locationName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'locationName',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'locationName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'locationName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'locationName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'locationName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'locationName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  locationNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'locationName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'longitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'longitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'longitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'longitude',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'longitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'longitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'longitude',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'longitude',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'longitude', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  longitudeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'longitude', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'shiftColor'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'shiftColor'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shiftColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shiftColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shiftColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shiftColor',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shiftColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shiftColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shiftColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shiftColor',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shiftColor', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shiftColor', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'shiftName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'shiftName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shiftName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shiftName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shiftName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shiftName',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shiftName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shiftName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shiftName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shiftName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shiftName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shiftName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'shiftTimeWindow'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'shiftTimeWindow'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shiftTimeWindow',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shiftTimeWindow',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shiftTimeWindow',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shiftTimeWindow',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shiftTimeWindow',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shiftTimeWindow',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shiftTimeWindow',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shiftTimeWindow',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shiftTimeWindow', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  shiftTimeWindowIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shiftTimeWindow', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'userDuty'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'userDuty'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userDuty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userDuty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userDuty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userDuty',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userDuty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userDuty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userDuty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userDuty',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userDuty', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userDutyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userDuty', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'userEmail'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'userEmail'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userEmail',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userEmail',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userEmail', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userEmail', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'userName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'userName'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userName',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userName', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'userProfilePic'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'userProfilePic'),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userProfilePic',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userProfilePic',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userProfilePic',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userProfilePic',
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
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userProfilePic',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userProfilePic',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userProfilePic',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userProfilePic',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userProfilePic', value: ''),
      );
    });
  }

  QueryBuilder<
    AttendanceLocalModel,
    AttendanceLocalModel,
    QAfterFilterCondition
  >
  userProfilePicIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userProfilePic', value: ''),
      );
    });
  }
}

extension AttendanceLocalModelQueryObject
    on
        QueryBuilder<
          AttendanceLocalModel,
          AttendanceLocalModel,
          QFilterCondition
        > {}

extension AttendanceLocalModelQueryLinks
    on
        QueryBuilder<
          AttendanceLocalModel,
          AttendanceLocalModel,
          QFilterCondition
        > {}

extension AttendanceLocalModelQuerySortBy
    on QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QSortBy> {
  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByAttendanceDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceDt', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByAttendanceDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceDt', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByAttendanceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceType', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByAttendanceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceType', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByDiffMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diffMinutes', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByDiffMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diffMinutes', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByEarlyLeaveMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earlyLeaveMinutes', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByEarlyLeaveMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earlyLeaveMinutes', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByFaceVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'faceVerified', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByFaceVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'faceVerified', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByHasPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasPhoto', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByHasPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasPhoto', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByLocationName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByLocationNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByShiftColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftColor', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByShiftColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftColor', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByShiftName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByShiftNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByShiftTimeWindow() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftTimeWindow', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByShiftTimeWindowDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftTimeWindow', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserDuty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDuty', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserDutyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDuty', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserProfilePic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  sortByUserProfilePicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.desc);
    });
  }
}

extension AttendanceLocalModelQuerySortThenBy
    on QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QSortThenBy> {
  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByAttendanceDt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceDt', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByAttendanceDtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceDt', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByAttendanceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceType', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByAttendanceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attendanceType', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByDiffMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diffMinutes', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByDiffMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diffMinutes', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByEarlyLeaveMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earlyLeaveMinutes', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByEarlyLeaveMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earlyLeaveMinutes', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByFaceVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'faceVerified', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByFaceVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'faceVerified', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByHasPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasPhoto', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByHasPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasPhoto', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByLocationName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByLocationNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByShiftColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftColor', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByShiftColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftColor', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByShiftName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByShiftNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByShiftTimeWindow() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftTimeWindow', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByShiftTimeWindowDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftTimeWindow', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserDuty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDuty', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserDutyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDuty', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserProfilePic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.asc);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QAfterSortBy>
  thenByUserProfilePicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userProfilePic', Sort.desc);
    });
  }
}

extension AttendanceLocalModelQueryWhereDistinct
    on QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct> {
  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByAttendanceDt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attendanceDt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByAttendanceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'attendanceType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByDiffMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'diffMinutes');
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByEarlyLeaveMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'earlyLeaveMinutes');
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByFaceVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'faceVerified');
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByGroupName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByHasPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasPhoto');
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByLatitude({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByLocationName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locationName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByLongitude({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByShiftColor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shiftColor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByShiftName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shiftName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByShiftTimeWindow({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'shiftTimeWindow',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByUserDuty({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userDuty', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByUserEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByUserName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceLocalModel, AttendanceLocalModel, QDistinct>
  distinctByUserProfilePic({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'userProfilePic',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension AttendanceLocalModelQueryProperty
    on
        QueryBuilder<
          AttendanceLocalModel,
          AttendanceLocalModel,
          QQueryProperty
        > {
  QueryBuilder<AttendanceLocalModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  attendanceDtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attendanceDt');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  attendanceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attendanceType');
    });
  }

  QueryBuilder<AttendanceLocalModel, String, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<AttendanceLocalModel, int, QQueryOperations>
  diffMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'diffMinutes');
    });
  }

  QueryBuilder<AttendanceLocalModel, int?, QQueryOperations>
  earlyLeaveMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'earlyLeaveMinutes');
    });
  }

  QueryBuilder<AttendanceLocalModel, bool?, QQueryOperations>
  faceVerifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'faceVerified');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<AttendanceLocalModel, bool?, QQueryOperations>
  hasPhotoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasPhoto');
    });
  }

  QueryBuilder<AttendanceLocalModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  locationNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locationName');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  shiftColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shiftColor');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  shiftNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shiftName');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  shiftTimeWindowProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shiftTimeWindow');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  userDutyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userDuty');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  userEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userEmail');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }

  QueryBuilder<AttendanceLocalModel, String?, QQueryOperations>
  userProfilePicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userProfilePic');
    });
  }
}
