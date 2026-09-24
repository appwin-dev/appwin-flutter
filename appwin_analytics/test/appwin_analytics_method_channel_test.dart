import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwin_analytics/appwin_analytics_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppwinAnalyticsMethodChannel platform = AppwinAnalyticsMethodChannel();
  const MethodChannel channel = MethodChannel('appwin_analytics');

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
