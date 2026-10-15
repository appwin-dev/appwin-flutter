## 0.14.2

**Native SDKs iOS 0.14.2 and Android 0.14.2.** Community fix, no API change.

- The unread notification badge now clears. Opening the Community feed, or
  coming back to it (for example from a host tab), marks all of the member's
  notifications as read and the unread count drops to 0. Before, nothing marked
  them read, so a badge that appeared never went away.

## 0.14.1

**Native SDKs iOS 0.14.1 and Android 0.14.1.** Community UI polish, no API change.

- Poll creation redesigned to the Figma spec: bordered option fields, a dashed
  "add an option" row, the post text below the options, and the placeholder in
  the right grey. The option field no longer shifts height when focused.
- Poll result bars animate in; a chosen reaction shows its emoji in place of
  the heart; videos keep their sound regardless of the silent switch; a forced
  light or dark theme is now fully applied.
- A rate-limit banner appears when posting or commenting too fast (HTTP 429).
- iOS: post, reply thread, moderation, sanctions and profile use the native
  navigation bar; the profile and notifications no longer nudge the back button
  when their content loads.
- Android: the publish button no longer flickers on the first typed character;
  opening a group shows a single centred loader; the composer and profile
  editor open as bottom sheets; text is no longer letter-spaced.
- Both: heart and comment icons refreshed from Figma; the feed accent glow is
  lighter.

## 0.14.0

Native SDKs iOS 0.14.0 and Android 0.14.0.

- **Breaking:** `AppwinCommunity.instance.onEditProfile` is removed. The
  profile editing handlers now go on the view that shows the feed:
  `AppwinCommunityView(onEditProfile:, onEditProfilePhoto:, onEditProfileName:)`,
  and the same parameters on `AppwinCommunity.instance.presentCommunity()`.
- Community, profile fields managed by the app: with `onEditProfilePhoto`,
  tapping the photo in the SDK's profile editor calls your app instead of
  opening the photo library; with `onEditProfileName`, the name is read-only
  in the SDK, tapping it calls your app, and the anonymity switch is hidden.
  The bio stays editable in the SDK. `onEditProfile` still replaces the whole
  editor.
- The SDK closes its own screens (profile sheet, editor, the feed opened with
  `presentCommunity`) before calling your handler, so your route shows on top.
  A post opened from a notification, with no view mounted, hides the fields
  your app owns instead of letting the member edit them in the SDK.
- Community, iOS: the profile opens at full width right away, and after
  posting the feed returns to its real top (or brings the new post into view
  when pinned posts sit above it).

## 0.13.0

Native SDKs iOS 0.13.0 and Android 0.13.0. No API change on this side; the community screens gain:

- Community, fonts: the studio sets a font for titles (the feed title and the
  member's name on their profile) separately from the font for texts. The
  title font follows the text font until the studio chooses one.
- Community, custom fonts work on Android: the name the studio gives is
  looked up in `res/font/` (Android resource naming, `Caprasimo-Regular` →
  `caprasimo_regular.ttf`) and in `assets/fonts/`. Until now Android used the
  system font whatever the studio set.
- Community, custom fonts in a Flutter app: a font declared in `pubspec.yaml`
  is found with no native setup, on iOS and Android, by PostScript name, file
  name or family name. Adding the file to the Runner target and `UIAppFonts`
  is no longer needed.
- Community, a custom font the SDK cannot find is reported once in the debug
  console (Xcode, Logcat under `Appwin`) instead of falling back silently.

## 0.12.0

Native SDKs iOS 0.12.0 and Android 0.12.0. No API change on this side; the community screens gain:

- Community, in-app moderation: moderators and admins get a flag with the
  pending count and a Moderation screen to restore, confirm, keep or hide
  reported content. From any post, comment or profile they can hide or delete
  with a reason, move a post to another group, pin it (end date and/or views
  per member), warn, shadow-ban or ban a member.
- Community, members: a new report sheet; a bell lists the sanctions they
  received (removed post or comment, warning, ban) until they tap "Got it";
  a post or comment removed by moderation as it is published shows an alert
  instead of disappearing.
- Community, reactions: 11 emojis on a long press of a post's heart or a
  comment, when the studio enables emoji reactions; the post comes forward and
  the rest of the screen dims. Heart-only communities keep the single heart.
- Community, design: admin badge on avatars, redesigned profile editing and
  anonymous banner in the composer, « ⋯ » menus that open on the dots. The
  studio's permissions for images, videos, polls and comments are applied.

## 0.11.2

Native SDKs iOS 0.11.1 and Android 0.11.2: session replay no longer makes the
app stutter (see `appwin_analytics`). No API change on this side.

## 0.11.1

Android SDK 0.11.1: session replay fix in release builds (see `appwin_analytics`).
No API change on this side.

## 0.11.0

Native SDKs 0.11.0: session replay in Analytics (see `appwin_analytics`).
No API change on this side.

## 0.10.0

**Native SDKs 0.10.0.** Reactions on posts (heart by default, toggle, read-only
breakdown for the author) and an in-app banner when the app is open.

- No more gap under the Community button when embedded in a Flutter screen
  whose tab bar already handles the bottom inset.

## 0.9.2

**Native SDKs 0.9.2.** Support and Community screens aligned on the InApp
mockups: customizable gradient, `colorScheme` and `grayWarmth` from the
dashboard, Help Center title and welcome message, "My inbox" hidden until a
conversation exists. No API change on this side.

## 0.9.1

Native SDKs 0.9.1: `registerPushToken` waits for the session before posting
and retries once with a fresh session after a 401 caused by a concurrent
`identify`. No API change on the Dart side.

## 0.9.0

- `events`: a stream of the current member's own actions (post, comment,
  reply, reaction, profile), once the server accepted them. Built for
  gamification.
- `unreadNotificationCountStream`: the unread count, live, for a badge.
- `onNotificationTap` and `openPost(postId, {commentId})`: route a
  notification tap to your Community tab yourself. Unset, a tap now opens the
  post even when the feed is not on screen, full screen over the app. Set it
  before `initialize()`.
- `onEditProfile`: replaces the SDK's profile editor with yours; push the
  result with `setUser`.
- `lastResult`: the current verdict, kept live.
- `AppwinCommunityView(unavailableBuilder: ...)`: your own UI while Community
  is not ready. Without it, the native "coming soon" placeholder replaces the
  empty view, with a diagnosis card in debug builds.
- Debug builds unlock Community without the plan; release builds still need
  it.

## 0.8.0

- **Breaking:** `login` and `logout` are removed: use `AppwinCore.instance.identify(...)` and `AppwinCore.instance.logout()`. `setUser` (public community profile) stays.

## 0.5.1

- iOS via CocoaPods is fixed. The podspec asked for `AppwinCore ~> 0.1`, a range
  an old `Podfile.lock` already satisfied, so `pod install` never upgraded the
  native SDK and the build failed on a symbol the pinned Core did not have. It
  now pins `>= 0.5.1, < 1.0.0`. Native 0.5.1 also restores the CocoaPods build,
  which 0.5.0 broke outright. No Dart API change.

## 0.5.0

- Version aligned with `appwin_core` 0.5.0 and its siblings. No change to the
  Dart API; the native feed follows the Figma designs.

## 0.4.1

- **Fix.** `AppwinCommunityView` crashed the app on Android, in SIGABRT rather
  than a Dart error: lacking a parent composition context, Compose looked for a
  lifecycle owner on the root of the view tree, which under Flutter has none.
  The view now supplies its own.
- Documentation on the whole public API, up from 52%: what the product is, and
  every member of the platform interface, the method channel and the profile.

## 0.4.0

- Version aligned with `appwin_core` 0.4.0 and its siblings. No change to the
  API: push tokens are registered through `AppwinCore.registerPushToken()`, and
  this package never exposed one of its own.

## 0.3.0

* New sibling package `appwin_notifications`: push tokens, automation events
  and in-app messages. The product existed natively and in React Native but
  had no Flutter package.

## 0.2.1

* Real example app: configure, initialise, then render from the answer. It was
  still the Flutter template, which called neither.
* Package page: simpler snippets that print the result instead of wiring state,
  and a clearer note on installing `appwin_core` (you do not).

## 0.2.0

**Breaking.** `initialize()` no longer takes an `appId` and no longer
configures the foundation. Call `AppwinCore.instance.configure()` first, then
`initialize()`, which answers whether this product may open for your app.

## 0.1.1

* Package page rewritten for pub.dev: what Appwin is, what this package does,
  installation, a minimal start, and links to the guide for the rest.
* Real licence file instead of the Flutter template placeholder.

## 0.1.0

* First published release.

## 0.0.2

* Android: the feed, the full-screen presentation and identity go through the
  native Kotlin SDK. `AppwinCommunityView` is rendered there in hybrid
  composition.
* Depends on `appwin_core` and re-exports it: `AppwinCore.instance.configure`
  comes with this package, one App ID for every product.
* `login` replays the session bootstrap on both platforms, so the calls that
  follow carry the new identity rather than only doing so on iOS.

## 0.0.1

* Initial version: embeddable native iOS community feed
  (`AppwinCommunityView`), full-screen presentation, identity (`login`,
  `setUser`), notification badge.
