// swift-tools-version: 5.9

import PackageDescription

/**
 Swift Package Manager manifest of the Flutter plugin.

 It lives **next to** the podspec, not instead of it: Flutter falls back to
 CocoaPods for projects that have not migrated.

 Both manifests must describe the same sources and the same dependencies - a
 mismatch silently breaks one of the two build paths, and only for the studios
 that picked that one.
 */
let package = Package(
  name: "appwin_notifications",
  platforms: [
    .iOS("16.0")
  ],
  products: [
    // The hyphen is not a choice: Flutter requires the plugin name's
    // underscores to become hyphens in the product name.
    .library(name: "appwin-notifications", targets: ["appwin_notifications"])
  ],
  dependencies: [
    // Provided by the Flutter tooling at build time.
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    // The native SDK lives in the same monorepo. Relative path during
    // development; the release script rewrites it into a tagged git URL.
    .package(url: "https://github.com/appwin-dev/appwin-ios.git", from: "0.2.0"),
  ],
  targets: [
    .target(
      name: "appwin_notifications",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "AppwinCore", package: "appwin-ios"),
        .product(name: "AppwinNotifications", package: "appwin-ios"),
      ]
    )
  ]
)
