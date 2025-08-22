Pod::Spec.new do |s|
  s.name             = 'Dimina'
  s.version          = '1.1.3'
  s.summary          = 'DiDi Mini Program Framework'
  
  s.description      = <<-DESC
                      DiDi Mini Program Framework for iOS platform.
                      DESC
                      
  s.homepage         = 'https://github.com/didi/dimina'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'Lehem' => 'lehemyang@gmail.com' }
  s.source           = { :git => 'https://github.com/didi/dimina.git', :tag => "v#{s.version}" }
  
  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'
  
  s.resource_bundles = {
    'DiminaAssets' => ['iOS/dimina/Resources/Assets.xcassets'],
    'DiminaJsSdk' => ['shared/jssdk/**/*']
  }
  
  s.frameworks = 'UIKit', 'Foundation'
  
  s.dependency 'MMKV', '2.2.2'
  s.dependency 'SSZipArchive', '2.4.3'
  s.dependency 'Alamofire', '5.10.2'
  
  # Core subspecs
  s.subspec 'App' do |app|
    app.source_files = 'iOS/dimina/DiminaKit/App/**/*.swift'
  end
  
  s.subspec 'Bundle' do |bundle|
    bundle.source_files = 'iOS/dimina/DiminaKit/Bundle/**/*.swift'
  end
  
  s.subspec 'Navigator' do |navigator|
    navigator.source_files = 'iOS/dimina/DiminaKit/Navigator/**/*.swift'
  end
  
  s.subspec 'Render' do |render|
    render.source_files = 'iOS/dimina/DiminaKit/Render/**/*.swift'
  end
  
  s.subspec 'Service' do |service|
    service.source_files = 'iOS/dimina/DiminaKit/Service/**/*.swift'
  end
  
  s.subspec 'Utils' do |utils|
    utils.source_files = 'iOS/dimina/DiminaKit/Utils/**/*.swift'
  end
  
  s.subspec 'Container' do |container|
    container.source_files = 'iOS/dimina/DiminaKit/Container/*.swift'
    
    container.subspec 'UI' do |ui|
      ui.source_files = 'iOS/dimina/DiminaKit/Container/UI/**/*.swift'
    end
    
    container.subspec 'API' do |api|
      api.source_files = 'iOS/dimina/DiminaKit/Container/Api/*.swift'
      
      api.subspec 'Base' do |base|
        base.source_files = 'iOS/dimina/DiminaKit/Container/Api/Base/**/*.swift'
      end
      
      api.subspec 'Device' do |device|
        device.source_files = 'iOS/dimina/DiminaKit/Container/Api/Device/**/*.swift'
      end
      
      api.subspec 'Media' do |media|
        media.source_files = 'iOS/dimina/DiminaKit/Container/Api/Media/**/*.swift'
      end
      
      api.subspec 'Network' do |network|
        network.source_files = 'iOS/dimina/DiminaKit/Container/Api/Network/**/*.swift'
      end
      
      api.subspec 'Route' do |route|
        route.source_files = 'iOS/dimina/DiminaKit/Container/Api/Route/**/*.swift'
      end
      
      api.subspec 'Storage' do |storage|
        storage.source_files = 'iOS/dimina/DiminaKit/Container/Api/Storage/**/*.swift'
      end
      
      api.subspec 'UI' do |ui_api|
        ui_api.source_files = 'iOS/dimina/DiminaKit/Container/Api/UI/**/*.swift'
      end
    end
    
    container.subspec 'Util' do |util|
      util.source_files = 'iOS/dimina/DiminaKit/Container/Util/**/*.swift'
    end
  end
end 