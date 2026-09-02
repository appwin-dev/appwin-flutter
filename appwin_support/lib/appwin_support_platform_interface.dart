/// Platform contract behind `AppwinSupport`.
///
/// Split out so the Dart API and the native implementation can move apart:
/// tests swap in a fake, and a future platform registers its own without
/// touching the calling code.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_support_method_channel.dart';

/// Contract each platform implements.
///
/// Host apps go through `AppwinSupport.instance` instead. It is public so a
/// platform package, or a test, can provide its own [instance].
abstract class AppwinSupportPlatform extends PlatformInterface {
  /// Constructs a AppwinSupportPlatform.
  AppwinSupportPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinSupportPlatform _instance = AppwinSupportMethodChannel();

  /// The default instance of [AppwinSupportPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppwinSupport].
  /// The implementation in use, method channel by default.
  static AppwinSupportPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppwinSupportPlatform] when
  /// they register themselves.
  static set instance(AppwinSupportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Host OS and version, for checking the bridge is alive. See
  /// `AppwinSupport.getPlatformVersion`.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Initialises the SDK. `baseUrl` is optional, an API URL override useful in
  /// development to point at localhost.
  /// Whether this app may use Support. See `AppwinSupport.initialize`.
  Future<AppwinInitResult> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Presents the native Appwin messenger over the host app.
  /// Presents the messenger. See `AppwinSupport.presentMessenger`.
  Future<void> presentMessenger() {
    throw UnimplementedError('presentMessenger() has not been implemented.');
  }

  /// Opens a session for an unnamed visitor. See
  /// `AppwinSupport.loginUnidentifiedUser`.
  Future<void> loginUnidentifiedUser() {
    throw UnimplementedError(
      'loginUnidentifiedUser() has not been implemented.',
    );
  }

  /// Attaches the customer to one of your users. See
  /// `AppwinSupport.loginIdentifiedUser`.
  Future<void> loginIdentifiedUser({required String externalId}) {
    throw UnimplementedError('loginIdentifiedUser() has not been implemented.');
  }

  /// Updates the current customer's attributes, Intercom style. Does **not**
  /// affect the identity (externalId), which keeps the one set at the last
  /// login. Every field is optional.
  /// Enriches the customer record. See `AppwinSupport.updateUser`.
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
}
