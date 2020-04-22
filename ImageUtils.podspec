version = '0.0.4'

Pod::Spec.new do |s|
  s.source                 = { :git => 'https://github.com/jonbrennecke/image-utils.git', :tag => "v#{version}" }
  s.name                   = 'ImageUtils'
  s.version                = version
  s.homepage               = 'https://github.com/jonbrennecke/image-utils'
  s.author                 = 'Jon Brennecke'
  s.platforms              = { :ios => '11.0' }
  s.source                 = source
  s.cocoapods_version      = '>= 1.2.0'
  s.license                = 'MIT'
  s.summary                = 'Swift library for rendering videos with effects'
  s.source_files           = 'source/**/*.swift'
  s.swift_version          = '5'
end
