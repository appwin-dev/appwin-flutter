import 'appwin_in_app_message.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_support_method_channel.dart';

abstract class AppwinSupportPlatform extends PlatformInterface {
  /// Constructs a AppwinSupportPlatform.
  AppwinSupportPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinSupportPlatform _instance = AppwinSupportMethodChannel();

  /// The default instance of [AppwinSupportPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppwinSupport].
  static AppwinSupportPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppwinSupportPlatform] when
  /// they register themselves.
  static set instance(AppwinSupportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Initialises the SDK. `baseUrl` is optional, an API URL override useful in
  /// development to point at localhost.
  Future<void> initialize({required String appId, String? baseUrl}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Presents the native Appwin messenger over the host app.
  Future<void> presentMessenger() {
    throw UnimplementedError('presentMessenger() has not been implemented.');
  }

  Future<void> loginUnidentifiedUser() {
    throw UnimplementedError('loginUnidentifiedUser() has not been implemented.');
  }

  Future<void> loginIdentifiedUser({ required String externalId}) {
    throw UnimplementedError('loginIdentifiedUser() has not been implemented.');
  }
  /// Updates the current customer's attributes, Intercom style. Does **not**
  /// affect the identity (externalId), which keeps the one set at the last
  /// login. Every field is optional.
  Future<void> updateUser({
    String? email,
    String? name,
    String? avatarUrl,
    String? language,
    String? timezone,
    String? location,
  }) {
    throw UnimplementedError('updateUser() has not been implemented.');
  }

  /// `platform` defaults to the device's: a hard-coded default would send FCM
  /// tokens labelled "ios".
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) {
    throw UnimplementedError('registerPushToken() has not been implemented.');
  }

  Future<List<AppwinInAppMessage>> fetchPendingInAppMessages() {
    throw UnimplementedError('fetchPendingInAppMessages() has not been implemented.');
  }

  Future<void> trackInAppDelivery({
    required String deliveryId,
    required String event,
  }) {
    throw UnimplementedError('trackInAppDelivery() has not been implemented.');
  }
}
