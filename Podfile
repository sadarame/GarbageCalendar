# Uncomment the next line to define a global platform for your project
platform :ios, '17.0'

target 'GarbageCalendar' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

#  pod 'FSCalendar'

#  pod 'RealmSwift'
  
  pod 'Firebase/Auth', '~> 10.29.0'
  pod 'Firebase/Functions', '~> 10.29.0'
  pod 'Firebase/AppCheck', '~> 10.29.0'
  pod 'Firebase/Analytics', '~> 10.29.0'
  
  pod 'Firebase/Messaging', '~> 10.29.0'
  
  pod 'FirebaseAnalytics', '~> 10.29.0'
  
  pod 'FirebaseMessaging', '~> 10.29.0'
  
  pod 'Google-Mobile-Ads-SDK', '~> 11.13.0'

  # Pods for GarbageCalendar
end

post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
          xcconfig_path = config.base_configuration_reference.real_path
          xcconfig = File.read(xcconfig_path)
          xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
          File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
          end
      end	
  end
