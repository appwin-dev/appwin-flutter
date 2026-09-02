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
