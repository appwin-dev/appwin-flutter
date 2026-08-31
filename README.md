# Appwin SDK for Flutter

Support messenger, community feed, push notifications and in-app messages for
Flutter apps. These are wrappers: the screens are rendered by the native iOS and
Android SDKs, not reimplemented in Dart.

| Package | pub.dev | What it gives you |
| --- | --- | --- |
| [`appwin_core`](./appwin_core) | `appwin_core` | The single `configure`, device identity, session. |
| [`appwin_support`](./appwin_support) | `appwin_support` | Messenger, FAQ, conversations, push token, in-app messages. |
| [`appwin_community`](./appwin_community) | `appwin_community` | Feed, comments, profiles. |

## Install

```bash
flutter pub add appwin_support
```

`appwin_core` comes with it and is re-exported, the way `firebase_core` does.
You install a product, you get the foundation.

## Use

Configure once, whatever the number of products:

```dart
import 'package:appwin_support/appwin_support.dart';

await AppwinCore.instance.configure(appId: 'your-app-id');
await AppwinSupport.presentMessenger();
```

The App ID comes from your Appwin dashboard. Without a valid one the SDK stays
inert: it makes no network call.

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
