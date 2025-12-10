#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint quick_login_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'quick_login_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for the CMCC quick login SDK.'
  s.description      = <<-DESC
Wraps the CMCC one-click login native SDK (Android/iOS) and exposes a simple Dart API to open the native authorization page and fetch login tokens.
                       DESC
  s.homepage         = 'https://example.com/quick_login_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'quick_login_flutter' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.vendored_frameworks = 'Frameworks/TYRZUISDK.xcframework'
  s.resources = ['Resources/TYRZResource.bundle', 'Resources/PrivacyInfo.xcprivacy', 'Resources/check_box_selected.png', 'Resources/check_box_unselected.png', 'Resources/close.png', 'Resources/common_toast_background.png']
  s.frameworks = ['UIKit', 'SystemConfiguration', 'WebKit', 'CoreTelephony']

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
