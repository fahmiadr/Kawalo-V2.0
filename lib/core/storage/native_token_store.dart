import 'package:flutter/services.dart';

enum NativeRefreshStatus { ok, rejected, unavailable, noSession }

typedef NativeRefreshResult = ({
  NativeRefreshStatus status,
  String? accessToken,
  String? refreshToken,
});

/// Android bridge to `AuthTokenVault`, the single owner of the token pair
/// since 13 Nov 2026. The PTT service refreshes through the same vault, so
/// Dart must never send a refresh token itself on Android: a second
/// refresher would replay rotated tokens and the server would revoke the
/// whole session.
class NativeTokenStore {
  NativeTokenStore({
    MethodChannel channel = const MethodChannel('kawalo/auth_tokens'),
  }) : _channel = channel {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sessionEnded') await onSessionEnded?.call();
    });
  }

  final MethodChannel _channel;

  /// Called when a refresh started by the PTT service was refused; the vault
  /// is already empty by then.
  Future<void> Function()? onSessionEnded;

  Future<({String? accessToken, String? refreshToken})> read() async {
    final map = await _channel.invokeMapMethod<String, String?>('read');
    return (
      accessToken: map?['accessToken'],
      refreshToken: map?['refreshToken'],
    );
  }

  /// A null field is left as it is.
  Future<void> save({String? accessToken, String? refreshToken}) =>
      _channel.invokeMethod<bool>('save', {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      });

  Future<void> clear() => _channel.invokeMethod<bool>('clear');

  /// The vault refreshes with this base URL even when Dart is not running.
  Future<void> configure(String baseUrl) =>
      _channel.invokeMethod<bool>('configure', {'baseUrl': baseUrl});

  /// [staleAccessToken] is the token the caller found expired; when the vault
  /// already holds a newer one it is returned without a server call.
  Future<NativeRefreshResult> refresh({String? staleAccessToken}) async {
    final map = await _channel.invokeMapMethod<String, String?>('refresh', {
      'staleAccessToken': staleAccessToken,
    });
    final status = NativeRefreshStatus.values.firstWhere(
      (s) => s.name == map?['status'],
      orElse: () => NativeRefreshStatus.unavailable,
    );
    return (
      status: status,
      accessToken: map?['accessToken'],
      refreshToken: map?['refreshToken'],
    );
  }
}
