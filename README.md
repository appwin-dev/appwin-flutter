# Appwin SDK for Flutter

Support, community, push notifications, analytics and attribution for Flutter
apps. These are wrappers: the screens are rendered by the native iOS and Android
SDKs, not reimplemented in Dart.

Requires Dart 3.9 (Flutter 3.35 or later) and the platform minimums: iOS 16,
Android 7.0 (API 24). See [Platform setup](#platform-setup).

Full guide, per-product APIs and dashboard setup:
https://appwin.io/docs/sdk/installation

## Install

```bash
flutter pub add appwin_support
```

`appwin_core` comes with any product and is re-exported, the way `firebase_core`
does: you install a product, you get the foundation.

## Packages

| Package | Purpose |
| --- | --- |
| [`appwin_core`](https://appwin.io/docs/products/appwin-core) | The single `configure`, device identity, session. Comes with the others. |
| [`appwin_support`](https://appwin.io/docs/products/support) | Messenger, FAQ, conversations. |
| [`appwin_community`](https://appwin.io/docs/products/community) | Feed, comments, profiles. |
| [`appwin_notifications`](https://appwin.io/docs/products/notifications) | Push, campaigns and automations, in-app messages. |
| [`appwin_analytics`](https://appwin.io/docs/products/analytics) | Sessions, screens, events, crashes and session replay. |
| [`appwin_attribution`](https://appwin.io/docs/products/attribution) | Acquisition signals: conversion values, advertising id and consent. |

Every package is published on pub.dev under the same name.

## Quickstart

Configure once at launch, then present or initialise the products you use:

```dart
import 'package:appwin_support/appwin_support.dart';

await AppwinCore.instance.configure(appId: 'your-app-id');

final support = await AppwinSupport.instance.initialize();
if (support.isReady) {
  await AppwinSupport.instance.presentMessenger();
}
```

The App ID comes from your Appwin dashboard; without a valid one the SDK stays
inert and makes no network call. Identity lives in Core
(`AppwinCore.instance.identify`); the products pick up the current user by
themselves. See the [Quickstart](https://appwin.io/docs/sdk/installation).

## Platform setup

The plugins declare the native SDKs they need (CocoaPods or Swift Package
Manager on iOS, Maven Central on Android): no extra repository to add. Your app
only has to meet the minimums.

**iOS 16.** In Xcode, set the Runner target's deployment target to 16.0. If
your project uses CocoaPods, set the platform at the top of `ios/Podfile`, then
run `pod install`:

```ruby
platform :ios, '16.0'
```

Each plugin ships both a podspec and a `Package.swift`, so it works whether your
project uses CocoaPods or Swift Package Manager.

**Android API 24.** If your app targets a lower `minSdk`, raise it in
`android/app/build.gradle(.kts)`:

```kotlin
android {
    defaultConfig {
        minSdk = 24
    }
}
```

## Support

Bugs and questions: the issues of this repository. Anything tied to your
account, your billing or your data goes through the support widget in your
Appwin dashboard.

## Licence

Proprietary, see [LICENSE](./LICENSE). This source is public for auditability
and for debugging on the studio's side, not for reuse.
