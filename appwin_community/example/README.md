# appwin_community_example

Minimal integration of `appwin_community`: `configure()` once at startup, a
`onNotificationTap` handler that opens the tapped post, `initialize()`, the
`events` stream, an unread badge from `unreadNotificationCountStream`, and the
feed itself as an `AppwinCommunityView`.

## Run it

Put your App ID in `lib/main.dart` first, from your Appwin dashboard:

```dart
const appId = 'your-app-id';
```

Then:

```bash
flutter run
```

Full guide: https://appwin.io/docs/products/community
