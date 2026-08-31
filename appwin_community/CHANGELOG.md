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
