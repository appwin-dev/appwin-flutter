import 'package:flutter/material.dart';
import 'package:appwin_community/appwin_community.dart';

/// Minimal Appwin Community integration: configure, initialise, embed.
///
/// Replace `your-app-id` with the App ID from your dashboard, under
/// Settings → SDK.
const appId = 'your-app-id';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. The foundation. One call, whatever the number of products.
  await AppwinCore.instance.configure(appId: appId);

  // 2. Before initialize(), so the tap that launched the app reaches it. The
  //    feed is this app's only screen, so opening the post is enough; an app
  //    with tabs would select its Community tab first.
  AppwinCommunity.instance.onNotificationTap = (target) {
    AppwinCommunity.instance.openPost(target.postId, commentId: target.commentId);
  };

  // 3. Community itself. It answers whether this app may open it.
  final community = await AppwinCommunity.instance.initialize();
  debugPrint('Appwin Community: $community');

  AppwinCommunity.instance.events.listen((event) {
    debugPrint('Appwin Community event: $event');
  });

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Appwin Community'),
          actions: [
            StreamBuilder<int>(
              stream: AppwinCommunity.instance.unreadNotificationCountStream,
              builder: (context, snapshot) => Padding(
                padding: const EdgeInsets.all(16),
                child: Badge.count(
                  count: snapshot.data ?? 0,
                  isLabelVisible: (snapshot.data ?? 0) > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            ),
          ],
        ),
        // The feed fills the space it is given and has no close button: the
        // surrounding screen is the way out. It follows the verdict live, and
        // shows the SDK's placeholder while Community is not ready.
        body: const AppwinCommunityView(),
      ),
    );
  }
}
