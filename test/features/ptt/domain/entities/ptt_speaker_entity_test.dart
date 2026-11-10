import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_event_dto.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';

void main() {
  String labelOf(String role) =>
      PttSpeakerEntity(userId: 'u', name: 'n', role: role).roleLabel;

  test('roleLabel tells ADMIN, GUARD and other roles apart', () {
    expect(labelOf('admin'), 'ADMIN');
    expect(labelOf('GUARD'), 'PETUGAS');
    expect(labelOf('user'), 'USER');
    expect(labelOf(''), 'ANGGOTA');
  });

  test('a speaker without a role stays unknown instead of becoming GUARD', () {
    final dto = PttSpeakerDto.fromMap(const {'userId': 'u1', 'name': 'Budi'});

    expect(dto.role, '');
  });

  test('a floor state without memberCount keeps the count unknown', () {
    final dto = PttFloorStateDto.fromMap(const {'state': 'IDLE'});

    expect(dto.memberCount, isNull);
  });
}
