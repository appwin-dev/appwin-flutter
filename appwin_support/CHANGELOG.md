## 0.3.0

* **Breaking.** `fetchPendingInAppMessages()` and `trackInAppDelivery()` are
  gone: in-app campaigns are the Notifications product, and they now live in
  `appwin_notifications` as `fetchPendingMessages()` / `syncOnAppOpen()` and
  `track()`.
* `registerPushToken()` **stays here on purpose**. It posts to the Support
  route, which works without the Notifications product enabled, so a
  Support-only studio keeps receiving conversation pushes.
* New sibling package `appwin_notifications`: push tokens, automation events
  and in-app messages. The product existed natively and in React Native but
  had no Flutter package.

## 0.2.1

* Real example app: configure, initialise, then render from the answer. It was
  still the Flutter template, which called neither.
* Package page: simpler snippets that print the result instead of wiring state,
  and a clearer note on installing `appwin_core` (you do not).

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
