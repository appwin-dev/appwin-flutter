# appwin_support

`appwin_support` puts **customer support inside your Flutter app**: a native
messenger your users open without creating an account, a help centre that
absorbs the repetitive questions, and a shared inbox on your side to answer
them.

**Appwin** is an engagement platform for mobile app studios. It puts an in-app
support messenger, a community feed and push notifications inside your app, all
rendered natively, and gives your team one dashboard to run them.

- [appwin.io](https://appwin.io)
- [Documentation](https://appwin.io/docs)
- [Support product guide](https://appwin.io/docs/products/support)

## Features

- ✅ **In-app messenger**, drawn natively - SwiftUI on iOS, Compose on Android
- ✅ **No sign-up required** - a user writes to you straight away, recognised by device
- ✅ **Help centre / FAQ** inside the app, written from the dashboard
- ✅ **Shared inbox** for your team: triage, tags, assignment, replies
- ✅ **Unread badge** you can read and show in your own navigation
- ✅ **Configured from the dashboard** - colours, wording, enabled features, no app release
- ✅ **Comes with `appwin_core`**, so a single `configure` covers every product

## Installation

```bash
flutter pub add appwin_support
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

## Getting started

**1. Configure the foundation at launch.** This step is required, and it is the
only one that is: every Appwin product reads the identity and the session it
sets up.

```dart
import 'package:appwin_support/appwin_support.dart';   // re-exports AppwinCore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

**2. Open the messenger** from wherever your app offers help:

```dart
await AppwinSupport.instance.presentMessenger();
```

Your app builds no screen. It triggers, the native side draws.

**3. Attach your own user** when someone signs in, so their conversations
follow them across devices:

```dart
await AppwinCore.instance.identify(externalId: user.id);
await AppwinCore.instance.bootstrapSession(externalId: user.id);
```

## Documentation

- [Support: in-app messenger, inbox and FAQ](https://appwin.io/docs/products/support)
- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
