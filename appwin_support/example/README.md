# appwin_support_example

Minimal integration of `appwin_support`: `configure()` once at startup,
`initialize()` to learn whether Support is available, then a button that
calls `presentMessenger()` only when it is ready. The messenger itself is drawn
by the native SDK.

## Run it

Put your App ID in `lib/main.dart` first, from your Appwin dashboard:

```dart
const appId = 'your-app-id';
```

Then:

```bash
flutter run
```

Full guide: https://appwin.io/docs/products/support
