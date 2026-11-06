import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Model immutable yang merepresentasikan satu pesan Server-Sent Event (SSE).
class SseMessage extends Equatable {
  const SseMessage({
    required this.data,
    this.id,
    this.event,
    this.retry,
  });

  /// Identifier event unik yang dikirimkan server melalui field `id:`.
  final String? id;

  /// Tipe event spesifik yang dikirimkan server melalui field `event:`.
  final String? event;

  /// Payload data utama yang dikirimkan server melalui field `data:`.
  final String data;

  /// Rekomendasi interval waktu rekoneksi (ms) dari field `retry:`.
  final int? retry;

  @override
  List<Object?> get props => [id, event, data, retry];

  @override
  String toString() =>
      'SseMessage(id: $id, event: $event, data: $data, retry: $retry)';
}

/// StreamTransformer yang mengubah stream byte mentah (`Stream<Uint8List>`)
/// menjadi stream record [SseMessage] yang terstruktur.
class SseStreamTransformer
    extends StreamTransformerBase<Uint8List, SseMessage> {
  const SseStreamTransformer();

  @override
  Stream<SseMessage> bind(Stream<Uint8List> stream) {
    return Stream<SseMessage>.eventTransformed(
      stream,
      _SseEventSink.new,
    );
  }
}

class _SseEventSink implements EventSink<Uint8List> {
  _SseEventSink(this._outputSink);

  final EventSink<SseMessage> _outputSink;

  String? _currentId;
  String? _currentEvent;
  final StringBuffer _dataBuffer = StringBuffer();
  int? _currentRetry;
  bool _hasData = false;

  final Utf8Decoder _utf8Decoder = const Utf8Decoder(allowMalformed: true);
  final LineSplitter _lineSplitter = const LineSplitter();
  String _bufferedString = '';

  @override
  void add(Uint8List data) {
    try {
      final decoded = _utf8Decoder.convert(data);
      _bufferedString += decoded;

      final lines = _lineSplitter.convert(_bufferedString);
      final endsWithNewline =
          _bufferedString.endsWith('\n') || _bufferedString.endsWith('\r');

      if (endsWithNewline) {
        _bufferedString = '';
        lines.forEach(_processLine);
      } else if (lines.isNotEmpty) {
        _bufferedString = lines.last;
        for (var i = 0; i < lines.length - 1; i++) {
          _processLine(lines[i]);
        }
      }
    } on Object catch (e, st) {
      _outputSink.addError(e, st);
    }
  }

  void _processLine(String line) {
    // Abaikan komentar SSE (misal keep-alive ": ping")
    if (line.startsWith(':')) {
      return;
    }

    // Baris kosong menandakan akhir dari satu blok event (dispatch trigger)
    if (line.isEmpty) {
      _dispatchEvent();
      return;
    }

    final colonIndex = line.indexOf(':');
    String field;
    String value;

    if (colonIndex == -1) {
      field = line;
      value = '';
    } else {
      field = line.substring(0, colonIndex);
      var valueStart = colonIndex + 1;
      // Jika terdapat leading space tunggal setelah ':', hilangkan
      if (valueStart < line.length && line[valueStart] == ' ') {
        valueStart++;
      }
      value = line.substring(valueStart);
    }

    switch (field) {
      case 'data':
        if (_hasData) {
          _dataBuffer.write('\n');
        }
        _dataBuffer.write(value);
        _hasData = true;
      case 'event':
        _currentEvent = value;
      case 'id':
        if (!value.contains('\u0000')) {
          _currentId = value;
        }
      case 'retry':
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          _currentRetry = parsed;
        }
    }
  }

  void _dispatchEvent() {
    if (_hasData || _currentEvent != null) {
      final message = SseMessage(
        id: _currentId,
        event: _currentEvent,
        data: _dataBuffer.toString(),
        retry: _currentRetry,
      );
      _outputSink.add(message);
    }

    _currentEvent = null;
    _dataBuffer.clear();
    _currentRetry = null;
    _hasData = false;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _outputSink.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_bufferedString.isNotEmpty) {
      _processLine(_bufferedString);
      _bufferedString = '';
    }
    _dispatchEvent();
    _outputSink.close();
  }
}
