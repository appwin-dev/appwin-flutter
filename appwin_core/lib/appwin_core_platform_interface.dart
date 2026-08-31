import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_core_method_channel.dart';

/// Contract each platform implements.
abstract class AppwinCorePlatform extends PlatformInterface {
  AppwinCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinCorePlatform _instance = AppwinCoreMethodChannel();

  static AppwinCorePlatform get instance => _instance;

  /// Platform-specific implementations register their own instance here.
  static set instance(AppwinCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> configure({
    required String appId,
    String? baseUrl,
    String? realtimeBaseUrl,
  }) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  Future<String> bootstrapSession({String? externalId}) {
    throw UnimplementedError('bootstrapSession() has not been implemented.');
  }

  Future<void> identify({required String externalId}) {
    throw UnimplementedError('identify() has not been implemented.');
  }

  Future<void> clearIdentity() {
    throw UnimplementedError('clearIdentity() has not been implemented.');
  }

  Future<void> signOut() {
    throw UnimplementedError('signOut() has not been implemented.');
  }

  Future<String?> deviceId() {
    throw UnimplementedError('deviceId() has not been implemented.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
}
