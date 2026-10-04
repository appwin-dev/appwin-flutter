# Changelog

Part of the Appwin SDK for Flutter: the four packages release together and
share one version. History lives in the repository root CHANGELOG.

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
