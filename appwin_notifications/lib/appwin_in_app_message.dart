/// An in-app message the server has queued for this device.
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

class AppwinInAppContent {
  const AppwinInAppContent({
    this.title,
    this.body,
    this.imageUrl,
    this.deeplink,
    this.buttons,
  });

  final String? title;
  final String? body;
  final String? imageUrl;
  final String? deeplink;
  final List<AppwinInAppButton>? buttons;

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

class AppwinInAppButton {
  const AppwinInAppButton({
    required this.label,
    required this.action,
    this.url,
  });

  final String label;
  final String action;
  final String? url;

  factory AppwinInAppButton.fromMap(Map<dynamic, dynamic> map) {
    return AppwinInAppButton(
      label: map['label'] as String,
      action: map['action'] as String,
      url: map['url'] as String?,
    );
  }
}

enum AppwinTrackEvent { opened, clicked, dismissed }

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
