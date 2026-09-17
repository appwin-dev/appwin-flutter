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

- ✅ **Push token registration**, with an explicit opt-in flag
- ✅ **Campaigns and automations** driven from the dashboard, no app release
- ✅ **In-app messages** delivered to the device, rendered by **your** widgets
- ✅ **Delivery reporting** - opened, clicked, dismissed - so campaigns have real numbers
- ✅ **One call at launch**: `syncOnAppOpen()` reports the open and returns what is pending
- ✅ **Comes with `appwin_core`**, so a single `configure` covers every product

Unlike Support and Community, this product **draws nothing**. It hands you the
message; the design is yours.

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

Nothing to add to your `Podfile` or to your Gradle repositories: the plugin
declares the native SDKs it needs, from CocoaPods and Maven Central.

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

**2. Initialise Notifications before asking for permission.** A system prompt
for a product the studio cannot use spends the single "allow" a user grants,
and neither iOS nor Android asks twice.

```dart
final notifications = await AppwinNotifications.instance.initialize();
debugPrint('Appwin Notifications: $notifications');   // ready / unavailable(plan) / ...

if (notifications.isReady) {
  // Ask the system for permission, then register the token below.
}
```

**3. Register the device token**, and again on every rotation:

```dart
await AppwinNotifications.instance.registerPushToken(token: fcmOrApnsToken);
```

Pass `pushOptIn: false` rather than skipping the call when the user declines:
that distinguishes "declined" from "never asked", which are two different
audiences on the studio's side.

**4. Sync at launch** to report the open and collect what is pending, in one
round trip:

```dart
final messages = await AppwinNotifications.instance.syncOnAppOpen();

for (final message in messages) {
  // Render it with your own widgets, then report what the user did:
  await AppwinNotifications.instance.track(
    deliveryId: message.deliveryId,
    event: AppwinTrackEvent.opened,
  );
}
```

Reporting matters: without it the campaign has no read rate, and an automation
that waits on "opened" never fires.

## Documentation

- [Notifications: push and in-app messages](https://appwin.io/docs/products/notifications)
- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
