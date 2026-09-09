# appwin_core_example

Minimal integration of `appwin_core`, the foundation the Appwin SDKs share.

Core is not a product: it holds the device identity, the session and the
network client that Support, Community and Notifications all reuse. So this
example has no messenger and no feed to open. It shows the three calls a host
app actually makes:

- `configure()` once at startup, before any product;
- `identify()` plus `bootstrapSession()` when your user signs in;
- `signOut()` when they sign out of your app.

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

Add the package next to `appwin_core` and it reuses everything set up here:

```yaml
dependencies:
  appwin_core: ^0.4.0
  appwin_support: ^0.4.0
```

```dart
await AppwinCore.instance.configure(appId: appId);

final support = await AppwinSupport.instance.initialize();
if (support.isReady) {
  // Your app owns the entry point; the SDK draws the messenger.
  AppwinSupport.instance.presentMessenger();
}
```
