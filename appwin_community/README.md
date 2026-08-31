# appwin_community

`appwin_community` puts a **community feed inside your Flutter app**: posts,
comments, member profiles and moderation, all drawn natively. Your app provides
an entry point, a tab or a button, and the SDK draws the rest.

**Appwin** is an engagement platform for mobile app studios. It puts an in-app
support messenger, a community feed and push notifications inside your app, all
rendered natively, and gives your team one dashboard to run them.

- [appwin.io](https://appwin.io)
- [Documentation](https://appwin.io/docs)
- [Community product guide](https://appwin.io/docs/products/community)

## Features

- ✅ **Native feed** - SwiftUI on iOS, Compose on Android, embedded in your own layout
- ✅ **Posts, comments and reactions** without a single screen to build
- ✅ **Member profiles**, shared with the other Appwin products
- ✅ **Moderation** from the dashboard, and reporting on the member side
- ✅ **Unread badge** you can read and show in your own navigation
- ✅ **Configured from the dashboard** - colours, wording, enabled features, no app release
- ✅ **Comes with `appwin_core`**, so a single `configure` covers every product

## Installation

```bash
flutter pub add appwin_community
```

`appwin_core` comes with it and is re-exported, so you get the single
`configure` and the identity API under the same import.

### Requirements

| Platform | Minimum |
| --- | --- |
| iOS | 16.0 |
| Android | 7.0 (API 24) |

Nothing to add to your `Podfile` or to your Gradle repositories: the plugin
declares the native SDKs it needs, from CocoaPods and Maven Central.

On other platforms, `AppwinCommunityView` renders a neutral screen rather than
throwing, so a multi-platform app stays launchable.

## Getting started

**1. Configure the foundation at launch.** This step is required, and it is the
only one that is: every Appwin product reads the identity and the session it
sets up.

```dart
import 'package:appwin_community/appwin_community.dart';   // re-exports AppwinCore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

**2. Initialise Community and gate your own UI.** `configure` checks nothing;
`initialize()` asks the server whether Community may open for this app. The SDK
cannot remove your tab, it does not own your navigation.

```dart
final community = await AppwinCommunity.instance.initialize();
if (community.isReady) {
  setState(() => _tabs.add(communityTab));
}
```

It answers rather than throwing: not being entitled is a normal outcome. The
three products share one round trip and the verdict is cached, so being offline
falls back to the last known answer instead of closing a product you pay for.

**3. Show the feed** where you want it, usually a tab:

```dart
const AppwinCommunityView()
```

It takes the room your layout gives it and carries no close button, since there
is a tab to leave it. A modal presentation exists too, for apps without a
dedicated tab.

**4. Attach your own user** when someone signs in, so their posts and profile
follow them across devices:

```dart
await AppwinCore.instance.identify(externalId: user.id);
await AppwinCore.instance.bootstrapSession(externalId: user.id);
```

## Documentation

- [Community: in-app feed, comments and profiles](https://appwin.io/docs/products/community)
- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
