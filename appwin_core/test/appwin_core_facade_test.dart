import 'package:appwin_core/appwin_core.dart';
import 'package:appwin_core/appwin_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Inherits the base class bodies, which all throw UnimplementedError: a
/// stand-in for any bridge failure (missing plugin, platform exception).
class ThrowingPlatform extends AppwinCorePlatform
    with MockPlatformInterfaceMixin {}

class _RecordingPlatform extends AppwinCorePlatform
    with MockPlatformInterfaceMixin {
  final identified = <String>[];

  @override
  Future<void> identify(String externalId, {AppwinUserAttributes? attributes}) async {
    identified.add(externalId);
  }
}

void main() {
  test('the facade never throws when the bridge does', () async {
    AppwinCorePlatform.instance = ThrowingPlatform();

    await AppwinCore.instance.configure(appId: 'app');
    await AppwinCore.instance.logout();
    expect(await AppwinCore.instance.deviceId(), isNull);
    expect(await AppwinCore.instance.getPlatformVersion(), isNull);
    expect(await AppwinCore.instance.hasRegisteredPushToken(), isFalse);
    await AppwinCore.instance.registerPushToken(token: 't');
  });

  test('identify surfaces a bridge failure instead of swallowing it', () {
    AppwinCorePlatform.instance = ThrowingPlatform();

    expect(
      AppwinCore.instance.identify(
        'u1',
        attributes: const AppwinUserAttributes(name: 'Ada'),
      ),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('updateUser surfaces a bridge failure instead of swallowing it', () {
    AppwinCorePlatform.instance = ThrowingPlatform();

    expect(
      AppwinCore.instance.updateUser(const AppwinUserAttributes(plan: 'pro')),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('identify rejects a blank externalId before reaching the bridge', () {
    final platform = _RecordingPlatform();
    AppwinCorePlatform.instance = platform;

    expect(() => AppwinCore.instance.identify('  '), throwsArgumentError);
    expect(platform.identified, isEmpty);
  });

  test('identify forwards the id and attributes when valid', () async {
    final platform = _RecordingPlatform();
    AppwinCorePlatform.instance = platform;

    await AppwinCore.instance.identify('u1');

    expect(platform.identified, ['u1']);
  });

  test('AppwinPush reports not consumed when the bridge fails', () async {
    AppwinCorePlatform.instance = ThrowingPlatform();
    const data = {'appwinType': 'support.message'};

    expect(await AppwinPush.instance.isAppwinPush(data), isFalse);
    expect(await AppwinPush.instance.handleTap(data), isFalse);
    expect(await AppwinPush.instance.handleForeground(data), isFalse);
    expect(await AppwinPush.instance.handleMessage(data), isFalse);
  });
}
