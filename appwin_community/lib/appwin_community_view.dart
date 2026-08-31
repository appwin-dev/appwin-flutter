import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
/// Call `AppwinCore.instance.configure(appId: ...)` before showing this widget:
/// without configuration the native view renders its error screen.
class AppwinCommunityView extends StatelessWidget {
  const AppwinCommunityView({super.key});

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
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const UiKitView(
          viewType: viewType,
          gestureRecognizers: _gestures,
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
