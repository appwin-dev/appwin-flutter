import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/material.dart';

/// Minimal `appwin_core` integration: configure once, then identify a user.
///
/// Core is the foundation the Appwin products share, not a product itself:
/// there is no UI to open here. Add `appwin_support`, `appwin_community` or
/// `appwin_notifications` for that, and they will reuse the identity and the
/// session set up below.
///
/// Replace `your-app-id` with the App ID from your dashboard, under
/// Settings then SDK.
const appId = 'your-app-id';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One call, whatever the number of products. It returns without waiting for
  // the network: the session opens in the background.
  await AppwinCore.instance.configure(appId: appId);

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _deviceId = 'loading...';
  String _status = 'Anonymous';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    // Stable across launches, and across reinstalls on iOS. Null until
    // configure() has run.
    final id = await AppwinCore.instance.deviceId();
    if (!mounted) return;
    setState(() => _deviceId = id ?? 'not configured');
  }

  /// Ties the device to one of your own users.
  ///
  /// The id is yours, the one in your database. bootstrapSession() follows so
  /// the session already open carries the new identity.
  Future<void> _signIn() async {
    await AppwinCore.instance.identify(externalId: 'user-42');
    await AppwinCore.instance.bootstrapSession();
    if (!mounted) return;
    setState(() => _status = 'Identified as user-42');
  }

  /// Call this when the user signs out of YOUR app, or the next person on the
  /// device inherits their identity.
  Future<void> _signOut() async {
    await AppwinCore.instance.signOut();
    if (!mounted) return;
    setState(() => _status = 'Anonymous');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appwin Core')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Device: $_deviceId'),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _signIn,
              child: const Text('Identify user'),
            ),
            TextButton(onPressed: _signOut, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}
