# appwin_core

`appwin_core` is the foundation of the Appwin SDKs for Flutter. It carries what
every Appwin product shares: the device identity, the authenticated session,
the network client, the event stream and consent. You configure it once, and
the products you installed use it.

**Appwin** is an engagement platform for mobile app studios. It puts an in-app
support messenger, a community feed and push notifications inside your app, all
rendered natively, and gives your team one dashboard to run them.

- [appwin.io](https://appwin.io)
- [Documentation](https://appwin.io/docs)
- [Quickstart](https://appwin.io/docs/sdk/installation)

## Features

- ✅ **One `configure`** for every Appwin product in your app, whatever the number
- ✅ **Anonymous by default** - a device is known without asking anyone to sign up
- ✅ **`identify`** attaches your own user id when someone signs in
- ✅ **One identity across products** - sign in once, recognised in Support and Community
- ✅ **`logout`** clears the person without losing the device
- ✅ **One event stream** - `track` feeds Analytics, automations and ad networks alike
- ✅ **Consent per purpose** - analytics, marketing, advertising
- ✅ **Push routing** - `AppwinPush` hands each Appwin push to the product that owns it
- ✅ **Native under the hood** - Swift on iOS, Kotlin on Android

## Installation

```bash
flutter pub add appwin_core
```

Most apps never run that command. Every Appwin product declares `appwin_core`
as a dependency **and re-exports it**, so installing `appwin_support` or
`appwin_community` already gives you `AppwinCore` under the same import. Add it
directly only if you want the identity API with no product at all.

### Requirements

| Platform | Minimum |
| --- | --- |
| iOS | 16.0 |
| Android | 7.0 (API 24) |

No repository to add: the plugin declares the native SDKs it needs, from
CocoaPods (or Swift Package Manager) and Maven Central. Your app only has to
meet the minimums: an iOS deployment target of 16.0 (in Xcode, plus
`platform :ios, '16.0'` in `ios/Podfile` if you use CocoaPods), and
`minSdk = 24` in `android/app/build.gradle` if yours is lower.

## Getting started

Configure once, at launch:

```dart
import 'package:appwin_core/appwin_core.dart';   // or any product package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

When someone signs in to your app:

```dart
await AppwinCore.instance.identify(
  user.id,
  attributes: AppwinUserAttributes(email: user.email, name: user.displayName),
);
```

One call: the id is kept on the device and the session reopens under it. What
you learn later goes through `updateUser`:

```dart
await AppwinCore.instance.updateUser(AppwinUserAttributes(plan: 'premium'));
```

On sign-out:

```dart
await AppwinCore.instance.logout();
```

## One `configure`, then one `initialize()` per product

`configure` prepares the foundation and checks nothing. Each product you
install has its own `initialize()`, which asks the server whether that product
may open for this app, and answers rather than throwing. With `appwin_support`:

```dart
final support = await AppwinSupport.instance.initialize();
debugPrint('Appwin Support: $support');   // ready / unavailable(plan) / ...

if (support.isReady) {
  // Show your help button.
}
```

Gate your own entry point on that result: the SDK cannot hide your tab or your
button, it does not own your navigation. The products share one round
trip and the verdict is cached on disk, so being offline falls back to the last
known answer instead of closing a product you pay for.

To follow the verdict while the app runs (a plan that lapses, a switch flipped
in the dashboard), listen to `availabilityUpdates`:

```dart
AppwinCore.instance
    .availabilityUpdates(AppwinProduct.community)
    .listen((result) => setState(() => _showTab = result.isReady));
```

## Events and consent

`track` is the single event stream: Analytics stores the event, Notifications
automations can trigger on it, and the ad networks receive it when Attribution
runs, each according to the user's consent. It never throws.

```dart
await AppwinCore.instance.track('level_completed', props: {'level': 3});
await AppwinCore.instance.track('purchase', props: {'value': 9.99, 'currency': 'EUR'});
```

Every purpose is granted by default. If your app has a consent screen, relay
its answer, for one purpose or for all three (`analytics`, `marketing`,
`advertising`). Callable before `configure`:

```dart
await AppwinCore.instance.setConsent(
  AppwinConsentState.denied,
  purpose: AppwinConsentPurpose.marketing,
);
```

## Push routing

`AppwinPush` routes Appwin pushes to the product that owns them. With
`appwin_notifications` started and no push code of your own, there is nothing
to write. If your app owns its push stack (FlutterFire), forward each callback
to `AppwinPush.instance.handleTap`, `handleForeground` and `handleMessage`, and
handle yourself only what comes back `false`. The API reference of `AppwinPush`
has the full FlutterFire wiring.

## Documentation

- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)
- [Appwin Core](https://appwin.io/docs/products/appwin-core)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
