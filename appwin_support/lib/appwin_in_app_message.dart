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
  });

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
