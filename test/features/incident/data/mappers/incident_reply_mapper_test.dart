import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/sse_stream_transformer.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_reply_mapper.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';

void main() {
  test('parseSseMessage thread_resolved membaca kunci snake_case', () {
    final event = IncidentReplyMapper.parseSseMessage(
      const SseMessage(
        event: 'thread_resolved',
        data: '{"incident_id":"inc_1","resolved_by":"u2",'
            '"resolved_by_name":"Sari",'
            '"resolved_at":"2026-11-04T11:00:00.000Z"}',
      ),
    );

    expect(event, isA<IncidentResolvedStreamEvent>());
    final e = event! as IncidentResolvedStreamEvent;
    expect(e.incidentId, 'inc_1');
    expect(e.resolvedBy, 'u2');
    expect(e.resolvedByName, 'Sari');
    expect(e.resolvedAt, DateTime.parse('2026-11-04T11:00:00.000Z'));
  });

  test('parseSseMessage incident_deleted membaca kunci snake_case', () {
    final event = IncidentReplyMapper.parseSseMessage(
      const SseMessage(
        event: 'incident_deleted',
        data: '{"incident_id":"inc_1","deleted_at":"2026-11-04T12:00:00.000Z"}',
      ),
    );

    final e = event! as IncidentDeletedStreamEvent;
    expect(e.incidentId, 'inc_1');
    expect(e.deletedAt, DateTime.parse('2026-11-04T12:00:00.000Z'));
  });
}
