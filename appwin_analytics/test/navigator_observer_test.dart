import 'package:appwin_analytics/appwin_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> screens;
  late GlobalKey<NavigatorState> navigator;

  Future<void> pumpApp(WidgetTester tester, {AppwinScreenNameExtractor? extractor}) async {
    screens = [];
    navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      initialRoute: '/',
      routes: {
        '/': (_) => const Text('home'),
        '/detail': (_) => const Text('detail'),
        '/other': (_) => const Text('other'),
      },
      navigatorObservers: [
        AppwinNavigatorObserver(
          onScreen: screens.add,
          nameExtractor: extractor ?? AppwinNavigatorObserver.defaultNameExtractor,
        ),
      ],
    ));
  }

  testWidgets('reports pushed, replaced and uncovered pages', (tester) async {
    await pumpApp(tester);
    navigator.currentState!.pushNamed('/detail');
    await tester.pumpAndSettle();
    navigator.currentState!.pushReplacementNamed('/other');
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(screens, ['/', '/detail', '/other', '/']);
  });

  testWidgets('dialogs leave the screen as it was', (tester) async {
    await pumpApp(tester);
    showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const Text('dialog'),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(screens, ['/']);
  });

  testWidgets('unnamed routes are skipped, extractor renames', (tester) async {
    await pumpApp(tester, extractor: (s) => s.name == '/' ? 'Home' : null);
    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('x')));
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed('/detail');
    await tester.pumpAndSettle();

    expect(screens, ['Home']);
  });

  testWidgets('a route replaced under the top one is not a screen', (tester) async {
    await pumpApp(tester);
    final below = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/below'),
      builder: (_) => const Text('below'),
    );
    navigator.currentState!.push(below);
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed('/detail');
    await tester.pumpAndSettle();
    navigator.currentState!.replace(
      oldRoute: below,
      newRoute: MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/replaced'),
        builder: (_) => const Text('replaced'),
      ),
    );
    await tester.pumpAndSettle();

    expect(screens, ['/', '/below', '/detail']);
  });
}
