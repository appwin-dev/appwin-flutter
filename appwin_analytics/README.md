# appwin_analytics

`appwin_analytics` measures **what happens in your Flutter app**: sessions,
screen views and the custom events you care about, ingested by Appwin and
explored in the dashboard (trends, funnels, retention).

**Appwin** is an engagement platform for mobile app studios. It puts an in-app
support messenger, a community feed and push notifications inside your app, all
rendered natively, and gives your team one dashboard to run them.

- [appwin.io](https://appwin.io)
- [Documentation](https://appwin.io/docs)
- [Analytics product guide](https://appwin.io/docs/products/analytics)

## Features

- ✅ **Sessions and screen views** tracked with a single call each
- ✅ **Custom events** with typed props (strings, numbers, booleans)
- ✅ **Offline-first pipeline** - events persist on device and upload in batches
- ✅ **Crash reporting** - native crashes, ANRs and uncaught Dart errors, grouped into issues
- ✅ **Consent-aware** - relay your consent screen's verdict, buffered before init
- ✅ **No blocking, no throwing** - `track` returns immediately, failures degrade quietly
- ✅ **Comes with `appwin_core`**, so a single `configure` covers every product

Like Notifications, this product **draws nothing**. It records what your app
reports; the screens stay yours.

## Installation

```bash
flutter pub add appwin_analytics
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
import 'package:appwin_analytics/appwin_analytics.dart';   // re-exports AppwinCore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

**2. Initialise Analytics.** `configure` checks nothing; `initialize()` asks
the server whether Analytics may run for this app, and answers rather than
throwing.

```dart
final analytics = await AppwinAnalytics.instance.initialize();
debugPrint('Appwin Analytics: $analytics');   // ready / unavailable(plan) / ...
```

The verdict is cached on disk, so an offline launch falls back to the last
known answer instead of dropping a product you pay for.

**3. Track events** from wherever they happen. The call never blocks and never
throws: the event is persisted locally and uploaded in batches, offline
included.

```dart
AppwinAnalytics.instance.track('level_completed', props: {'level': 3});
AppwinAnalytics.instance.track('purchase', props: {'value': 9.99, 'currency': 'EUR'});
```

Event names match `^[a-z][a-z0-9_]{0,63}$`. The `purchase` convention
(`value` + `currency`) also feeds the ad networks and the SKAN conversion value
when Attribution runs.

**4. Record screen views** to power funnel steps and breakdowns:

```dart
AppwinAnalytics.instance.screen('checkout');
```

**5. Relay analytics consent** if your app has a consent screen. Callable
before `initialize`, buffered natively:

```dart
AppwinAnalytics.instance.setConsent(AppwinAnalyticsConsent.granted);
```

## Crashes

Crash reporting starts with `initialize()`, under the same verdict and the
same consent as events. It captures native crashes and ANRs through the native
SDK, and uncaught Dart errors through `FlutterError.onError` and
`PlatformDispatcher.onError`. Handlers you or another SDK installed earlier
(Crashlytics, Sentry) keep running after Appwin's.

```dart
await AppwinAnalytics.instance.initialize(
  inAppPackages: ['my_app'],   // your packages: their frames group issues
);

try {
  await checkout();
} catch (e, stack) {
  AppwinAnalytics.instance.recordError(e, stack);   // non-fatal
}
```

Dart errors are reported as non-fatal: they do not stop a Flutter app. Pass
`crashReporting: false` to `initialize()` to turn the whole feature off.
Stacks from `--obfuscate` or `--split-debug-info` builds are sent as raw
addresses and are not symbolicated yet.

## Documentation

- [Analytics: sessions, events and funnels](https://appwin.io/docs/products/analytics)
- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
