import 'package:equatable/equatable.dart';

/// Pure DTO yang merepresentasikan event platform native dari `kawalo/ptt_events`.
///
/// DILARANG KERAS mengimpor Domain Entity ke dalam file DTO ini.
class PttSpeakerDto extends Equatable {
  const PttSpeakerDto({
    required this.userId,
    required this.name,
    required this.role,
  });

  factory PttSpeakerDto.fromMap(Map<dynamic, dynamic> map) {
    return PttSpeakerDto(
      userId: map['userId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'GUARD',
    );
  }

  final String userId;
  final String name;
  final String role;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'role': role,
      };

  @override
  List<Object?> get props => [userId, name, role];
}

class PttFloorStateDto extends Equatable {
  const PttFloorStateDto({
    required this.state,
    this.speaker,
    this.memberCount = 1,
  });

  factory PttFloorStateDto.fromMap(Map<dynamic, dynamic> map) {
    final speakerMap = map['speaker'];
    return PttFloorStateDto(
      state: map['state']?.toString() ?? 'IDLE',
      speaker: speakerMap is Map<dynamic, dynamic>
          ? PttSpeakerDto.fromMap(speakerMap)
          : null,
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 1,
    );
  }

  final String state;
  final PttSpeakerDto? speaker;
  final int memberCount;

  @override
  List<Object?> get props => [state, speaker, memberCount];
}

class PttTransmissionEventDto extends Equatable {
  const PttTransmissionEventDto({
    required this.state,
    this.requestId,
    this.reason,
    this.preemptedBy,
    this.leaseTtlMs,
    this.currentSpeaker,
  });

  factory PttTransmissionEventDto.fromMap(Map<dynamic, dynamic> map) {
    final speakerMap = map['currentSpeaker'];
    return PttTransmissionEventDto(
      state: map['state']?.toString() ?? 'IDLE',
      requestId: map['requestId']?.toString(),
      reason: map['reason']?.toString(),
      preemptedBy: map['preemptedBy']?.toString(),
      leaseTtlMs: (map['leaseTtlMs'] as num?)?.toInt(),
      currentSpeaker: speakerMap is Map<dynamic, dynamic>
          ? PttSpeakerDto.fromMap(speakerMap)
          : null,
    );
  }

  final String state;
  final String? requestId;
  final String? reason;
  final String? preemptedBy;
  final int? leaseTtlMs;
  final PttSpeakerDto? currentSpeaker;

  @override
  List<Object?> get props => [
        state,
        requestId,
        reason,
        preemptedBy,
        leaseTtlMs,
        currentSpeaker,
      ];
}

class PttEventDto extends Equatable {
  const PttEventDto({
    required this.eventType,
    required this.rawMap,
  });

  factory PttEventDto.fromMap(Map<dynamic, dynamic> map) {
    final eventType = map['event']?.toString() ?? '';
    final data = map['data'];
    final dataMap = data is Map<dynamic, dynamic> ? data : <dynamic, dynamic>{};

    return PttEventDto(
      eventType: eventType,
      rawMap: dataMap,
    );
  }

  final String eventType;
  final Map<dynamic, dynamic> rawMap;

  @override
  List<Object?> get props => [eventType, rawMap];
}
