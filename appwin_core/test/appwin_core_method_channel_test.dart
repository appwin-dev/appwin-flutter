import 'package:appwin_core/appwin_core_method_channel.dart';
import 'package:appwin_core/appwin_user_attributes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests cover **what goes out on the method channel**.
///
/// The Dart layer has almost no logic, but the little it has shows up natively
/// and nowhere else - a `null` argument forwarded instead of removed, and native
/// reads "clear" where the app meant
/// « ne touche pas ».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = AppwinCoreMethodChannel();
  const channel = MethodChannel('appwin_core');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'deviceId' => 'appareil-1',
            'isAppwinPush' || 'handlePushTap' || 'handlePushMessage' => true,
            'handlePushForeground' => false,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configure ne transmet que ce qui est renseigné', () async {
    await platform.configure(appId: 'app-1');

    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, {'appId': 'app-1'});
  });

  test('configure transmet les URL de développement quand elles sont fournies', () async {
    await platform.configure(
      appId: 'app-1',
      baseUrl: 'http://localhost:3000',
      realtimeBaseUrl: 'ws://localhost:3003',
    );

    expect(calls.single.arguments, {
      'appId': 'app-1',
      'baseUrl': 'http://localhost:3000',
      'realtimeBaseUrl': 'ws://localhost:3003',
    });
  });

  test('configure refuse un appId vide sans toucher au natif', () async {
    // Checked on the Dart side: the error surfaces with a usable stack rather
    // than an opaque bridge exception.
    expect(() => platform.configure(appId: '   '), throwsArgumentError);
    expect(calls, isEmpty);
  });

  test('identify without attributes sends only the externalId', () async {
    await platform.identify('user-42');

    expect(calls.single.method, 'identify');
    expect(calls.single.arguments, {'externalId': 'user-42'});
  });

  test('identify sends only the attributes that are set', () async {
    await platform.identify(
      'user-42',
      attributes: const AppwinUserAttributes(email: 'a@b.c', plan: 'premium'),
    );

    expect(calls.single.arguments, {
      'externalId': 'user-42',
      'attributes': {'email': 'a@b.c', 'plan': 'premium'},
    });
  });

  test('identify rejects a blank externalId without reaching native', () {
    expect(() => platform.identify('  '), throwsArgumentError);
    expect(calls, isEmpty);
  });

  test('updateUser omits null attributes so the server keeps them', () async {
    await platform.updateUser(const AppwinUserAttributes(name: 'Ada'));

    expect(calls.single.method, 'updateUser');
    expect(calls.single.arguments, {
      'attributes': {'name': 'Ada'},
    });
  });

  test('logout goes over with no arguments', () async {
    await platform.logout();

    expect(calls.single.method, 'logout');
    expect(calls.single.arguments, isNull);
  });

  test('deviceId remonte la valeur du natif', () async {
    expect(await platform.deviceId(), 'appareil-1');
  });

  test('registerPushToken transmet la plateforme dérivée du device', () async {
    await platform.registerPushToken(token: 'abc');

    expect(calls.single.method, 'registerPushToken');
    expect(calls.single.arguments, {
      'token': 'abc',
      'platform': 'android',
      'pushOptIn': true,
    });
  });

  test('registerPushToken refuse un jeton vide sans toucher au natif', () async {
    expect(() => platform.registerPushToken(token: '   '), throwsArgumentError);
    expect(calls, isEmpty);
  });

  test('push data goes over as received, nested values included', () async {
    final data = <String, dynamic>{
      'appwinType': 'support.message',
      'data': {'deeplink': 'appwin://support/conversation/c1'},
    };

    expect(await platform.handlePushTap(data), isTrue);

    expect(calls.single.method, 'handlePushTap');
    expect(calls.single.arguments, {'data': data});
  });

  test('handlePushForeground only sends the title and body it has', () async {
    await platform.handlePushForeground({'appwinType': 'support.message'});
    await platform.handlePushForeground(
      {'appwinType': 'support.message'},
      title: 'Agent',
      body: 'Hello',
    );

    expect(calls[0].arguments, {
      'data': {'appwinType': 'support.message'},
    });
    expect(calls[1].arguments, {
      'data': {'appwinType': 'support.message'},
      'title': 'Agent',
      'body': 'Hello',
    });
  });

  test('push calls read a missing native answer as not consumed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    expect(await platform.isAppwinPush({'appwinType': 'x'}), isFalse);
    expect(await platform.handlePushMessage({'appwinType': 'x'}), isFalse);
  });
}
