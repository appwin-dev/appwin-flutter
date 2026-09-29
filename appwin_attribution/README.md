# appwin_attribution

`appwin_attribution` reports **where your Flutter app's installs come from**:
SKAdNetwork conversion values and the advertising identity on iOS, the Play
Install Referrer on Android, plus the optional embedded ad-network adapters
(TikTok). The native SDK owns the signals; this layer relays your decisions.

**Appwin** is an engagement platform for mobile app studios. It puts an in-app
support messenger, a community feed and push notifications inside your app, all
rendered natively, and gives your team one dashboard to run them.

- [appwin.io](https://appwin.io)
- [Documentation](https://appwin.io/docs)
- [Attribution product guide](https://appwin.io/docs/products/attribution)

## Features

- ✅ **SKAdNetwork conversion values** managed for you on iOS
- ✅ **Advertising identity** (IDFA / GAID), gated by consent and by ATT
- ✅ **Play Install Referrer** captured on Android
- ✅ **Embedded ad-network adapters** (TikTok), enabled from the dashboard
- ✅ **Consent-first** - signals reach the networks only after you say so
- ✅ **Comes with `appwin_core`**, so a single `configure` covers every product

Like Notifications and Analytics, this product **draws nothing**: the only UI it
touches is the system ATT prompt, which you trigger.

## Installation

```bash
flutter pub add appwin_attribution
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
declares the native SDKs it needs, from CocoaPods and Maven Central. On iOS,
declare `NSUserTrackingUsageDescription` in your `Info.plist` before prompting
for ATT.

## Getting started

**1. Configure the foundation at launch.** This step is required, and it is the
only one that is: every Appwin product reads the identity and the session it
sets up.

```dart
import 'package:appwin_attribution/appwin_attribution.dart';   // re-exports AppwinCore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

**2. Relay advertising consent before initialising.** This decides IF signals
reach the networks at all. Callable before `initialize`, buffered natively:

```dart
AppwinAttribution.instance.setAdvertisingConsent(AppwinAdvertisingConsent.granted);
```

**3. Initialise Attribution.** `configure` checks nothing; `initialize()` asks
the server whether Attribution may run for this app, and answers rather than
throwing.

```dart
final attribution = await AppwinAttribution.instance.initialize();
debugPrint('Appwin Attribution: $attribution');   // ready / unavailable(plan) / ...
```

The verdict is cached on disk, so an offline launch falls back to the last
known answer instead of dropping a product you pay for.

**4. Request tracking authorization** on iOS, when your flow decides to ask. A
refused ATT does not stop attribution; it only removes the IDFA from the
signals. Android has no ATT and resolves `true` without showing anything.

```dart
final granted = await AppwinAttribution.instance.requestTrackingAuthorization();
debugPrint('ATT granted: $granted');
```

## Documentation

- [Attribution: install sources and conversion values](https://appwin.io/docs/products/attribution)
- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
