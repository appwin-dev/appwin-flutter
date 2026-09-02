# Changelog - Appwin SDK for Flutter

Versions follow [semantic versioning](https://semver.org).

Each Appwin artefact versions independently: a fix here does not move the iOS,
Android or React Native SDK. All four numbers live in one place, `version.json`
in the monorepo, and the release script derives every manifest and every
cross-artefact pin from it.

The three packages (`appwin_core`, `appwin_support`, `appwin_community`) are
released together and share **this** version. They pin the native iOS SDK at the
version they were tested against, which moves on its own schedule.

## 0.4.0

**Breaking.** `registerPushToken` moved from Support to the foundation: it is
now `AppwinCore.instance.registerPushToken(...)`. The token is shared by Support, Community and Notifications, so it
belongs to the socle rather than to one product; it still posts to the Support
route, so registering it needs no Notifications entitlement. A product whose
`initialize()` runs without a registered token logs a warning - recommended for
Support and Community, required for Notifications - rather than refusing to
start.

`initialize()` answered `AppwinInitStatus.unknown` on a first launch of an app
that was online, and the messenger stayed closed until the next one. The cause
was native, in both foundations: `configure` returns before the bearer exists,
`/sdk/v1/availability` is bearer-only, and the call went out without a token.

This release pins the iOS and Android SDKs at 0.2.1, which await the session
before asking. No Dart API changed.

## 0.2.0

**Breaking.** `AppwinSupport.instance.initialize({appId})` and its Community
equivalent no longer configure the foundation. They take no argument and answer
whether the product may open:

```dart
await AppwinCore.instance.configure(appId: 'your-app-id');
final support = await AppwinSupport.instance.initialize();
if (support.isReady) { ... }
```

Call `AppwinCore.instance.configure()` first, as the guide already showed.

## 0.1.0

First release.
