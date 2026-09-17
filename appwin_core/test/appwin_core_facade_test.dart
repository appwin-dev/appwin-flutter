import 'package:appwin_core/appwin_core.dart';
import 'package:appwin_core/appwin_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Inherits the base class bodies, which all throw UnimplementedError: a
/// stand-in for any bridge failure (missing plugin, platform exception).
class ThrowingPlatform extends AppwinCorePlatform
    with MockPlatformInterfaceMixin {}

void main() {
  test('the facade never throws when the bridge does', () async {
    AppwinCorePlatform.instance = ThrowingPlatform();

    await AppwinCore.instance.configure(appId: 'app');
    expect(await AppwinCore.instance.bootstrapSession(externalId: 'u1'), '');
    await AppwinCore.instance.identify(externalId: 'u1');
    await AppwinCore.instance.clearIdentity();
    await AppwinCore.instance.signOut();
    expect(await AppwinCore.instance.deviceId(), isNull);
    expect(await AppwinCore.instance.getPlatformVersion(), isNull);
    expect(await AppwinCore.instance.hasRegisteredPushToken(), isFalse);
    await AppwinCore.instance.registerPushToken(token: 't');
  });
}
