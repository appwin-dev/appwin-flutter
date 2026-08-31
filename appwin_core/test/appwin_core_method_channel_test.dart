import 'package:appwin_core/appwin_core_method_channel.dart';
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
            'bootstrapSession' => 'jeton-de-session',
            'deviceId' => 'appareil-1',
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

  test('bootstrapSession renvoie le jeton du natif', () async {
    expect(await platform.bootstrapSession(), 'jeton-de-session');
    expect(calls.single.arguments, <String, dynamic>{});
  });

  test('bootstrapSession transmet externalId quand il est fourni', () async {
    await platform.bootstrapSession(externalId: 'user-42');

    expect(calls.single.arguments, {'externalId': 'user-42'});
  });

  test('deviceId remonte la valeur du natif', () async {
    expect(await platform.deviceId(), 'appareil-1');
  });
}
