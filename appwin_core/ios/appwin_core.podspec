#
# CocoaPods podspec for the `appwin_core` Flutter wrapper.
#
# Firebase/FlutterFire pattern (ADR-0020): this plugin compiles **only** its
# glue file. The native `AppwinCore` SDK is declared as a CocoaPods dependency,
# so `import AppwinCore` works normally.
#
# Development, in the Flutter host app's Podfile:
#
#   target 'Runner' do
#     pod 'AppwinCore', :path => '../../../core/AppwinCore'
#   end
#
Pod::Spec.new do |s|
  s.name             = 'appwin_core'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for the native Appwin foundation (identity, session, networking).'
  s.description      = <<-DESC
Flutter plugin - a thin layer over the native AppwinCore SDK (ADR-0019,
ADR-0020). No UI: it carries the single `configure`, the device identity and
the session shared by every Appwin product.
                       DESC
  s.homepage         = 'https://appwin.io'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Appwin Studio' }
  s.author           = { 'Appwin' => 'lesignobles.studio@gmail.com' }
  s.source           = { :path => '.' }

  # The Flutter glue code only. Core's native sources are **not** compiled
  # here - they arrive through the CocoaPods dependency.
  s.source_files = 'appwin_core/Sources/appwin_core/**/*.{h,m,swift}'

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

  s.platform      = :ios, '16.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.resource_bundles = {'appwin_core_privacy' => ['appwin_core/Sources/appwin_core/PrivacyInfo.xcprivacy']}
end
