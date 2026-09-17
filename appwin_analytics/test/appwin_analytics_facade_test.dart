import 'package:appwin_analytics/appwin_analytics.dart';
import 'package:appwin_analytics/appwin_analytics_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Inherits the base class bodies, which all throw UnimplementedError: a
/// stand-in for any bridge failure (missing plugin, platform exception).
class ThrowingPlatform extends AppwinAnalyticsPlatform
    with MockPlatformInterfaceMixin {}

void main() {
  test('the facade never throws when the bridge does', () async {
    AppwinAnalyticsPlatform.instance = ThrowingPlatform();

    final result = await AppwinAnalytics.instance.initialize();
    expect(result.status, AppwinInitStatus.unknown);

    await AppwinAnalytics.instance.track('purchase', props: {'value': 9.99});
    await AppwinAnalytics.instance.screen('home');
    await AppwinAnalytics.instance.flush();
    await AppwinAnalytics.instance.setConsent(AppwinAnalyticsConsent.denied);
    expect(await AppwinAnalytics.instance.getPlatformVersion(), isNull);
  });
}
