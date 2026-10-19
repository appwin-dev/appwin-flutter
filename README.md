# Appwin SDK for Flutter

Support, community, push notifications, analytics and attribution for Flutter
apps. These are wrappers: the screens are rendered by the native iOS and Android
SDKs, not reimplemented in Dart.

Requires Flutter 3.44 and the platform minimums (iOS 16, Android API 24).

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
| [`appwin_notifications`](https://appwin.io/docs/products/notifications) | Push token, events, in-app messages. |
| [`appwin_analytics`](https://appwin.io/docs/products/analytics) | Behavioural events, funnels and experiments. |
| [`appwin_attribution`](https://appwin.io/docs/products/attribution) | Acquisition signals: conversion values, advertising id and consent. |

Every package is published on pub.dev under the same name.

## Quickstart

Configure once at launch, then present or initialise the products you use:

```dart
import 'package:appwin_support/appwin_support.dart';

await AppwinCore.instance.configure(appId: 'your-app-id');
await AppwinSupport.presentMessenger();
```

The App ID comes from your Appwin dashboard; without a valid one the SDK stays
inert and makes no network call. Identity lives in Core
(`AppwinCore.instance.identify`); the products pick up the current user by
themselves. See the [Quickstart](https://appwin.io/docs/sdk/installation).

## iOS: SPM and CocoaPods

Each plugin ships both manifests. Flutter has defaulted to SPM since 3.44, and
CocoaPods still works for projects that have not migrated.

## Support

Bugs and questions: the issues of this repository. Anything tied to your
account, your billing or your data goes through the support widget in your
Appwin dashboard.

## Licence

Proprietary, see [LICENSE](./LICENSE). This source is public for auditability
and for debugging on the studio's side, not for reuse.
