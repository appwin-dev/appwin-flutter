## 0.5.1

- iOS via CocoaPods is fixed. The podspec asked for `AppwinCore ~> 0.1`, a range
  an old `Podfile.lock` already satisfied, so `pod install` never upgraded the
  native SDK and the build failed on a symbol the pinned Core did not have. It
  now pins `>= 0.5.1, < 1.0.0`. Native 0.5.1 also restores the CocoaPods build,
  which 0.5.0 broke outright. No Dart API change.

## 0.5.0

- **Fix.** Push taps are tracked on iOS. The plugin registers as an application
  delegate and re-asserts the notification delegate on launch and on every
  foreground: Firebase Messaging claims that delegate too, and whichever
  library registered last won, so a tap was attributed to nothing whenever
  Firebase came second.
- Native SDKs at 0.5.0.

## 0.4.1

- Documentation on the whole public API, up from 7%: what the product does,
  when to let the SDK present a message and when to render it yourself, and
  every field of the in-app message payload.

## 0.4.0

- `registerPushToken()` now forwards to `appwin_core`. Same signature, same
  call site: push tokens are shared with Support and Community, and two
  registrations would fight over the same device.

## 0.3.0

First release. The Notifications product was reachable from the native iOS and
Android SDKs and from React Native, but had no Flutter package: part of its
surface was folded into `appwin_support`, and `initialize()` had nowhere to
live.

* `initialize()`, `registerPushToken`, `trackEvent`, `fetchPendingMessages`,
  `track` and `syncOnAppOpen`.
* No UI: the app renders the in-app messages it is handed.
