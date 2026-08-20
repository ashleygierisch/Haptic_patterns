#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint haptic_patterns.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'haptic_patterns'
  s.version          = '0.0.1'
  s.summary          = 'Composable haptic feedback patterns for Flutter.'
  s.description      = <<-DESC
Composable haptic feedback patterns for Flutter -- chain, repeat, and
compose taps, buzzes, and custom sequences on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/modexanderson/haptic_patterns'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mordecai Shekwogaza' => 'mordecai.a.d@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'haptic_patterns_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
