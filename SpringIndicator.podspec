Pod::Spec.new do |s|
  s.name         = "SpringIndicator"
  s.version      = "1.5.1"
  s.summary      = "SpringIndicator is a indicator such as a spring and PullToRefresh."
  s.homepage     = "https://github.com/KyoheiG3/SpringIndicator"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kyohei Ito" => "je.suis.kyohei@gmail.com" }
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.source       = { :git => "https://github.com/KyoheiG3/SpringIndicator.git", :tag => s.version.to_s }
  s.source_files  = "SpringIndicator/**/*.{h,swift}"
  s.requires_arc = true
  s.frameworks = "UIKit"
end
