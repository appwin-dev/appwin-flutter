/// In-app messages and the events a campaign is tracked by.
///
/// The native SDK presents these itself; you only touch these types when you
/// render them yourself, through `fetchPendingMessages()`.
library;

/// An in-app message the server has queued for this device.
class AppwinInAppMessage {
  /// Builds a message. The SDK decodes them for you; this is here for tests
  /// and for a host app rendering its own UI.
  const AppwinInAppMessage({
    required this.id,
    required this.campaignId,
    required this.deliveryId,
    required this.channel,
    required this.format,
    required this.content,
  });

  /// Message id, unique to this queued copy.
  final String id;

  /// The campaign that produced it, shared by every recipient.
  final String campaignId;

  /// This delivery, to this device. It is what `AppwinNotifications.track`
  /// reports against, so opens and clicks land on the right send.
  final String deliveryId;

  /// Delivery channel, `in_app` for everything reaching this class.
  final String channel;

  /// How the studio chose to present it: `modal`, `banner`, `fullscreen` or
  /// `image_only`. A string rather than an enum: the dashboard can ship a new
  /// format before the SDK knows about it, and an unknown one must not crash
  /// the host app.
  final String format;

  /// Title, body, image and buttons.
  final AppwinInAppContent content;

  /// Decodes what the native side sends over the method channel.
  factory AppwinInAppMessage.fromMap(Map<dynamic, dynamic> map) {
    final content = map['content'] as Map<dynamic, dynamic>? ?? {};
    return AppwinInAppMessage(
      id: map['id'] as String,
      campaignId: map['campaignId'] as String,
      deliveryId: map['deliveryId'] as String,
      channel: map['channel'] as String? ?? 'in_app',
      format: map['format'] as String? ?? 'modal',
      content: AppwinInAppContent.fromMap(content),
    );
  }
}

/// What an [AppwinInAppMessage] actually shows. Every field is optional: the
/// studio composes the message in the dashboard and may leave any of them out.
class AppwinInAppContent {
  /// Builds a payload.
  const AppwinInAppContent({
    this.title,
    this.body,
    this.imageUrl,
    this.deeplink,
    this.buttons,
  });

  /// Headline, absent on an image-only message.
  final String? title;

  /// Body copy.
  final String? body;

  /// Illustration to show above the text.
  final String? imageUrl;

  /// Where tapping the message itself should take the user, independently of
  /// any button.
  final String? deeplink;

  /// Calls to action, in the order the studio arranged them.
  final List<AppwinInAppButton>? buttons;

  /// Decodes what the native side sends over the method channel.
  factory AppwinInAppContent.fromMap(Map<dynamic, dynamic> map) {
    final rawButtons = map['buttons'] as List<dynamic>?;
    return AppwinInAppContent(
      title: map['title'] as String?,
      body: map['body'] as String?,
      imageUrl: map['imageUrl'] as String?,
      deeplink: map['deeplink'] as String?,
      buttons: rawButtons
          ?.whereType<Map<dynamic, dynamic>>()
          .map(AppwinInAppButton.fromMap)
          .toList(),
    );
  }
}

/// One call to action on an in-app message.
class AppwinInAppButton {
  /// Builds a button.
  const AppwinInAppButton({
    required this.label,
    required this.action,
    this.url,
  });

  /// The text on the button, already in the studio's wording.
  final String label;

  /// What tapping it does: `deeplink`, `dismiss`, `opt_in_push` or
  /// `open_settings`. A string for the same reason as
  /// [AppwinInAppMessage.format]: the dashboard may add one first.
  final String action;

  /// Target of a `deeplink` action.
  final String? url;

  /// Decodes what the native side sends over the method channel.
  factory AppwinInAppButton.fromMap(Map<dynamic, dynamic> map) {
    return AppwinInAppButton(
      label: map['label'] as String,
      action: map['action'] as String,
      url: map['url'] as String?,
    );
  }
}

/// What happened to a message, reported back through
/// `AppwinNotifications.track`.
///
/// This is what turns a send into a statistic in the dashboard: a message
/// presented without [opened] never counts as seen.
enum AppwinTrackEvent {
  /// Shown to the user.
  opened,

  /// A button, or the message body, was tapped.
  clicked,

  /// Closed without acting on it.
  dismissed,
}

/// Moments a studio can trigger a campaign from.
///
/// The native SDK reports the lifecycle ones on its own once
/// `AppwinNotifications.start` has run. You report the rest, the ones only
/// your app knows about.
enum AppwinAutomationEvent {
  /// App came to the foreground.
  appOpen('app_open'),

  /// App went to the background.
  appBackground('app_background'),

  /// A purchase completed. Report it yourself, with the amount in the
  /// properties if the campaign segments on it.
  purchase('purchase'),

  /// Anything specific to your app, named through `eventName`.
  customEvent('custom_event'),

  /// The user accepted push permission.
  pushOptIn('push_opt_in'),

  /// A new session began.
  sessionStart('session_start');

  const AppwinAutomationEvent(this.wireValue);

  /// The value the server expects, which is not the Dart name.
  final String wireValue;
}
