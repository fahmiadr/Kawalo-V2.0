import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kawalo/background_access');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'status' => {
              'notifications': 'granted',
              'microphone': 'askable',
              'battery': 'refused',
              'skipped': false,
            },
            'request' => true,
            _ => true,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('status parses every item and prompts while one is askable', () async {
    final status = await const BackgroundAccessService().status();

    expect(status.grants, {
      BackgroundAccessItem.notifications: BackgroundAccessGrant.granted,
      BackgroundAccessItem.microphone: BackgroundAccessGrant.askable,
      BackgroundAccessItem.battery: BackgroundAccessGrant.refused,
    });
    expect(status.shouldPrompt, isTrue);
  });

  test('request sends the item name', () async {
    final granted = await const BackgroundAccessService().request(
      BackgroundAccessItem.battery,
    );

    expect(granted, isTrue);
    expect(calls.single.arguments, {'item': 'battery'});
  });

  test('a skipped or unknown status never prompts', () {
    final skipped = BackgroundAccessStatus.fromMap(const {
      'notifications': 'askable',
      'skipped': true,
    });
    final unknown = BackgroundAccessStatus.fromMap(const {});

    expect(skipped.shouldPrompt, isFalse);
    expect(unknown.shouldPrompt, isFalse);
    expect(
      unknown.grants[BackgroundAccessItem.microphone],
      BackgroundAccessGrant.refused,
    );
  });
}
