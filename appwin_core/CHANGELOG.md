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
