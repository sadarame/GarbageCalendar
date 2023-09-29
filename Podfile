# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'GarbageCalendar' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

#  pod 'FSCalendar'

  pod 'RealmSwift'
  
  pod 'Firebase/Analytics'
  
  pod 'Firebase/Messaging'
  
  pod 'FirebaseAnalytics'
  
  pod 'FirebaseMessaging'
  
  pod 'Google-Mobile-Ads-SDK'

  # Pods for GarbageCalendar
  
  post_install do |installer|
    xcode_base_version = `xcodebuild -version | grep 'Xcode' | awk '{print $2}' | cut -d . -f 1`
      # 既存のスクリプトなどで以下が記載されている場合、↑の変数だけ追加すればOK
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # Xcode 15以上で動作します(if内を追記)
        if config.base_configuration_reference && Integer(xcode_base_version) >= 15
          xcconfig_path = config.base_configuration_reference.real_path
          xcconfig = File.read(xcconfig_path)
          xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
          File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
        end
      end
    end
  end


end
