#
# CocoaPods podspec for the `appwin_core` Flutter wrapper.
#
# The fallback of the Swift Package Manager manifest next to it
# (`appwin_core/Package.swift`), for the apps that have not turned SPM on. Both
# compile the same glue against the same native SDK, `AppwinCore`; only where
# the native sources come from differs (see below).
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

  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  glue = 'appwin_core/Sources/appwin_core/**/*.{h,m,swift}'
  privacy = { 'appwin_core_privacy' => ['appwin_core/Sources/appwin_core/PrivacyInfo.xcprivacy'] }

  # Where the native SDK comes from. CocoaPods trunk is read-only from
  # 2026-12-02: no Appwin pod can be published there any more, so a published
  # plugin never asks trunk for one.
  #
  # - Published (pub.dev): `sdk/scripts/release.mjs` copies the native sources
  #   of `appwin-ios`, and their podspec, into `appwin_core/Native/`, and this pod
  #   compiles them with its glue. The podspec is read rather than restated,
  #   so the files, frameworks and resources stay those of the iOS SDK.
  # - Monorepo: no `Native/` folder. The native pods are declared, and the
  #   app supplies them by `:path` (the showcase's Podfile).
  native_spec = File.join(__dir__, 'appwin_core', 'Native', 'AppwinCore.podspec')
  if File.exist?(native_spec)
    native = Pod::Specification.from_file(native_spec).attributes_hash
    in_native = ->(paths) { Array(paths).map { |path| "appwin_core/Native/#{path}" } }

    s.source_files = [glue, *in_native.(native['source_files'])]
    s.frameworks = native['frameworks']
    s.resource_bundles = privacy.merge(
      (native['resource_bundles'] || {}).transform_values(&in_native)
    )
    # One module, one language mode, and the glue's is 5 (as under SPM,
    # `swift-tools-version: 5.9`): Flutter's headers are not Sendable-clean.
    # The native sources are written for Swift 6, the stricter of the two,
    # and compile unchanged in mode 5.
    s.swift_version = '5.0'
    s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
      # `package` access is scoped by this name: the same as every Appwin
      # podspec and as `name:` in appwin-ios's Package.swift.
      'OTHER_SWIFT_FLAGS' => '$(inherited) -package-name Appwin',
    }
  else
    s.source_files = glue
    s.resource_bundles = privacy unless privacy.empty?
    # `>= X, < next major` is the CocoaPods spelling of SPM's `from: "X"`, so
    # both manifests describe the SAME range. Stamped from sdk/version.json by
    # scripts/release.mjs - do not hand-edit.
    s.dependency 'AppwinCore', '>= 1.2.0', '< 2.0.0'
    s.swift_version = '5.0'
    s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
    }
  end
end
