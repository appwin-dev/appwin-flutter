/// The Appwin products a verdict can be asked about.
library;

/// An Appwin product, as the server names it in its availability verdict.
///
/// Mirrors `AppwinProduct` in the iOS and Android SDKs.
enum AppwinProduct {
  /// Messenger, conversations and FAQ (`appwin_support`).
  support,

  /// In-app feed, comments and member profiles (`appwin_community`).
  community,

  /// Push registration and in-app messages (`appwin_notifications`).
  notifications,

  /// Product analytics (`appwin_analytics`).
  analytics,

  /// Install attribution (`appwin_attribution`).
  attribution;

  /// The key the native SDKs and the server use for this product.
  String get key => name;

  /// The product for [key], or `null` for one this package does not know:
  /// a native SDK newer than this package may report products it has never
  /// heard of.
  static AppwinProduct? fromKey(Object? key) {
    for (final product in values) {
      if (product.key == key) return product;
    }
    return null;
  }
}
