// One import: `appwin_community` re-exports the foundation, so `AppwinCore`
// comes with the feed.
import 'package:appwin_community/appwin_community.dart';
import 'package:flutter/material.dart';

/// Demo app for the Appwin Community SDK.
///
/// Reproduces the expected integration: a tab of the main bar that
/// rend le fil en pleine page.
///
/// To point at a local API, change `_baseUrl` below. On the simulator
/// `localhost` works; on a physical device you need your machine's IP on the
/// local network, since the phone does not know your localhost.
void main() {
  runApp(const ExampleApp());
}

/// Replace with your project's app id (dashboard, Community, SDK).
const String _appId = 'c4a3353e-246e-44da-9220-cd8bde210563';

/// `null` en prod. En dev : 'http://localhost:3000' (simulateur) ou
/// 'http://192.168.1.X:3000' (device physique).
///
/// Deliberately nullable: this is the line you change to go to production, and
/// keeping it nullable avoids having to change the type too.
// ignore: unnecessary_nullable_for_final_variable_declarations
const String? _baseUrl = 'http://192.168.8.114:3000';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appwin Community',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3373F2)),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _status = 'Initialisation…';
  int _unread = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // One configure, carried by the foundation: it covers Community as it
      // does any other Appwin product wired into the same app.
      await AppwinCore.instance.configure(appId: _appId, baseUrl: _baseUrl);

      // Optional: attach the member to YOUR app's user, then push what you
      // already know about them. Without this they stay anonymous and can name
      // themselves from inside the SDK.
      // await AppwinCommunity.instance.login(externalId: 'user-42');
      // await AppwinCommunity.instance.setUser(nickname: 'Mamy42');

      final unread = await AppwinCommunity.instance.unreadNotificationCount();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _unread = unread;
        _status = 'SDK prêt';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Échec : $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `IndexedStack` et non un remplacement de widget : la vue native garde
      // its state (scroll position, loaded pages) when switching tabs and
      // coming back.
      body: IndexedStack(
        index: _index,
        children: [
          _PlaceholderTab(status: _status, onPresentModal: _presentModal),
          // The feed, full page. Nothing else to do.
          _ready
              ? const AppwinCommunityView()
              : const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Boutique',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              child: const Icon(Icons.forum_outlined),
            ),
            selectedIcon: const Icon(Icons.forum),
            label: 'Communauté',
          ),
        ],
      ),
    );
  }

  Future<void> _presentModal() async {
    await AppwinCommunity.instance.presentCommunity();
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.status, required this.onPresentModal});

  final String status;
  final VoidCallback onPresentModal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ton app',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text(
                "L'onglet Communauté rend le SDK natif en pleine page.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onPresentModal,
                child: const Text('Ouvrir en plein écran (modal)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
