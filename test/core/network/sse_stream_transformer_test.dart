import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/sse_stream_transformer.dart';

void main() {
  group('SseStreamTransformer Tests', () {
    test('transforms single complete SSE message into SseMessage', () async {
      const payload =
          'id: 101\nevent: new_reply\ndata: {"message": "halo"}\n\n';
      final byteStream = Stream.value(Uint8List.fromList(utf8.encode(payload)));

      final messages =
          await byteStream.transform(const SseStreamTransformer()).toList();

      expect(messages.length, equals(1));
      expect(messages[0].id, equals('101'));
      expect(messages[0].event, equals('new_reply'));
      expect(messages[0].data, equals('{"message": "halo"}'));
    });

    test('ignores keep-alive comment lines starting with colon', () async {
      const payload = ': ping\n\n'
          'id: 102\nevent: new_reply\ndata: {"test": true}\n\n'
          ': ping\n\n';
      final byteStream = Stream.value(Uint8List.fromList(utf8.encode(payload)));

      final messages =
          await byteStream.transform(const SseStreamTransformer()).toList();

      expect(messages.length, equals(1));
      expect(messages[0].id, equals('102'));
      expect(messages[0].event, equals('new_reply'));
      expect(messages[0].data, equals('{"test": true}'));
    });

    test('reassembles fragmented chunks across byte boundaries', () async {
      final chunk1 =
          Uint8List.fromList(utf8.encode('id: 103\nevent: thread_res'));
      final chunk2 =
          Uint8List.fromList(utf8.encode('olved\ndata: {"ok": 1}\n\n'));

      final byteStream = Stream.fromIterable([chunk1, chunk2]);

      final messages =
          await byteStream.transform(const SseStreamTransformer()).toList();

      expect(messages.length, equals(1));
      expect(messages[0].id, equals('103'));
      expect(messages[0].event, equals('thread_resolved'));
      expect(messages[0].data, equals('{"ok": 1}'));
    });

    test('handles multiline data fields joined with newlines', () async {
      const payload = 'event: text\ndata: line 1\ndata: line 2\n\n';
      final byteStream = Stream.value(Uint8List.fromList(utf8.encode(payload)));

      final messages =
          await byteStream.transform(const SseStreamTransformer()).toList();

      expect(messages.length, equals(1));
      expect(messages[0].event, equals('text'));
      expect(messages[0].data, equals('line 1\nline 2'));
    });

    test('parses retry field properly', () async {
      const payload = 'retry: 5000\ndata: hello\n\n';
      final byteStream = Stream.value(Uint8List.fromList(utf8.encode(payload)));

      final messages =
          await byteStream.transform(const SseStreamTransformer()).toList();

      expect(messages.length, equals(1));
      expect(messages[0].retry, equals(5000));
      expect(messages[0].data, equals('hello'));
    });
  });
}
