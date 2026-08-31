# appwin_core

The foundation of the Appwin SDKs for Flutter: device identity, authenticated
session, network client. The products - `appwin_support`, `appwin_community` -
depend on it and are only consumers of it.

## Why this package exists

**One `configure`, whatever the number of products you integrate.**

Without it, an app wiring both Support and Community passes its App ID twice, to
two different `initialize` calls, while the native side has only one device
identity and one session. The model is Firebase's: you configure the
foundation, then the products just work.

It also opens the identity API that the product facades do not expose:
`identify`, `clearIdentity`, `signOut`, `bootstrapSession`, `deviceId`.

## Install

```bash
flutter pub add appwin_community   # or appwin_support, depending on the product
```

No `pub add appwin_core`: every product plugin depends on it and re-exports it,
so `AppwinCore` arrives with the product, under the same import. You install
this package directly only for an app that wants identity with no product at
all, a case that does not exist yet.

iOS 16 minimum, Android 7.0 (API 24) minimum.

## Usage

```dart
import 'package:appwin_community/appwin_community.dart';   // re-exports AppwinCore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

When a user signs in to your app:

```dart
await AppwinCore.instance.identify(externalId: user.id);
await AppwinCore.instance.bootstrapSession(externalId: user.id);
```

Both calls, not one: `identify` records the identity locally,
`bootstrapSession` mints a token that carries it. Without the second, the calls
that follow stay on the anonymous session until the next launch.

On sign-out:

```dart
await AppwinCore.instance.signOut();
```

## Local development

`baseUrl` points the SDK at your API:

| Target | `baseUrl` |
| --- | --- |
| iOS simulator | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| Physical device | `http://192.168.1.X:3000` |
| Production | omitted |

The native binaries come from their registries: Maven Central on Android
(`io.appwin:appwin-*`), and the `appwin-ios` Swift package on iOS. Nothing to
add to your app's repositories.
