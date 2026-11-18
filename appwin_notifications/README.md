# appwin_notifications

`appwin_notifications` sends **push and in-app messages to your Flutter app**:
device token registration, the lifecycle events that trigger automations, and
the in-app campaigns waiting for a user.

**Appwin** is an engagement platform for mobile app studios. It puts an in-app
support messenger, a community feed and push notifications inside your app, all
rendered natively, and gives your team one dashboard to run them.

- [appwin.io](https://appwin.io)
- [Documentation](https://appwin.io/docs)
- [Notifications product guide](https://appwin.io/docs/products/notifications)

## Features

- ✅ **One call at launch**: `start()` asks for push permission, registers the token and presents in-app messages
- ✅ **Campaigns and automations** driven from the dashboard, no app release
- ✅ **In-app messages** presented natively, or handed to **your** widgets if you prefer
- ✅ **Delivery reporting** - opened, clicked, dismissed - so campaigns have real numbers
- ✅ **Works next to FlutterFire**: forward its callbacks to `AppwinPush`
- ✅ **Comes with `appwin_core`**, so a single `configure` covers every product

## Installation

```bash
flutter pub add appwin_notifications
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

No repository to add: the plugin declares the native SDKs it needs, from
CocoaPods (or Swift Package Manager) and Maven Central. Your app only has to
meet the minimums: an iOS deployment target of 16.0 (in Xcode, plus
`platform :ios, '16.0'` in `ios/Podfile` if you use CocoaPods), and
`minSdk = 24` in `android/app/build.gradle` if yours is lower.

## Getting started

**1. Configure the foundation at launch.** This step is required, and it is the
only one that is: every Appwin product reads the identity and the session it
sets up.

```dart
import 'package:appwin_notifications/appwin_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

**2. Initialise, then start Notifications.** `initialize()` asks the server
whether Notifications may run for this app, and answers rather than throwing.
Call it before any push prompt: a system prompt for a product the studio cannot
use spends the single "allow" a user grants, and neither iOS nor Android asks
twice. Then `start()` takes over the rest: push permission, token registration,
realtime delivery and in-app presentation.

```dart
final notifications = await AppwinNotifications.instance.initialize();
debugPrint('Appwin Notifications: $notifications');   // ready / unavailable(plan) / ...

if (notifications.isReady) {
  await AppwinNotifications.instance.start();
}
```

To ask for permission yourself on iOS, at a moment the user understands why,
pass `requestPushPermission: false`, then register the token as shown below
once it is granted. `stop()` undoes what `start()` installed, for a
kids mode or a paused account; it is not needed on sign-out
(`AppwinCore.instance.logout()` covers that).

**3. Push setup per platform.** On iOS, enable the *Push Notifications*
capability of the Runner target and upload your APNs key in the dashboard. On
Android, push goes through Firebase Cloud Messaging: your app needs Firebase set
up (`firebase_messaging` and `google-services.json`), and the FCM credentials go
in the dashboard. Without Firebase, `start()` still runs and in-app messages
still work; only push is skipped.

If your app registers tokens itself, forward each one, and again on every
rotation:

```dart
await AppwinCore.instance.registerPushToken(token: token);
```

Pass `pushOptIn: false` rather than skipping the call when the user declines:
that distinguishes "declined" from "never asked", which are two different
audiences on the studio's side.

If your app owns its push stack (FlutterFire), pass
`installsNotificationDelegate: false` to `start()` on iOS and forward each
callback to `AppwinPush` (see the API reference of `AppwinPush` in
`appwin_core`).

**4. Report your own moments** so automations can trigger on them. Lifecycle
events (`app_open`, `session_start`...) are sent for you; what only your app
knows goes through Core's event stream:

```dart
await AppwinCore.instance.track('purchase', props: {'value': 9.99, 'currency': 'EUR'});
await AppwinCore.instance.track('onboarding_finished');
```

## Rendering in-app messages yourself

`start()` presents in-app messages with the SDK's UI and reports opens, clicks
and dismissals on its own. To draw them with your own widgets instead, fetch
them and report what the user did:

```dart
final messages = await AppwinNotifications.instance.fetchPendingMessages();

for (final message in messages) {
  // Render message.content with your own widgets, then:
  await AppwinNotifications.instance.track(
    deliveryId: message.deliveryId,
    event: AppwinTrackEvent.opened,
  );
}
```

Reporting matters: without it the campaign has no read rate, and an automation
that waits on "opened" never fires. Report `AppwinTrackEvent.clicked` with the
`buttonIndex` of the tapped button, and `AppwinTrackEvent.dismissed` when the
message is closed without acting on it.

## Documentation

- [Notifications: push and in-app messages](https://appwin.io/docs/products/notifications)
- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
