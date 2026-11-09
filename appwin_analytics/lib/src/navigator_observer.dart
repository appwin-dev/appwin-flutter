/// Automatic screen tracking from the app's [Navigator].
library;

import 'package:flutter/widgets.dart';

import '../appwin_analytics.dart';

/// Returns the screen name of [settings], or `null` to skip the route.
typedef AppwinScreenNameExtractor = String? Function(RouteSettings settings);

/// Reports the visible page route as a screen: the `screen_view` event, and
/// the screen names on the session replay timeline.
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [AppwinNavigatorObserver()],
/// )
/// ```
///
/// Only [PageRoute]s count: dialogs, sheets and popups leave the screen as
/// it was. A route without a name is skipped, so name your routes
/// (`RouteSettings(name: ...)`, named routes, or the router's own names) or
/// pass a [nameExtractor].
class AppwinNavigatorObserver extends NavigatorObserver {
  /// An observer that reports to [AppwinAnalytics.screen], or to [onScreen].
  AppwinNavigatorObserver({
    this.nameExtractor = defaultNameExtractor,
    this.onScreen,
  });

  /// Called with each screen name instead of [AppwinAnalytics.screen].
  final void Function(String name)? onScreen;

  /// Maps a route to its screen name.
  final AppwinScreenNameExtractor nameExtractor;

  /// The route's [RouteSettings.name].
  static String? defaultNameExtractor(RouteSettings settings) => settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _report(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // `Navigator.replace` can swap a route under the top one, which stays the screen.
    if (newRoute != null && newRoute.isCurrent) _report(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Popping a dialog does not change the screen under it.
    if (route is PageRoute && previousRoute != null) _report(previousRoute);
  }

  void _report(Route<dynamic> route) {
    if (route is! PageRoute) return;
    final name = nameExtractor(route.settings);
    if (name == null || name.isEmpty) return;
    final report = onScreen;
    report != null ? report(name) : AppwinAnalytics.instance.screen(name);
  }
}
