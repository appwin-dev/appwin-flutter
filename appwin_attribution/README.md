# appwin_attribution

Flutter plugin wrapping the native Appwin Attribution SDK: SKAdNetwork
conversion values, advertising identity, Play Install Referrer and the
optional embedded ad-network adapters (TikTok).

```dart
await AppwinCore.instance.configure(appId: 'your-app-id');
AppwinAttribution.instance.setAdvertisingConsent(AppwinAdvertisingConsent.granted);
await AppwinAttribution.instance.initialize();
await AppwinAttribution.instance.requestTrackingAuthorization();
```
