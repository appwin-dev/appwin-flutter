/// Platform contract behind `AppwinAnalytics`.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_analytics.dart' show AppwinAnalyticsConsent;
import 'appwin_analytics_method_channel.dart';

/// Contract each platform implements. Host apps go through
/// `AppwinAnalytics.instance` instead.
abstract class AppwinAnalyticsPlatform extends PlatformInterface {
  /// Constructs a AppwinAnalyticsPlatform.
  AppwinAnalyticsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinAnalyticsPlatform _instance = AppwinAnalyticsMethodChannel();

  /// The implementation in use, method channel by default.
  static AppwinAnalyticsPlatform get instance => _instance;

  static set instance(AppwinAnalyticsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Host OS and version. See `AppwinAnalytics.getPlatformVersion`.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Whether this app may use Analytics. See `AppwinAnalytics.initialize`.
  Future<AppwinInitResult> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Queues a custom event. See `AppwinAnalytics.track`.
  Future<void> track(String name, {Map<String, Object?>? props}) {
    throw UnimplementedError('track() has not been implemented.');
  }

  /// Emits a `screen_view`. See `AppwinAnalytics.screen`.
  Future<void> screen(String name) {
    throw UnimplementedError('screen() has not been implemented.');
  }

  /// Uploads the pending queue now. See `AppwinAnalytics.flush`.
  Future<void> flush() {
    throw UnimplementedError('flush() has not been implemented.');
  }

  /// Relays the analytics consent. See `AppwinAnalytics.setConsent`.
  Future<void> setConsent(AppwinAnalyticsConsent consent) {
    throw UnimplementedError('setConsent() has not been implemented.');
  }
}
