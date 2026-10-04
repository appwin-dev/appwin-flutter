## 0.10.0

Native SDKs 0.10.0: crash reporting in Analytics, Community reactions and
in-app banner, `registerPushToken` no longer fails on a transient 5xx/429.
No API change on this side.

## 0.9.2

**Native SDKs 0.9.2.** Support and Community screens aligned on the InApp
mockups: customizable gradient, `colorScheme` and `grayWarmth` from the
dashboard, Help Center title and welcome message, "My inbox" hidden until a
conversation exists. No API change on this side.

## 0.9.1

Native SDKs 0.9.1: `registerPushToken` waits for the session before posting
and retries once with a fresh session after a 401 caused by a concurrent
`identify`. No API change on the Dart side.

## 0.9.0

- `availabilityUpdates(AppwinProduct)`: a product's verdict, then every change
  (a dashboard toggle, a plan that lapses), revalidated when the app returns to
  the foreground. New `AppwinProduct` enum.
- `AppwinInitResult` now compares by value.
- Debug builds of the host app unlock Community without the plan (a native
  SDK change, nothing to call); release builds still need it.

## 0.8.0

- **Breaking:** `identify(externalId, {attributes})`, `updateUser(AppwinUserAttributes)` and `logout()` are the only identity API; `bootstrapSession`, `clearIdentity` and `signOut` are removed. `identify` and `updateUser` throw on failure; `logout` never throws.
- **Fixed:** the external id is persisted across launches and kept by every session renewal.

- `AppwinPush`: `isAppwinPush`, `handleTap`, `handleForeground` and
  `handleMessage`, for an app that owns its push stack (FlutterFire). Wire them
  to `getInitialMessage`, `onMessageOpenedApp`, `onMessage` and the background
  handler, and an Appwin push opens what it points to, a Support reply its
  conversation. Parsing and routing stay native.
- **Fix.** Android: the push tap that cold-starts the app is no longer lost.
  The native SDK reads the launch intent from `configure()` onward, which in
  Flutter runs after the activity resumed; the plugin now hands it over right
  after `configure()`, and every later tap through `onNewIntent`.

## 0.5.1

- iOS via CocoaPods is fixed. The podspec asked for `AppwinCore ~> 0.1`, a range
  an old `Podfile.lock` already satisfied, so `pod install` never upgraded the
  native SDK and the build failed on a symbol the pinned Core did not have. It
  now pins `>= 0.5.1, < 1.0.0`. Native 0.5.1 also restores the CocoaPods build,
  which 0.5.0 broke outright. No Dart API change.

## 0.5.0

- Native SDKs at 0.5.0: analytics with a persisted offline queue, install
  attribution, in-app banners. No change to the Dart API.

## 0.4.1

- Documentation on the whole public API, up from 43%: what Appwin is, what the
  foundation holds versus the products, and every symbol on the platform
  interface and the method channel.
- Real example app. `appwin_core` had none, so its page carried no runnable
  integration: configure, identify plus bootstrap, sign out.

## 0.4.0

- `registerPushToken()` and `hasRegisteredPushToken()` on the foundation.
  Strongly recommended with Support and Community; required with Notifications.
- Products log a debug warning on `initialize()` when the token is still missing.

## 0.3.0

* New sibling package `appwin_notifications`: push tokens, automation events
  and in-app messages. The product existed natively and in React Native but
  had no Flutter package.

## 0.2.1

* Real example app: configure, initialise, then render from the answer. It was
  still the Flutter template, which called neither.
* Package page: simpler snippets that print the result instead of wiring state,
  and a clearer note on installing `appwin_core` (you do not).

## 0.2.0

Exposes `AppwinInitResult`, the answer returned by each product's
`initialize()`. `configure()` itself is unchanged.

## 0.1.1

* Package page rewritten for pub.dev: what Appwin is, what this package does,
  installation, a minimal start, and links to the guide for the rest.
* Real licence file instead of the Flutter template placeholder.

## 0.1.0

* First published release. Bridges the native iOS and Android SDKs.

## 0.0.1

* Initial version: a single `configure` for every product, session
  (`bootstrapSession`), identity (`identify`, `clearIdentity`, `signOut`),
  `deviceId`. iOS and Android.
