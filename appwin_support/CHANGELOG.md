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
