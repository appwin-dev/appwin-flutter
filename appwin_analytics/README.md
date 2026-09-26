# appwin_analytics

Flutter plugin wrapping the native Appwin Analytics SDK: sessions, screens
and custom events, explored in the [Appwin](https://appwin.io) dashboard.

```dart
await AppwinCore.instance.configure(appId: 'your-app-id');
final analytics = await AppwinAnalytics.instance.initialize();
AppwinAnalytics.instance.track('purchase', props: {'value': 9.99, 'currency': 'EUR'});
```
