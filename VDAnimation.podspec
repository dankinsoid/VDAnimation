#
# Be sure to run `pod lib lint VDUIExtensions.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VDAnimation'
  s.version          = '1.50.0'
  s.summary          = 'A short description of VDAnimation.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/dankinsoid/VDAnimation'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Voidilov' => 'voidilov@gmail.com' }
  s.source           = { :git => 'https://github.com/dankinsoid/VDAnimation.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.6'
  s.source_files = 'Sources/VDAnimation/**/*'
  s.frameworks = 'UIKit'
  s.dependency 'VDTransition'
  s.dependency 'VDChain'
end
