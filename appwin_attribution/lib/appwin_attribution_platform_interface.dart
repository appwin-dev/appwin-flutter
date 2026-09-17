/// Platform contract behind `AppwinAttribution`.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_attribution.dart' show AppwinAdvertisingConsent;
import 'appwin_attribution_method_channel.dart';

/// Contract each platform implements. Host apps go through
/// `AppwinAttribution.instance` instead.
abstract class AppwinAttributionPlatform extends PlatformInterface {
  /// Constructs a AppwinAttributionPlatform.
  AppwinAttributionPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinAttributionPlatform _instance = AppwinAttributionMethodChannel();

  /// The implementation in use, method channel by default.
  static AppwinAttributionPlatform get instance => _instance;

  static set instance(AppwinAttributionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Host OS and version. See `AppwinAttribution.getPlatformVersion`.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Whether this app may use Attribution. See `AppwinAttribution.initialize`.
  Future<AppwinInitResult> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Relays the advertising consent. See
  /// `AppwinAttribution.setAdvertisingConsent`.
  Future<void> setAdvertisingConsent(AppwinAdvertisingConsent consent) {
    throw UnimplementedError('setAdvertisingConsent() has not been implemented.');
  }

  /// ATT prompt (iOS). See `AppwinAttribution.requestTrackingAuthorization`.
  Future<bool> requestTrackingAuthorization() {
    throw UnimplementedError(
      'requestTrackingAuthorization() has not been implemented.',
    );
  }

  /// Ad-signals debug mode. See `AppwinAttribution.setAdSignalsDebugMode`.
  Future<void> setAdSignalsDebugMode(bool enabled) {
    throw UnimplementedError('setAdSignalsDebugMode() has not been implemented.');
  }
}
