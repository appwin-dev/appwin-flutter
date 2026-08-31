import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwin_support/appwin_support_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppwinSupportMethodChannel platform = AppwinSupportMethodChannel();
  const MethodChannel channel = MethodChannel('appwin_support');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
