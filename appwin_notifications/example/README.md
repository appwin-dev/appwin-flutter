# appwin_notifications_example

Integration of `appwin_notifications` that renders in-app messages with its own
widgets: `configure()` once at startup, `initialize()`, then the messages
pending at launch (`syncOnAppOpen()`) listed in the app, each reported with
`track()` when tapped. Most apps call `start()` instead and let the SDK present
and report the messages.

## Run it

Put your App ID in `lib/main.dart` first, from your Appwin dashboard:

```dart
const appId = 'your-app-id';
```

Then:

```bash
flutter run
```

Full guide: https://appwin.io/docs/products/notifications
