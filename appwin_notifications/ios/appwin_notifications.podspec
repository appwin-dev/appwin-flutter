#
# CocoaPods podspec for the `appwin_notifications` Flutter wrapper.
#
# Firebase/FlutterFire pattern (ADR-0020): this plugin compiles **only** its
# glue file. The native `AppwinCore` and `AppwinNotifications` SDKs are declared
# as CocoaPods dependencies, which makes them real Swift modules, so
# `import AppwinNotifications` works normally.
#
# Development: `pod 'AppwinNotifications', :path => '.../sdk/appwin-ios'` in the
# Podfile, and the same for AppwinCore - the four podspecs share that folder.
#
Pod::Spec.new do |s|
  s.name             = 'appwin_notifications'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for the native iOS Appwin Notifications SDK.'
  s.description      = <<-DESC
Flutter plugin - a thin layer over the native AppwinNotifications SDK. No UI:
it registers the push token, reports the events that trigger automations, and
returns the in-app messages for the app to render.
                       DESC
  s.homepage         = 'https://appwin.io'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Appwin Studio' }
  s.author           = { 'Appwin' => 'lesignobles.studio@gmail.com' }
  s.source           = { :path => '.' }

  s.source_files = 'appwin_notifications/Sources/appwin_notifications/**/*.{h,m,swift}'

  s.dependency 'Flutter'
  # `~> 0.1` is the exact range of `from: "0.1.x"` in Package.swift
  # (>= 0.1.0, < 1.0.0). Both manifests must describe the same dependencies:
  # a mismatch silently breaks one of the two build paths.
  s.dependency 'AppwinCore', '~> 0.1'
  s.dependency 'AppwinNotifications', '~> 0.1'

  s.platform      = :ios, '16.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
