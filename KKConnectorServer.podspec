Pod::Spec.new do |spec|
  spec.name         = 'KKConnectorServer'
  spec.version      = '1.0.7'
  spec.license      = 'MIT'
  spec.summary      = 'Transfer data between macOS ans iOS'
  spec.homepage     = 'https://github.com/hughkli/KKConnector.git'
  spec.author       = 'Li Kai'
  spec.source           = { :git => 'https://github.com/hughkli/KKConnector.git', :tag => spec.version.to_s }
  spec.requires_arc = true
  spec.source_files = 'Shared/**/*', 'Server/**/*'
  spec.ios.deployment_target  = '9.0'
  spec.macos.deployment_target  = '10.14'
end
