/// An in-app message the server has queued for this device.
///
/// The same shape as the Support SDK's, on purpose: both come from the same
/// delivery pipeline, and a studio that already renders one should not have to
/// learn a second model.
class AppwinInAppMessage {
  const AppwinInAppMessage({
    required this.id,
    required this.campaignId,
    required this.deliveryId,
    required this.channel,
    required this.format,
    required this.content,
  });

  final String id;
  final String campaignId;

  /// What you report back to [AppwinNotifications.track]. It identifies this
  /// delivery to this device, not the campaign.
  final String deliveryId;
  final String channel;
  final String format;
  final AppwinInAppContent content;

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

/// What to render. Every field is optional: a campaign may carry a title only,
/// or an image only.
class AppwinInAppContent {
  const AppwinInAppContent({this.title, this.body, this.imageUrl, this.deeplink});

  final String? title;
  final String? body;
  final String? imageUrl;
  final String? deeplink;

  factory AppwinInAppContent.fromMap(Map<dynamic, dynamic> map) {
    return AppwinInAppContent(
      title: map['title'] as String?,
      body: map['body'] as String?,
      imageUrl: map['imageUrl'] as String?,
      deeplink: map['deeplink'] as String?,
    );
  }
}

/// What the user did with a message. Reported through
/// [AppwinNotifications.track].
enum AppwinTrackEvent { opened, clicked, dismissed }

/// Lifecycle events that trigger automations on the server.
///
/// The wire values are the server's, not Dart's naming: they must match what
/// the native SDKs send, and what the React Native bridge already exposes.
enum AppwinAutomationEvent {
  appOpen('app_open'),
  appBackground('app_background'),
  purchase('purchase'),
  customEvent('custom_event'),
  pushOptIn('push_opt_in'),
  sessionStart('session_start');

  const AppwinAutomationEvent(this.wireValue);

  final String wireValue;
}
