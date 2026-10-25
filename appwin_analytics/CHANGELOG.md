# Changelog

Part of the Appwin SDK for Flutter: the six packages release together and
share one version. History lives in the repository root CHANGELOG.

## 1.0.0

Native SDKs iOS 1.0.0 and Android 1.0.0. The public API is stable from now on and follows semantic versioning: no breaking change before 2.0.0; the symbols deprecated during 0.x keep working through 1.x. Builds with Xcode 26.0 (Swift 6.2).

## 0.16.0

Native SDKs iOS 0.16.0 and Android 0.16.0. `AppwinAnalytics.track` and `setConsent` are deprecated in favour of `AppwinCore.instance.track` / `setConsent`; `AppwinAnalyticsConsent` is a deprecated `typedef` of `AppwinConsentState`. They end in the same native batches. Calling both `AppwinCore.instance.track` and the old method for the same event counts it twice: remove the old call. A journey triggered on `session_start` now starts when the customer comes back after 30 minutes away, not on every process launch. Refusing through `AppwinCore.instance.setConsent` also purges recorded replay.

## 0.15.0

Native SDKs iOS 0.15.0 and Android 0.15.0 (in-app moderation, see `appwin_community`). No API change on this side.

## 0.14.2

Native SDKs iOS 0.14.2 and Android 0.14.2 (community unread badge fix). No API change on this side.

## 0.14.1

Native SDKs iOS 0.14.1 and Android 0.14.1 (community UI polish). No API change on this side.

## 0.14.0

Native SDKs iOS 0.14.0 and Android 0.14.0 (profile editing on the community view, see `appwin_community`). No API change on this side.

## 0.13.0

Native SDKs iOS 0.13.0 and Android 0.13.0 (community fonts, see `appwin_community`). No API change on this side.

## 0.12.0

Native SDKs iOS 0.12.0 and Android 0.12.0 (community moderation, see `appwin_community`). No API change on this side.

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

- Android: session replay no longer records black frames in release builds.
  R8 renamed Flutter's surface view, which was then never captured; the
  Android SDK (0.11.1) now keeps its name. Rebuild your release, no code change.

## 0.11.0

Session replay (ADR-0057), off by default and switched on per app on the
Session replay page:

- The screen is recorded as a video, masked on the device before encoding.
  Text fields are always masked, web views too unless unmasked; other text
  and images follow the project settings, shown by default.
- `AppwinMask(child: ...)` hides a part of the screen whatever the settings,
  `AppwinUnmask(child: ...)` shows it (text fields stay masked).
- `AppwinNavigatorObserver()`: add it to `navigatorObservers` and named page
  routes are reported as screens. Dialogs and sheets are ignored.
- `initialize(sessionReplay: false)` never records this app.
- Android: recording starts from the first screen, and the Flutter surface is
  captured instead of a black frame.

## 0.10.0

**Native SDKs 0.10.0.** Crash reporting (ADR-0056).

- `initialize()` gains `crashReporting` (default `true`) and `inAppPackages`.
- Uncaught Dart errors (`FlutterError.onError`, `PlatformDispatcher.onError`)
  are reported as non-fatal with runtime `flutter`; previous handlers still run.
- New `recordError(error, [stack, fatal])` for errors your code catches.
- Native crashes and ANRs are captured by the native SDKs, nothing to call.

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

- Fixed: Swift Package Manager resolution. The plugin's `Package.swift` declared
  the product `appwin-support` and depended on `AppwinSupport`; it now declares
  `appwin-analytics` and depends on `AppwinCore` only. CocoaPods was not affected.

## 0.8.0

- Released with the rest of the Appwin SDK for Flutter 0.8.0. No change in this package; identity moved to `appwin_core` (see its changelog).
