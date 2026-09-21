#
#  Be sure to run `pod spec lint NvMaterialLibrary.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "NvMaterialLibrary"
  spec.version      = "0.0.1"
  spec.summary      = "the network tools"
  spec.description  = "the network for package download tools"
  spec.homepage     = "https://github.com"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "meishe" => "meicamapp@meishesdk.com" }
  spec.source       = { :git => "https://github.com/bcinnovation/NvMaterialLibrary.git", :tag => "#{spec.version}" }

  spec.platform              = :ios
  spec.static_framework      = false
  spec.ios.deployment_target = '12.0'
  spec.ios.requires_arc      = true
  spec.ios.pod_target_xcconfig   = {
    'SWIFT_VERSION'                    => '5.0',
    'ENABLE_BITCODE'                   => 'NO',
    'DEFINES_MODULE'                   => 'YES',
    'BUILD_LIBRARIES_FOR_DISTRIBUTION' => 'YES'
  }

  spec.resources = 'NvMaterialLibrary/NvMaterialLibrary/Resources/*'
  spec.subspec 'SourceFiles' do |s|
    s.source_files = 'NvMaterialLibrary/NvMaterialLibrary/SourceFiles/**/*'
  end
  
  spec.ios.dependency     'NvEffectFrameworks'
  spec.ios.dependency     'Zip'
  spec.ios.dependency     'SDWebImageWebPCoder'

end
