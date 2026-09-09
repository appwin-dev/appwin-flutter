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
  # `>= X, < next major` is the CocoaPods spelling of SPM's `from: "X"`. Not
  # `~> X.Y`, which would be narrower on the minor, and not `~> X` either, which
  # is wider on the patch: both manifests must describe the SAME range or one of
  # the two build paths resolves a version the other never sees.
  #
  # Stamped from sdk/version.json by scripts/release.mjs - do not hand-edit. It
  # sat at `~> 0.1` through 0.2.0 to 0.5.0, and since an old Podfile.lock still
  # satisfies that range, `pod install` upgraded nothing and apps failed at Swift
  # compile time on a symbol their pinned Core did not have.
  s.dependency 'AppwinCore', '>= 0.5.1', '< 1.0.0'
  s.dependency 'AppwinNotifications', '>= 0.5.1', '< 1.0.0'

  s.platform      = :ios, '16.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
