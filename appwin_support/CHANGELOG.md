## 0.2.0

**Breaking.** `initialize()` no longer takes an `appId` and no longer
configures the foundation. Call `AppwinCore.instance.configure()` first, then
`initialize()`, which answers whether this product may open for your app.

## 0.1.1

* Package page rewritten for pub.dev: what Appwin is, what this package does,
  installation, a minimal start, and links to the guide for the rest.
* Real licence file instead of the Flutter template placeholder.

## 0.1.0

* First published release.

## 0.0.2

* Android: messenger, identity, push token and in-app messages now go through
  the native Kotlin SDKs.
* `registerPushToken` derives the platform from the device instead of
  defaulting to `ios`.
* iOS: the push token, in-app messages and delivery tracking go through
  `AppwinSupport` and `AppwinNotifications` instead of being re-issued as HTTP
  calls in the glue. Same endpoints as before, one fewer copy to drift.
* iOS: those calls no longer replay `bootstrapSession` every time. The bootstrap
  rotates the session token on the server, so repeating it before every push
  token registration invalidated the session in progress.
* Depends on `appwin_core` and re-exports it: `AppwinCore.instance.configure`
  comes with this package, one App ID for every product.

## 0.0.1

* Initial version.
