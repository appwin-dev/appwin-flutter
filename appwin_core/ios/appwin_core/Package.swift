// swift-tools-version: 5.9

import PackageDescription

/**
 Manifeste Swift Package Manager du plugin Flutter.

 Depuis Flutter 3.44, SPM est le gestionnaire de dépendances iOS par défaut.
 Ce manifeste vit **à côté** du podspec, pas à sa place : Flutter retombe sur
 CocoaPods pour les projets qui n'ont pas migré, et un plugin qui ne
 fournirait que l'un des deux serait inutilisable pour la moitié du parc.

 Les deux manifestes doivent décrire les mêmes sources et les mêmes
 dépendances. Un décalage casse silencieusement un des deux chemins de build,
 et ce n'est visible que chez le studio qui a choisi l'autre.
 */
let package = Package(
  name: "appwin_core",
  platforms: [
    .iOS("16.0")
  ],
  products: [
    // The hyphen is not a choice: Flutter requires the plugin name's
    // underscores to become hyphens in the product name.
    .library(name: "appwin-core", targets: ["appwin_core"])
  ],
  dependencies: [
    // Provided by the Flutter tooling at build time.
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    // The native SDK lives in the same monorepo. Relative path during
    // development; the release script rewrites it into a tagged git URL
    // (cf. sdk/scripts/release-swift-packages.mjs).
    .package(url: "https://github.com/appwin-dev/appwin-ios.git", from: "0.3.0"),
  ],
  targets: [
    .target(
      name: "appwin_core",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "AppwinCore", package: "appwin-ios"),
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ]
    )
  ]
)
