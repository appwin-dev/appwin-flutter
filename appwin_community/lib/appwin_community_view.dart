/// The native community feed, as a Flutter widget.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'src/community_verdict.dart';

/// Builds your own UI for when Community is not ready, from the verdict that
/// closed it. See [AppwinCommunityView.unavailableBuilder].
typedef AppwinCommunityUnavailableBuilder =
    Widget Function(BuildContext context, AppwinInitResult result);

/// The community feed, rendered natively, embedded in the Flutter tree.
///
/// This is the expected integration: a tab of the main bar showing the
/// community full page.
///
/// ```dart
/// Scaffold(
///   body: IndexedStack(
///     index: _index,
///     children: const [HomePage(), AppwinCommunityView(), ProfilePage()],
///   ),
///   bottomNavigationBar: ...,
/// )
/// ```
///
/// Call `AppwinCore.instance.configure(appId: ...)` and
/// `AppwinCommunity.instance.initialize()` before showing this widget.
///
/// While Community is not ready the native view shows a "coming soon"
/// placeholder (with a diagnosis card in debug builds), and swaps to the feed
/// by itself when the verdict changes. Pass [unavailableBuilder] to show your
/// own UI instead.
class AppwinCommunityView extends StatelessWidget {
  /// Creates the feed. It sizes itself to its parent, so give it a slot with
  /// real constraints: a tab body, not an unbounded column.
  const AppwinCommunityView({super.key, this.unavailableBuilder});

  /// Your own UI for when Community is not ready, in place of the SDK's
  /// placeholder.
  ///
  /// Used only once `AppwinCommunity.instance.initialize()` has answered and
  /// the answer is not ready; before that, the native view shows its own
  /// placeholder. The widget follows the verdict live: it switches between
  /// your UI and the feed as the verdict changes.
  ///
  /// ```dart
  /// AppwinCommunityView(
  ///   unavailableBuilder: (context, result) => const ComingSoon(),
  /// )
  /// ```
  final AppwinCommunityUnavailableBuilder? unavailableBuilder;

  /// Identifier of the factory registered natively. The same on both
  /// plateformes.
  static const String viewType = 'appwin_community_view';

  /// The feed scrolls, taps and opens sheets: every gesture must reach the
  /// native view. Without this, Flutter intercepts the vertical drag and the
  /// feed looks frozen.
  static const Set<Factory<OneSequenceGestureRecognizer>> _gestures = {
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  @override
  Widget build(BuildContext context) {
    final builder = unavailableBuilder;
    // Without a builder the native view follows the verdict itself; watching
    // it here too would only rebuild for nothing.
    if (builder == null) return const _NativeCommunityView();
    return ValueListenableBuilder<AppwinInitResult?>(
      valueListenable: communityVerdict,
      builder: (context, result, nativeView) {
        if (result != null && !result.isReady) return builder(context, result);
        return nativeView!;
      },
      child: const _NativeCommunityView(),
    );
  }
}

class _NativeCommunityView extends StatelessWidget {
  const _NativeCommunityView();

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const UiKitView(
          viewType: AppwinCommunityView.viewType,
          gestureRecognizers: AppwinCommunityView._gestures,
          creationParams: <String, dynamic>{},
          creationParamsCodec: StandardMessageCodec(),
        );
      case TargetPlatform.android:
        return const _AndroidCommunityView();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        // The native SDK does not exist on these platforms, so render a neutral
        // screen rather than throwing, keeping a multiplatform app launchable
        // during mobile development.
        return const _UnsupportedPlatformPlaceholder();
    }
  }
}

/// Vue Android en **composition hybride**.
///
/// `AndroidView` would go through a virtual display, where text input is
/// notoirement bancale : le fil a un champ de publication et un champ de
/// comment, so that is disqualifying. Hybrid composition renders the native view
/// in the app's hierarchy, keyboard and accessibility included.
class _AndroidCommunityView extends StatelessWidget {
  const _AndroidCommunityView();

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: AppwinCommunityView.viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: AppwinCommunityView._gestures,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: AppwinCommunityView.viewType,
            layoutDirection: Directionality.of(context),
            creationParams: const <String, dynamic>{},
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}

class _UnsupportedPlatformPlaceholder extends StatelessWidget {
  const _UnsupportedPlatformPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF9FAFC),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Appwin Community runs on iOS and Android.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64758B), fontSize: 14),
          ),
        ),
      ),
    );
  }
}
