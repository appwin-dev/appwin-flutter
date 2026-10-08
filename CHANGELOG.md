# Changelog - Appwin SDK for Flutter

Versions follow [semantic versioning](https://semver.org).

Each Appwin artefact versions independently: a fix here does not move the iOS,
Android or React Native SDK. All four numbers live in one place, `version.json`
in the monorepo, and the release script derives every manifest and every
cross-artefact pin from it.

The three packages (`appwin_core`, `appwin_support`, `appwin_community`) are
released together and share **this** version. They pin the native iOS SDK at the
version they were tested against, which moves on its own schedule.

## 0.12.0

**Native SDKs iOS 0.12.0 and Android 0.12.0.** Community moderation in the app, emoji reactions, sanctions; custom user attributes.

- Community, in-app moderation: moderators and admins get a flag with the
  pending count and a Moderation screen to restore, confirm, keep or hide
  reported content. From any post, comment or profile they can hide or delete
  with a reason, move a post to another group, pin it (end date and/or views
  per member), warn, shadow-ban or ban a member.
- Community, members: a new report sheet; a bell lists the sanctions they
  received (removed post or comment, warning, ban) until they tap "Got it";
  a post or comment removed by moderation as it is published shows an alert
  instead of disappearing.
- Community, reactions: 11 emojis on a long press of a post's heart or a
  comment, when the studio enables emoji reactions; the post comes forward and
  the rest of the screen dims. Heart-only communities keep the single heart.
- Community, design: admin badge on avatars, redesigned profile editing and
  anonymous banner in the composer, « ⋯ » menus that open on the dots. The
  studio's permissions for images, videos, polls and comments are applied.
- Core: `customAttributes` on the user attributes (snake_case keys, up to 50,
  values up to 200 characters, `null` removes one), usable for push audiences.
- Notifications, iOS: push taps are tracked when FlutterFire owns the
  notification delegate, and a push received in the foreground shows the
  in-app banner.
- No breaking change in the Dart API: update and rebuild.

## 0.11.2

**Native SDKs iOS 0.11.1 and Android 0.11.2.** Session replay no longer makes
the app stutter.

- iOS: Flutter renders the replay frames itself, on the engine's threads. The
  main thread is no longer held while the engine renders the screen a second
  time (about 150 ms every second on an iPhone 15). Same quality, two pixels
  per point, and the masks come from the same frame. Scrolls and animations
  are recorded.
- Android: a Flutter screen is recorded while it scrolls or animates: its
  capture costs the app's threads under 1 ms.
- A screen showing a native view (a platform view, a native screen over
  Flutter) keeps the native capture, which now waits for the screen to be
  still: no capture while a finger is down or a scroll or an animation runs,
  and at least one frame every 10 s.
- No API change: update and rebuild.

## 0.11.1

**Android SDK 0.11.1.** Session replay on Android recorded black frames in
release builds: R8 renamed Flutter's surface view, so it was never captured.
The Android SDK now keeps that class name in minified apps. Rebuild your
release to get it; nothing to change in your code.

## 0.11.0

**Native SDKs 0.11.0.** Session replay in Analytics (ADR-0057):

- The screen is recorded as a video (H.264, one frame per second, segments of
  10 s) and masked on the device before encoding: nothing masked ever leaves
  the phone. Off by default: switch it on per app on the Session replay page.
- Text fields are always masked, web views too unless you unmask them. Other
  text and images follow the project settings, shown by default.
- `AppwinMask` and `AppwinUnmask` widgets to mask or show a part of the screen.
- `AppwinNavigatorObserver`: add it to `navigatorObservers` and named routes
  become screens, on the analytics funnels and the replay timeline.
- `initialize(sessionReplay: false)` never records this app, whatever the
  dashboard says.
- Android: recording now works in a Flutter app from the first screen (it
  waited for the next resume), and Flutter's surface is captured (it came out
  black).

## 0.10.0

**Native SDKs 0.10.0.** Crash reporting in Analytics (ADR-0056):

- `AppwinAnalytics.instance.initialize()` gains `crashReporting` (default
  `true`) and `inAppPackages`. Uncaught Dart errors are reported as non-fatal,
  previous handlers (Crashlytics, Sentry) still run.
- `AppwinAnalytics.instance.recordError(error, [stack, fatal])` for errors your
  code catches.
- Native crashes and ANRs are captured by the native SDKs.

Also from the native SDKs: Community reactions and in-app banner, no more gap
under the Community button when embedded in a Flutter screen, and
`registerPushToken` no longer fails on a transient 5xx/429.

## 0.9.2

**Native SDKs 0.9.2.** Support and Community screens aligned on the InApp
mockups: customizable gradient, `colorScheme` and `grayWarmth` from the
dashboard, Help Center title and welcome message, "My inbox" hidden until a
conversation exists. No API change on this side.

## 0.9.1

**Native SDKs 0.9.1.** `registerPushToken` now waits for the session before
posting and retries once with a fresh session when the bearer was rotated
meanwhile by a concurrent `identify`: the 401 a token registered right after
`configure` could get is gone. No API change on this side.

## 0.9.0

**Community: events, live counts and your own UI.** `AppwinCommunity` gains
`events` (the current member's own actions, for gamification),
`unreadNotificationCountStream`, `onNotificationTap` / `openPost`,
`onEditProfile` and a live `lastResult`. `AppwinCommunityView(unavailableBuilder:)`
takes your UI while Community is not ready; without it a "coming soon"
placeholder replaces the empty view, with a diagnosis card in debug builds.

**Debug builds unlock Community without the plan.** Release builds still need
it.

**Core.** `availabilityUpdates(AppwinProduct)` streams a product's verdict and
every change; `AppwinInitResult` compares by value.

**Fixed: Swift Package Manager resolution of `appwin_analytics` and
`appwin_attribution`.** Both declared the `appwin-support` product. CocoaPods
was not affected.

Details in each package's changelog.

## 0.8.0

**Breaking: user identity now lives in Core, once.** `AppwinCore.identify`
opens the server session with the id and persists it across launches,
`AppwinCore.updateUser` sets the user attributes (email, name, avatarUrl,
language, timezone, location, plan), `AppwinCore.logout` revokes the session
and starts a fresh anonymous one. Products no longer have identity functions:
they read the session Core holds, and refresh when it changes.

| 0.7 | 0.8 |
|---|---|
| `AppwinCore.instance.identify(externalId: ...)` | `AppwinCore.instance.identify(externalId, attributes: ...)` |
| `AppwinSupport.instance.loginIdentifiedUser(...)` | `AppwinCore.instance.identify(...)` |
| `AppwinSupport.instance.updateUser(...)` | `AppwinCore.instance.updateUser(AppwinUserAttributes(...))` |
| `AppwinSupport.instance.loginUnidentifiedUser()` | nothing: Core opens the anonymous session itself |
| `AppwinCommunity.instance.login(...)` | `AppwinCore.instance.identify(...)` |
| `signOut()`, `clearIdentity()`, `AppwinCommunity.instance.logout()` | `AppwinCore.instance.logout()` |
| `bootstrapSession()` | nothing: internal now |
| `AppwinNotifications.instance.registerPushToken(...)` | `AppwinCore.instance.registerPushToken(...)` |

`AppwinSupportUserAttributes` becomes `AppwinUserAttributes`, in Core.

**Fixed: identifying through Support did not identify.** The id never reached
the server once a session existed, so the visitor stayed an anonymous lead.
Internal session renewals (availability, analytics re-auth) also dropped the
id, and a concurrent `identify` could be handed the anonymous session being
opened. The id is now persisted and reused by every renewal.

**Fixed: a logout kept the device attached to the user.** The next anonymous
session landed on the person who had just signed out (server-side fix, no
action needed).

**`identify` and `updateUser` now throw.** Unlike the rest of the facade,
they surface failures (`ArgumentError` on a blank id, `PlatformException`
otherwise): a sign-in that fails silently leaves the app believing its user
is identified. `logout` never throws.

**Push routing reaches Flutter.** A tap on an Appwin push opens the right
screen - a Support reply its conversation - whether the app was in the
foreground, in the background or cold-started by the tap, and whoever owns the
push stack.

- `appwin_core`: `AppwinPush` (`isAppwinPush`, `handleTap`, `handleForeground`,
  `handleMessage`) for apps on FlutterFire, which forward its callbacks. Android
  no longer loses the tap that launched the app.
- `appwin_notifications`: `start(installsNotificationDelegate:)` to leave the
  iOS notification delegate to the host.
- `appwin_support`: `presentConversation(conversationId)`.

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
