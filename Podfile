# Uncomment the next line to define a global platform for your project
platform :ios, '16.2'

target 'GmmApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for GmmApp
  pod 'SnapKit', '~> 5.6.0'
  pod 'Toast-Swift', '~> 5.0.1'
  pod 'SYBadgeButton'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'
end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2'
               end
          end
   end
end
