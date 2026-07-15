#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mel_spectrogram_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mel_spectrogram_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Sonogram and waveform visualization for Flutter'
  s.description      = <<-DESC
Sonogram and waveform visualization for Flutter.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Igor Kim' => 'igor.kim.dev@pm.me' }
  s.source           = { :path => '.' }
  s.source_files = [
    'mel_spectrogram_flutter/Sources/mel_spectrogram_flutter/**/*.{swift}',
    'mel_spectrogram_flutter/Sources/MelSpectrogramBridge/**/*.{h,m,mm,c,cc,cpp}'
  ]
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.frameworks = 'CoreAudio', 'AudioToolbox', 'AVFAudio'
  s.public_header_files = 'mel_spectrogram_flutter/Sources/MelSpectrogramBridge/MelSpectrogramBridge.h'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/mel_spectrogram_flutter/Sources/MelSpectrogramBridge"'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'mel_spectrogram_flutter_privacy' => ['mel_spectrogram_flutter/Sources/mel_spectrogram_flutter/PrivacyInfo.xcprivacy']}
end
