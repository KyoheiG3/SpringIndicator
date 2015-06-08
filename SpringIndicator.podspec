Pod::Spec.new do |s|
  s.name         = "SpringIndicator"
  s.version      = "1.1.4"
  s.summary      = "SpringIndicator is a indicator such as a spring and PullToRefresh."
  s.homepage     = "https://github.com/KyoheiG3/SpringIndicator"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kyohei Ito" => "je.suis.kyohei@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/KyoheiG3/SpringIndicator.git", :tag => s.version.to_s }
  s.source_files  = "SpringIndicator/**/*.{h,swift}"
  s.requires_arc = true
  s.frameworks = "UIKit"
end
