# appwin_core

`appwin_core` is the foundation of the Appwin SDKs for Flutter. It carries what
every Appwin product shares: the device identity, the authenticated session and
the network client. You configure it once, and the products you installed use
it.

**Appwin** is an engagement platform for mobile app studios. It puts an in-app
support messenger, a community feed and push notifications inside your app, all
rendered natively, and gives your team one dashboard to run them.

- [appwin.io](https://appwin.io)
- [Documentation](https://appwin.io/docs)
- [Quickstart](https://appwin.io/docs/quickstart)

## Features

- ✅ **One `configure`** for every Appwin product in your app, whatever the number
- ✅ **Anonymous by default** - a device is known without asking anyone to sign up
- ✅ **`identify`** attaches your own user id when someone signs in
- ✅ **One identity across products** - sign in once, recognised in Support and Community
- ✅ **`signOut`** clears the person without losing the device
- ✅ **Native under the hood** - Swift on iOS, Kotlin on Android

## Installation

You rarely install this package on its own. Every Appwin product depends on it
and re-exports it, so it arrives with the product:

```bash
flutter pub add appwin_support     # or appwin_community
```

Install it directly only for an app that wants the identity API with no product:

```bash
flutter pub add appwin_core
```

### Requirements

| Platform | Minimum |
| --- | --- |
| iOS | 16.0 |
| Android | 7.0 (API 24) |

Nothing to add to your `Podfile` or to your Gradle repositories: the plugin
declares the native SDKs it needs, from CocoaPods and Maven Central.

## Getting started

Configure once, at launch:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwinCore.instance.configure(appId: 'your-app-id');
  runApp(const MyApp());
}
```

When someone signs in to your app:

```dart
await AppwinCore.instance.identify(externalId: user.id);
await AppwinCore.instance.bootstrapSession(externalId: user.id);
```

Both calls, not one: `identify` records the identity, `bootstrapSession` mints
the token that carries it. Without the second, the calls that follow stay on the
anonymous session until the next launch.

On sign-out:

```dart
await AppwinCore.instance.signOut();
```

## One `configure`, then one `initialize()` per product

`configure` prepares the foundation and checks nothing. Each product you
install has its own `initialize()`, which asks the server whether that product
may open for this app, and answers rather than throwing:

```dart
final support = await AppwinSupport.instance.initialize();
if (support.isReady) {
  setState(() => _showHelpButton = true);
}
```

Gate your own entry point on that result: the SDK cannot hide your tab or your
button, it does not own your navigation. The three products share one round
trip and the verdict is cached on disk, so being offline falls back to the last
known answer instead of closing a product you pay for.

## Documentation

- [Install the SDK](https://appwin.io/docs/sdk/installation)
- [Identity: anonymous and signed-in users](https://appwin.io/docs/sdk/identity)
- [Core concepts](https://appwin.io/docs/concepts)

## License

Proprietary. Use is reserved to studios holding a current Appwin contract.
