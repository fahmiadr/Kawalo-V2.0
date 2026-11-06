import 'package:flutter/services.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_event_dto.dart';

abstract class PttNativePlatformDataSource {
  Future<void> joinChannel({
    required String channelUrl,
    required String groupUid,
    required String token,
  });

  Future<void> leaveChannel();

  Future<void> startTransmission({required String requestId});

  Future<void> stopTransmission();

  Future<void> updateAuthToken(String token);

  Future<bool> hasRecordAudioPermission();

  Future<bool> requestRecordAudioPermission();

  Stream<PttEventDto> get eventStream;
}

class PttNativePlatformDataSourceImpl implements PttNativePlatformDataSource {
  PttNativePlatformDataSourceImpl({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('kawalo/ptt_control'),
        _eventChannel = eventChannel ?? const EventChannel('kawalo/ptt_events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Future<void> joinChannel({
    required String channelUrl,
    required String groupUid,
    required String token,
  }) async {
    await _methodChannel.invokeMethod<bool>('joinChannel', {
      'channelUrl': channelUrl,
      'groupUid': groupUid,
      'token': token,
    });
  }

  @override
  Future<void> leaveChannel() async {
    await _methodChannel.invokeMethod<bool>('leaveChannel');
  }

  @override
  Future<void> startTransmission({required String requestId}) async {
    await _methodChannel.invokeMethod<bool>('startTransmission', {
      'requestId': requestId,
    });
  }

  @override
  Future<void> stopTransmission() async {
    await _methodChannel.invokeMethod<bool>('stopTransmission');
  }

  @override
  Future<void> updateAuthToken(String token) async {
    await _methodChannel.invokeMethod<bool>('updateAuthToken', {
      'token': token,
    });
  }

  @override
  Future<bool> hasRecordAudioPermission() async {
    final result =
        await _methodChannel.invokeMethod<bool>('hasRecordAudioPermission');
    return result ?? false;
  }

  @override
  Future<bool> requestRecordAudioPermission() async {
    final result =
        await _methodChannel.invokeMethod<bool>('requestRecordAudioPermission');
    return result ?? false;
  }

  late final Stream<PttEventDto> _eventStream = _eventChannel
      .receiveBroadcastStream()
      .map((dynamic event) {
        if (event is Map<dynamic, dynamic>) {
          return PttEventDto.fromMap(event);
        }
        return const PttEventDto(eventType: '', rawMap: {});
      })
      .asBroadcastStream();

  @override
  Stream<PttEventDto> get eventStream => _eventStream;
}
