import Flutter
import UIKit
import AppwinCommunity

/// Factory for the native view embedded in the Flutter tree.
///
/// This is what lets Dart's `AppwinCommunityView` render the feed full page in a
/// tab, rather than presenting it modally.
class AppwinCommunityViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType = "appwin_community_view"

    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

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
            AppwinCommunityPlatformView(
                frame: frame,
                profileEditing: ProfileEditingRequests(arguments: args, viewId: viewId, channel: channel)
            )
        }
    }

    /// Codec for `creationParams`: which profile editing handlers the Dart
    /// widget has.
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

/**
 Container that hosts Community's `UIHostingController` inside a Flutter
 `UiKitView`.

 Same contract as RN's `AppwinHostingView`: the hosting controller must be a
 child of `FlutterViewController`. Returning the hosting view alone (no
 `addChild`) breaks safe-area / keyboard / sheet presenter propagation, so the
 feed draws under the status bar and home indicator.
 */
@MainActor
final class AppwinCommunityHostingView: UIView {
    private let hostingController: UIViewController
    private var didAttachToParent = false

    init(frame: CGRect, hostingController: UIViewController) {
        self.hostingController = hostingController
        super.init(frame: frame)

        hostingController.view.backgroundColor = .clear
        // Community is light-only; lock the embedded VC so a dark host does not
        // leak into system sheets presented from SwiftUI.
        hostingController.overrideUserInterfaceStyle = .light
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        attachIfNeeded()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        // Flutter may parent the view before the window/responder chain is
        // ready; retry so we still get addChild once FlutterViewController
        // is reachable.
        if window != nil {
            attachIfNeeded()
        }
    }

    override func removeFromSuperview() {
        detachFromParent()
        super.removeFromSuperview()
    }

    private func attachIfNeeded() {
        if hostingController.view.superview !== self {
            hostingController.view.removeFromSuperview()
            addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }

        if hostingController.parent == nil, let parent = enclosingViewController {
            parent.addChild(hostingController)
            hostingController.didMove(toParent: parent)
            didAttachToParent = true
        }
    }

    private func detachFromParent() {
        if hostingController.parent != nil {
            hostingController.willMove(toParent: nil)
            hostingController.removeFromParent()
        }
        hostingController.view.removeFromSuperview()
        didAttachToParent = false
    }

    private var enclosingViewController: UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let controller = current as? UIViewController { return controller }
            responder = current.next
        }
        return nil
    }
}

/// Flutter `PlatformView` wrapper around [AppwinCommunityHostingView].
@MainActor
class AppwinCommunityPlatformView: NSObject, FlutterPlatformView {
    private let container: AppwinCommunityHostingView

    init(frame: CGRect, profileEditing: ProfileEditingRequests) {
        let host = AppwinCommunity.communityViewController(
            onEditProfile: profileEditing.onEditProfile,
            onEditProfilePhoto: profileEditing.onEditProfilePhoto,
            onEditProfileName: profileEditing.onEditProfileName
        )
        self.container = AppwinCommunityHostingView(frame: frame, hostingController: host)
        super.init()
    }

    // `view()` is declared `nonisolated` by the protocol; Flutter calls it on
    // the main thread, hence the same `assumeIsolated` as at creation.
    nonisolated func view() -> UIView {
        MainActor.assumeIsolated { container }
    }
}
