import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

/// What the always-on PTT service needs to keep running in the background.
/// The order is the order in which they are requested.
enum BackgroundAccessItem { notifications, microphone, battery }

/// `refused` also covers an item that was asked once and is still missing:
/// the prompt never asks for it again (the user can still change it in the
/// system settings).
enum BackgroundAccessGrant { granted, askable, refused }

class BackgroundAccessStatus extends Equatable {
  const BackgroundAccessStatus({required this.grants, this.skipped = false});

  factory BackgroundAccessStatus.fromMap(Map<String, Object?> map) {
    return BackgroundAccessStatus(
      grants: {
        for (final item in BackgroundAccessItem.values)
          item: BackgroundAccessGrant.values.firstWhere(
            (grant) => grant.name == map[item.name],
            orElse: () => BackgroundAccessGrant.refused,
          ),
      },
      skipped: map['skipped'] == true,
    );
  }

  final Map<BackgroundAccessItem, BackgroundAccessGrant> grants;
  final bool skipped;

  bool get shouldPrompt =>
      !skipped && grants.values.contains(BackgroundAccessGrant.askable);

  @override
  List<Object?> get props => [grants, skipped];
}

/// Android-only bridge to `MainActivity` (`kawalo/background_access`). The
/// native side remembers which items were asked and whether the prompt was
/// skipped, so it survives logout and cache wipes.
class BackgroundAccessService {
  const BackgroundAccessService({
    MethodChannel channel = const MethodChannel('kawalo/background_access'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<BackgroundAccessStatus> status() async {
    final map = await _channel.invokeMapMethod<String, Object?>('status');
    return BackgroundAccessStatus.fromMap(map ?? const {});
  }

  Future<bool> request(BackgroundAccessItem item) async {
    final granted = await _channel.invokeMethod<bool>('request', {
      'item': item.name,
    });
    return granted ?? false;
  }

  Future<void> skip() => _channel.invokeMethod<bool>('skip');
}
