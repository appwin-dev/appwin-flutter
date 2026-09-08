#
# CocoaPods podspec for the `appwin_community` Flutter wrapper.
#
# Firebase/FlutterFire pattern (ADR-0020): this plugin compiles **only** its
# glue files. The native `AppwinCore` and `AppwinCommunity` SDKs are declared as
# CocoaPods dependencies, which makes them real Swift modules, so
# `import AppwinCore` and `import AppwinCommunity` work normally.
#
# Development, in the Flutter host app's Podfile:
#
#   target 'Runner' do
#     pod 'AppwinCore',      :path => '../../../core/AppwinCore'
#     pod 'AppwinCommunity', :path => '../../AppwinCommunity'
#     # ...
#   end
#
# CocoaPods compiles Core and Community from source on every rebuild, so the
# feedback loop stays fast. No symlink, no duplicated sources, no single-module
# hack.
#
# Distribution (later): replace `:path` with `:git => 'https://…'`, or consume a
# published XCFramework.
#
Pod::Spec.new do |s|
  s.name             = 'appwin_community'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for the native iOS Appwin Community SDK.'
  s.description      = <<-DESC
Flutter plugin - a thin layer over the native AppwinCore and AppwinCommunity
SDKs (ADR-0019, ADR-0020). No Flutter UI: it exposes the native feed through a
PlatformView embeddable in a tab, plus a method channel for identity.
                       DESC
  s.homepage         = 'https://appwin.io'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Appwin Studio' }
  s.author           = { 'Appwin' => 'lesignobles.studio@gmail.com' }
  s.source           = { :path => '.' }

  # The Flutter glue code only. Core's and Community's native sources are
  # **not** compiled here - they arrive through the CocoaPods dependencies.
  s.source_files = 'appwin_community/Sources/appwin_community/**/*.{h,m,swift}'

  s.dependency 'Flutter'
  # `~> 0.1` is the exact range of `from: "0.1.x"` in Package.swift
  # (>= 0.1.0, < 1.0.0). Both manifests must describe the same dependencies:
  # a mismatch silently breaks one of the two build paths.
  s.dependency 'AppwinCore', '~> 0.1'
  s.dependency 'AppwinCommunity', '~> 0.1'

  s.platform      = :ios, '16.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
