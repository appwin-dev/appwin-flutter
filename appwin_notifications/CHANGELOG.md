## 0.3.0

First release. The Notifications product was reachable from the native iOS and
Android SDKs and from React Native, but had no Flutter package: part of its
surface was folded into `appwin_support`, and `initialize()` had nowhere to
live.

* `initialize()`, `registerPushToken`, `trackEvent`, `fetchPendingMessages`,
  `track` and `syncOnAppOpen`.
* No UI: the app renders the in-app messages it is handed.
