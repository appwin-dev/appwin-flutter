import 'package:flutter/material.dart';
import 'package:appwin_support/appwin_support.dart';

/// Minimal Appwin Support integration: configure, initialise, open.
///
/// Replace `your-app-id` with the App ID from your dashboard, under
/// Settings → SDK.
const appId = 'your-app-id';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. The foundation. One call, whatever the number of products.
  await AppwinCore.instance.configure(appId: appId);

  // 2. Support itself. It answers whether this app may open it.
  final support = await AppwinSupport.instance.initialize();
  debugPrint('Appwin Support: $support');

  runApp(ExampleApp(supportReady: support.isReady));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.supportReady});

  /// 3. Your app decides what to show. The SDK cannot hide your button.
  final bool supportReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Appwin Support')),
        body: Center(
          child: supportReady
              ? ElevatedButton(
                  onPressed: AppwinSupport.instance.presentMessenger,
                  child: const Text('Open support'),
                )
              : const Text('Support is not available for this app.'),
        ),
      ),
    );
  }
}
