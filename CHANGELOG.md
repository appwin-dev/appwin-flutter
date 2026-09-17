# Changelog - Appwin SDK for Flutter

Versions follow [semantic versioning](https://semver.org).

Each Appwin artefact versions independently: a fix here does not move the iOS,
Android or React Native SDK. All four numbers live in one place, `version.json`
in the monorepo, and the release script derives every manifest and every
cross-artefact pin from it.

The three packages (`appwin_core`, `appwin_support`, `appwin_community`) are
released together and share **this** version. They pin the native iOS SDK at the
version they were tested against, which moves on its own schedule.

## 0.6.0

**Analytics and Attribution reach Flutter.** Two new packages complete the
product line:

- `appwin_analytics` - `initialize`, `track` (with the `{value, currency}`
  purchase convention), `screen`, `flush`, `setConsent`.
- `appwin_attribution` - `initialize`, `setAdvertisingConsent`,
  `requestTrackingAuthorization` (ATT on iOS, resolves `true` on Android),
  `setAdSignalsDebugMode` (TikTok test events).

Both are thin bridges over the native 0.6.x SDKs, share `appwin_core`'s
single `configure()`, and follow the same availability contract as the other
packages (server verdict, disk-cached, offline-safe).

## 0.5.3

**Native SDKs 0.6.2 under the hood.** Same content as 0.5.2 - which never
reached pub.dev (the publish workflow hung on authentication) - plus natives
that report their real version to the dashboard. No Dart API change.

## 0.5.2

**Native SDKs 0.6.1 under the hood.** The pinned iOS and Android cores gain a
one-hour revalidation TTL on the availability verdict: release builds skip the
network round trip at most launches, debug builds still revalidate every time
so the toggle-relaunch-ready loop stays instant. No Dart API change.

## 0.5.1

**iOS builds through CocoaPods again.** Two things broke it, and both are
fixed here.

The plugins' podspecs asked for `AppwinCore ~> 0.1`, unchanged since 0.1.0.
That range accepts anything below 1.0.0, so an existing `Podfile.lock` already
satisfied it and `pod install` never upgraded the native SDK: apps compiled
0.5.0 Dart glue against a native Core still at 0.2.0 and failed with
`Type 'AppwinCore' has no member 'registerPushToken'`, an error naming the glue
file rather than the version skew. The podspecs now pin
`>= <native version>, < 1.0.0`, the exact CocoaPods spelling of the `from:` in
`Package.swift`, and the release script stamps them from `version.json` like
every other cross-artefact pin.

The native pods themselves were also missing from CocoaPods trunk for 0.3.0,
0.4.0 and 0.5.0, and native 0.5.0 could not compile under CocoaPods at all.
Both are fixed in iOS 0.5.1, which this release pins.

No Dart API change.

## 0.5.0

`updateUser` takes a `plan`, so a studio can segment its customers by
subscription tier without stuffing it into another field.

**Push taps are tracked on iOS.** The plugin now registers itself as an
application delegate and re-asserts the notification delegate on launch and on
every foreground. Firebase Messaging claims that delegate for itself, and
whichever library registered last won: a tap on an Appwin push was attributed
to nothing at all whenever Firebase came second. Re-asserting on both hooks
makes the order irrelevant.

`loginUnidentifiedUser` no longer invents a display name for the anonymous
visitor it creates on Android. It sent `Visitor anonyme <deviceId>` - a French
literal, and a name that then showed in the dashboard as though the customer
had chosen it. The record is created from the device session, with no name.

This release also carries the native SDKs at 0.5.0: analytics, install
attribution and in-app banners. See their changelogs.

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
