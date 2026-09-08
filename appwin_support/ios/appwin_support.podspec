#
# CocoaPods podspec for the `appwin_support` Flutter wrapper.
#
# Firebase/FlutterFire pattern (ADR-0020): this plugin compiles **only** its
# glue file. The native `AppwinCore` and `AppwinSupport` SDKs are declared as
# CocoaPods dependencies, which makes them real Swift modules, so
# `import AppwinCore` and `import AppwinSupport` work normally.
#
# Development, in the Flutter host app's Podfile:
#
#   target 'Runner' do
#     pod 'AppwinCore',    :path => '../../../core/AppwinCore'
#     pod 'AppwinSupport', :path => '../../AppwinSupport'
#     # ...
#   end
#
# CocoaPods compiles Core and Support from source on every rebuild, so the
# feedback loop stays fast. No symlink, no duplicated sources, no single-module
# hack.
#
# Distribution (later): replace `:path` with `:git => 'https://…'`, or consume a
# published XCFramework.
#
Pod::Spec.new do |s|
  s.name             = 'appwin_support'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for the native iOS Appwin Support SDK.'
  s.description      = <<-DESC
Flutter plugin - a thin layer over the native AppwinCore and AppwinSupport SDKs
(ADR-0019, ADR-0020). No Flutter UI: it opens the native screens through a
method channel.
                       DESC
  s.homepage         = 'https://appwin.io'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Appwin Studio' }
  s.author           = { 'Appwin' => 'lesignobles.studio@gmail.com' }
  s.source           = { :path => '.' }

  # The Flutter glue code only. Core's and Support's native sources are **not**
  # compiled here - they arrive through the CocoaPods dependencies.
  s.source_files = 'appwin_support/Sources/appwin_support/**/*.{h,m,swift}'

  s.dependency 'Flutter'
  # `~> 0.1` is the exact range of `from: "0.1.x"` in Package.swift
  # (>= 0.1.0, < 1.0.0). Both manifests must describe the same dependencies:
  # a mismatch silently breaks one of the two build paths.
  s.dependency 'AppwinCore', '~> 0.1'
  s.dependency 'AppwinSupport', '~> 0.1'

  s.platform      = :ios, '16.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # Privacy manifest: to fill in if we ever use a required reason API.
  s.resource_bundles = {'appwin_support_privacy' => ['appwin_support/Sources/appwin_support/PrivacyInfo.xcprivacy']}
end
