## 0.1.0

* First published release.

## 0.0.2

* Android: the feed, the full-screen presentation and identity go through the
  native Kotlin SDK. `AppwinCommunityView` is rendered there in hybrid
  composition.
* Depends on `appwin_core` and re-exports it: `AppwinCore.instance.configure`
  comes with this package, one App ID for every product.
* `login` replays the session bootstrap on both platforms, so the calls that
  follow carry the new identity rather than only doing so on iOS.

## 0.0.1

* Initial version: embeddable native iOS community feed
  (`AppwinCommunityView`), full-screen presentation, identity (`login`,
  `setUser`), notification badge.
