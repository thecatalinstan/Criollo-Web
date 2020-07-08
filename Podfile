platform :osx, '10.10'
use_frameworks!

target 'Criollo Web' do
    pod 'Criollo',		        '1.0.1'
    pod 'CSFeedKit',          '0.2.1'
    pod 'CSOddFormatters',    '1.1.1'
    pod 'CSSystemInfoHelper', '1.4.2'
    pod 'JSONModel',          '1.8.0'
    pod 'JWT',                '3.0.0-beta.12'
    pod 'MMMarkdown',         '0.5.5'
    pod 'Realm',              '3.3.2',          :inhibit_warnings => true
    pod 'STTwitter',          '0.2.6'
end

post_install do |installer|
  # Change settings per build config
  installer.pods_project.targets.each do |target|
    
    if target.name == "JWT"
      `git apply Patches/JWT-3.0.0-beta.12.diff 2> /dev/null`
    end
    
    if target.name == "MMMarkdown"
      `git apply Patches/MMMarkdown-0.5.5.diff 2> /dev/null`
    end
    
    # Change settings per target, per build configuration
    target.build_configurations.each do |config|
      
      # Xcode 11.5 recommended settings
      config.build_settings.delete("ARCHS")
      
      if target.name == "JWT"
        config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "10.10"
        config.build_settings["WARNING_CFLAGS"] = ['$(inherited)', '-Wno-deprecated', '-Wno-deprecated-implementations']
      end
      
      if target.name == "MMMarkdown"
        config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "10.10"
      end
      
      if target.name == "STTwitter"
        config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "10.10"
      end
      
    end
  end
end

