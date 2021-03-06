version = '0.0.6'

Pod::Spec.new do |s|
  s.name                   = 'ImageUtils'
  s.version                = version
  s.homepage               = 'https://github.com/jonbrennecke/image-utils'
  s.author                 = 'Jon Brennecke'
  s.platforms              = { :ios => '13.2', :macos => '10.15' }
  s.source                 = { :git => 'https://github.com/jonbrennecke/image-utils.git', :tag => "v#{version}" }
  s.cocoapods_version      = '>= 1.2.0'
  s.license                = 'MIT'
  s.summary                = 'Swift library for rendering videos with effects'
  s.source_files           = 'source/**/*.swift'
  s.swift_version          = '5'
  s.ios.deployment_target  = '13.2'
  s.osx.deployment_target  = '10.15'
end
