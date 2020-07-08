platform :osx, '10.10'
use_frameworks!

target 'Criollo Web' do
    pod 'Criollo',		        '1.0.1'
    pod 'CSFeedKit',          '0.2.1'
    pod 'CSOddFormatters',    '1.1.1'
    pod 'CSSystemInfoHelper', '1.4.2'
    pod 'JSONModel',          '1.8.0'
    pod 'JWT',                '3.0.0-beta.12',  :inhibit_warnings => true
    pod 'MMMarkdown',         '0.5.5',          :inhibit_warnings => true
    pod 'Realm',              '3.3.2',          :inhibit_warnings => true
    pod 'STTwitter',          '0.2.6',          :inhibit_warnings => true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete("ARCHS")
    end
  end
end

