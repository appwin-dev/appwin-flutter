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

  // 2. Community itself. It answers whether this app may open it.
  final community = await AppwinCommunity.instance.initialize();
  debugPrint('Appwin Community: $community');

  runApp(ExampleApp(communityReady: community.isReady));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.communityReady});

  /// 3. Your app decides what to show. The SDK cannot remove your tab.
  final bool communityReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Appwin Community')),
        // The feed fills the space it is given and has no close button: the
        // surrounding screen is the way out.
        body: communityReady
            ? const AppwinCommunityView()
            : const Center(child: Text('Community is not available for this app.')),
      ),
    );
  }
}
