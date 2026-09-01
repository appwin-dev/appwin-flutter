import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_in_app_message.dart';
import 'appwin_notifications_method_channel.dart';

abstract class AppwinNotificationsPlatform extends PlatformInterface {
  AppwinNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinNotificationsPlatform _instance =
      AppwinNotificationsMethodChannel();

  static AppwinNotificationsPlatform get instance => _instance;

  static set instance(AppwinNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<AppwinInitResult> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> start({bool requestPushPermission = true}) {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> registerPushToken({
    required String token,
    bool pushOptIn = true,
  }) {
    throw UnimplementedError('registerPushToken() has not been implemented.');
  }

  Future<void> trackEvent({
    required AppwinAutomationEvent event,
    String? eventName,
    Map<String, String>? properties,
  }) {
    throw UnimplementedError('trackEvent() has not been implemented.');
  }

  Future<List<AppwinInAppMessage>> fetchPendingMessages() {
    throw UnimplementedError('fetchPendingMessages() has not been implemented.');
  }

  Future<void> track({
    required String deliveryId,
    required AppwinTrackEvent event,
    int? buttonIndex,
  }) {
    throw UnimplementedError('track() has not been implemented.');
  }

  Future<List<AppwinInAppMessage>> syncOnAppOpen() {
    throw UnimplementedError('syncOnAppOpen() has not been implemented.');
  }

  Future<void> presentPendingMessages() {
    throw UnimplementedError('presentPendingMessages() has not been implemented.');
  }
}
