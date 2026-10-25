# appwin_core_example

Minimal integration of `appwin_core`, the foundation the Appwin SDKs share.

Core is not a product: it holds the device identity, the session and the
network client that every Appwin product reuses. So this
example has no messenger and no feed to open. It shows the three calls a host
app actually makes:

- `configure()` once at startup, before any product;
- `identify()` when your user signs in;
- `logout()` when they sign out of your app.

## Run it

Put your App ID in `lib/main.dart` first, from the dashboard under
Settings then SDK:

```dart
const appId = 'your-app-id';
```

Then:

```bash
flutter run
```

To point at a local API rather than production, pass `baseUrl` to
`configure()`: `http://localhost:3000` on the iOS simulator,
`http://10.0.2.2:3000` on the Android emulator.

## Adding a product

Install the product instead: it depends on `appwin_core` and re-exports it, so
you do not list `appwin_core` yourself.

```bash
flutter pub add appwin_support
```

```dart
import 'package:appwin_support/appwin_support.dart';   // re-exports AppwinCore

await AppwinCore.instance.configure(appId: appId);

final support = await AppwinSupport.instance.initialize();
if (support.isReady) {
  // Your app owns the entry point; the SDK draws the messenger.
  await AppwinSupport.instance.presentMessenger();
}
```
