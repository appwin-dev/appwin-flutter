# appwin_support

Flutter wrapper around the **native Appwin Support SDKs**
(ADR-0019).

Thin Dart glue on top of the native code. **No UI is rendered on the Flutter
side**: like Intercom, your app calls a method and a native Appwin screen
appears on top. The proprietary logic (UI, ADR-0011 auth, transport) lives in
the native SDK at `sdk/appwin-ios` and `sdk/appwin-android`, not here.

## Platforms

| Platform | Status | Minimum |
| -------- | ------ | ------- |
| iOS      | ✅      | 16.0 |
| Android  | ✅      | 7.0 (API 24) |

The Android AARs come from Maven Central (`io.appwin:appwin-*`). There is
nothing to add to your app's repositories: the plugin declares what it needs.

## Install

```bash
flutter pub add appwin_support
```

`appwin_core` comes with it and is re-exported, so you configure the foundation
once and use the product.

## Usage

```dart
import 'package:appwin_support/appwin_support.dart';

// Presents the native Appwin messenger on top of your app.
await AppwinSupport.instance.presentMessenger();

// Sanity check of the Dart to Swift bridge (returns e.g. "iOS 18.0").
final v = await AppwinSupport.instance.getPlatformVersion();
```

`AppwinSupport.instance` is a singleton (the Intercom model). Your app builds no
screen: it triggers, the native side draws.

## Architecture

```
Dart  AppwinSupport.instance.presentMessenger()
  └─ MethodChannel "appwin_support"
       └─ ios/Classes/AppwinSupportPlugin.swift   (bridge)
            └─ AppwinSupport.presentMessenger()    (native SDK, SwiftUI)
```

- `lib/appwin_support.dart` - public facade (singleton)
- `lib/appwin_support_platform_interface.dart` - platform contract
- `lib/appwin_support_method_channel.dart` - MethodChannel implementation
- `ios/appwin_support/Sources/appwin_support/AppwinSupportPlugin.swift` - iOS bridge
- `android/src/main/kotlin/io/appwin/flutter/support/AppwinSupportPlugin.kt` - Android bridge
- `ios/appwin_support.podspec` + `ios/appwin_support/Package.swift` - iOS packaging
- `android/build.gradle` - Android packaging

> Flat structure (the interface-in-files pattern), **not** the federated split
> into per-platform packages: two bridges speaking the same method channel fit
> in one package, and a studio has nothing extra to install (ADR-0019).

## iOS development, wiring the native SDKs

The Firebase and FlutterFire pattern (see ADR-0020): the plugin **depends on**
the native `AppwinCore` and `AppwinSupport` through CocoaPods. It compiles
**only** its own glue file. The native modules are real, separate Swift modules,
so `import AppwinCore` and `import AppwinSupport` work normally.

### Podfile setup in the host app

To develop the plugin alongside the native SDKs, declare the local pods in the
`Podfile` of your test Flutter app. All four podspecs live in the single
`appwin-ios` folder, next to `Package.swift`:

```ruby
target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Local dev pods - CocoaPods compiles from source on every rebuild.
  pod 'AppwinCore',          :path => '../../../../appwin-ios'
  pod 'AppwinSupport',       :path => '../../../../appwin-ios'
  pod 'AppwinNotifications', :path => '../../../../appwin-ios'
end
```

Edit a file in `sdk/appwin-ios/Sources/AppwinCore/` or
`sdk/appwin-ios/Sources/AppwinSupport/`, then `flutter run` rebuilds everything.
No symlink, no copy, no publishing.

### Adding a new native file

Nothing to do on the Flutter side. The podspec's `source_files` glob
(`Sources/AppwinCore/**/*.swift` or `Sources/AppwinSupport/**/*.swift`) picks it
up on the next `pod install`.

### Distribution

At release time the script rewrites `ios/appwin_support/Package.swift` so the
local path becomes a tagged git URL on `appwin-dev/appwin-ios`. Nothing to do by
hand. See ADR-0036.

## Testing

```bash
# Dart: analysis and unit tests
flutter analyze
flutter test

# Demo app (an "Open support" button opens the native screen)
cd example && flutter run

# Native iOS SDK: run it from the repository root, the package is iOS-only
# so `swift build` (which targets macOS) does not apply.
pnpm sdk:check --only=swift
```
