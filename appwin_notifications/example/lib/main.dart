import 'package:flutter/material.dart';
import 'package:appwin_notifications/appwin_notifications.dart';

/// Minimal Appwin Notifications integration: configure, initialise, sync.
///
/// Replace `your-app-id` with the App ID from your dashboard, under
/// Settings → SDK.
const appId = 'your-app-id';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. The foundation. One call, whatever the number of products.
  await AppwinCore.instance.configure(appId: appId);

  // 2. Notifications itself. Do this before asking the system for push
  //    permission: the user grants it once, and neither OS asks twice.
  final notifications = await AppwinNotifications.instance.initialize();
  debugPrint('Appwin Notifications: $notifications');

  // 3. Report the app open and collect what is pending, in one round trip.
  final pending = notifications.isReady
      ? await AppwinNotifications.instance.syncOnAppOpen()
      : <AppwinInAppMessage>[];

  runApp(ExampleApp(ready: notifications.isReady, messages: pending));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.ready, required this.messages});

  final bool ready;

  /// This product draws nothing: the messages are yours to render.
  final List<AppwinInAppMessage> messages;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Appwin Notifications')),
        body: !ready
            ? const Center(
                child: Text('Notifications are not available for this app.'),
              )
            : messages.isEmpty
                ? const Center(child: Text('No message pending.'))
                : ListView(
                    children: [
                      for (final message in messages)
                        ListTile(
                          title: Text(message.content.title ?? 'Untitled'),
                          subtitle: Text(message.content.body ?? ''),
                          // Reporting is what gives a campaign its read rate,
                          // and what an automation waiting on "opened" needs.
                          onTap: () => AppwinNotifications.instance.track(
                            deliveryId: message.deliveryId,
                            event: AppwinTrackEvent.opened,
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
