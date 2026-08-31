// swift-tools-version: 5.9

import PackageDescription

/**
 Manifeste Swift Package Manager du plugin Flutter.

 Depuis Flutter 3.44, SPM est le gestionnaire de dépendances iOS par défaut.
 Ce manifeste vit **à côté** du podspec, pas à sa place : Flutter retombe sur
 CocoaPods pour les projets qui n'ont pas migré.

 Les deux manifestes doivent décrire les mêmes sources et les mêmes
 dépendances - un décalage casse silencieusement un des deux chemins de build.
 */
let package = Package(
  name: "appwin_community",
  platforms: [
    .iOS("16.0")
  ],
  products: [
    .library(name: "appwin-community", targets: ["appwin_community"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    .package(url: "https://github.com/appwin-dev/appwin-ios.git", from: "0.2.0"),
  ],
  targets: [
    .target(
      name: "appwin_community",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "AppwinCore", package: "appwin-ios"),
        .product(name: "AppwinCommunity", package: "appwin-ios"),
      ]
    )
  ]
)
