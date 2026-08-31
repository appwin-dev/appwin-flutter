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

That is the only package to install. `appwin_core` comes with it as a
dependency and is re-exported, so `AppwinCore` is available under the same
import - **do not add it yourself**, or you take on a second version
constraint to keep aligned with this one.

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

**2. Initialise Support and gate your own UI.** `configure` checks nothing;
`initialize()` asks the server whether Support may open for this app. The SDK
cannot hide your help button, it does not own your navigation.

```dart
final support = await AppwinSupport.instance.initialize();
debugPrint('Appwin Support: $support');   // ready / unavailable(plan) / ...

if (support.isReady) {
  // Show your help button, your menu entry, whatever opens support.
}
```

It answers rather than throwing: not being entitled is a normal outcome. The
three products share one round trip and the verdict is cached, so being offline
falls back to the last known answer instead of closing a product you pay for.

**3. Open the messenger** from wherever your app offers help:

```dart
await AppwinSupport.instance.presentMessenger();
```

Your app builds no screen. It triggers, the native side draws.

**4. Attach your own user** when someone signs in, so their conversations
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
