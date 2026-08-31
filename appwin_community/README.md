# appwin_community

Flutter plugin for the Appwin Community SDK. All the UI is native - SwiftUI on
iOS, Compose on Android: your app provides an entry point, the SDK draws the
feed, the comments, the profiles and the member-side moderation.

| Platform | Status | Minimum |
| --- | --- | --- |
| iOS | ✅ | 16.0 |
| Android | ✅ | 7.0 (API 24) |

On other platforms, `AppwinCommunityView` renders a neutral screen rather than
throwing, so a multi-platform app stays launchable.

## Install

One package in `pubspec.yaml`: it depends on `appwin_core` (the single
`configure` and the identity API) and re-exports it.

```yaml
dependencies:
  appwin_community:
    path: ../path/to/sdk/appwin-flutter/appwin_community

# Until `appwin_core` is published, tell pub where to find it: an override only
# applies from the root, so the plugin's own override does not apply here.
dependency_overrides:
  appwin_core:
    path: ../path/to/sdk/appwin-flutter/appwin_core
```

```dart
import 'package:appwin_community/appwin_community.dart';   // AppwinCore comes with it

await AppwinCore.instance.configure(appId: 'your-app-id');
```

The Android AARs come from Maven Central (`io.appwin:appwin-*`). There is
nothing to add to your app's repositories: the plugin declares what it needs.

The native SDKs arrive through CocoaPods. In `ios/Podfile`:

```ruby
platform :ios, '16.0'

target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  pod 'AppwinCore',      :path => '<path>/sdk/appwin-ios'
  pod 'AppwinCommunity', :path => '<path>/sdk/appwin-ios'
end
```

Then `cd ios && pod install`.

> `platform :ios, '16.0'` is required: the SDK uses SwiftUI and async/await.
> Without that line CocoaPods targets iOS 12 and the build fails.

## Usage

### 1. Initialise at launch

```dart
await AppwinCommunity.instance.initialize(
  appId: 'your-app-id',             // dashboard → Community → SDK
  baseUrl: 'http://localhost:3000', // development only, null in production
);
```

If your app already integrates `appwin_support`, **one `initialize` is enough**:
both SDKs share the device identity carried by AppwinCore.

### 2. Show the feed in a tab

This is the expected integration: full page, inside your tab bar.

```dart
Scaffold(
  body: IndexedStack(
    index: _index,
    children: const [
      HomePage(),
      AppwinCommunityView(),   // ← the feed, natively
      ProfilePage(),
    ],
  ),
  bottomNavigationBar: NavigationBar(/* ... */),
)
```

`IndexedStack` rather than swapping the widget: the native view keeps its scroll
position and its loaded pages when you leave the tab and come back.

### 3. Identity (optional)

With nothing else, the member is **anonymous** with a stable generated nickname,
and can name themselves from inside the SDK. If your app already has accounts:

```dart
// Attach the member to YOUR user (shared with Support)
await AppwinCommunity.instance.login(externalId: user.id);

// Push what you already know, to save them the typing
await AppwinCommunity.instance.setUser(
  nickname: user.displayName,
  avatarUrl: user.photoUrl,
);

// On sign-out
await AppwinCommunity.instance.logout();
```

Every `setUser` field is optional; an omitted field is not overwritten.
Providing a `nickname` takes the profile out of anonymity.

### 4. Notification badge

```dart
final unread = await AppwinCommunity.instance.unreadNotificationCount();
```

Returns `0` rather than an error when the call fails: a badge must never break
the rendering of a tab bar.

### 5. Modal presentation (special case)

When the community has no dedicated tab (entry from a menu, opening from a
notification):

```dart
await AppwinCommunity.instance.presentCommunity();
```

It adds a close button, which the embedded mode does not have.

## What is configured from the dashboard

None of the following is driven by your app's code: it all lives under
**Community → Customise** in the Appwin dashboard.

- accent colour, font, text size, corner radius, light and dark theme
- turning on the community, posts, comments, replies, images, reactions, view
  counters, public profiles, reporting
- instant translation into the device language
- maximum length of posts and comments, image count, lines before "see more",
  flood protection
- moderation (off, automatic, manual), thresholds, banned words

The SDK re-reads the config on every open (with an ETag), so a change on the
studio's side applies without redeploying the app.

## Localisation

The SDK's labels are resolved in **your** app's bundle. To translate or reword
them, add an `AppwinCommunity.strings` to your project:

```
"community.new_post" = "Share something";
"community.like" = "Like";
```

Without that file the SDK uses its English defaults. The keys are listed in
`CommunityStrings.swift`.

## Example

`example/` holds a minimal app reproducing the tab integration. Fill in `_appId`
in `example/lib/main.dart`, then:

```bash
cd example
flutter run
```
