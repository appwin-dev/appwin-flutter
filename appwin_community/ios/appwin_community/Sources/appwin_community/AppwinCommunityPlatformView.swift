import Flutter
import UIKit
import AppwinCommunity

/// Factory for the native view embedded in the Flutter tree.
///
/// This is what lets Dart's `AppwinCommunityView` render the feed full page in a
/// tab, rather than presenting it modally.
class AppwinCommunityViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType = "appwin_community_view"

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        // Flutter creates and destroys platform views on the main thread, but
        // the protocol signature is `nonisolated`. `assumeIsolated` makes that
        // guarantee explicit: were it ever violated we trap here instead of
        // silently corrupting SwiftUI state.
        MainActor.assumeIsolated {
            AppwinCommunityPlatformView(frame: frame)
        }
    }

    /// Codec for `creationParams`. There are none today, but declaring it
    /// avoids changing the Dart-side signature the day we want to open the view
    /// directly on a group.
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Native view backed by a `UIHostingController`.
///
/// The controller is retained by the view: without that it would be released as
/// soon as it was created, and SwiftUI would lose its lifecycle - `task` would
/// never start and the stores would be deallocated under the UI.
///
/// The controller is deliberately **not** added as a child of a parent
/// `UIViewController`: Flutter exposes no suitable container for a
/// `PlatformView`, and the view hierarchy is enough for SwiftUI to work. The
/// trade-off - no propagation of controller lifecycle events - has no effect
/// here, since the SDK does not depend on them.
@MainActor
class AppwinCommunityPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIViewController

    init(frame: CGRect) {
        self.hostingController = AppwinCommunity.communityViewController()
        super.init()

        hostingController.view.frame = frame
        // The feed paints its own background from the studio theme, light or
        // dark: an opaque background here would mask the chosen colour at the
        // edges.
        hostingController.view.backgroundColor = .clear
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    // `view()` is declared `nonisolated` by the protocol; Flutter calls it on
    // the main thread, hence the same `assumeIsolated` as at creation.
    nonisolated func view() -> UIView {
        MainActor.assumeIsolated { hostingController.view }
    }
}
