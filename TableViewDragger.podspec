Pod::Spec.new do |s|
  s.name         = "TableViewDragger"
  s.version      = "1.4.0"
  s.summary      = "A cells of UITableView can be rearranged by drag and drop."
  s.homepage     = "https://github.com/KyoheiG3/TableViewDragger"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kyohei Ito" => "je.suis.kyohei@gmail.com" }
  s.swift_version = '4.2'
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/KyoheiG3/TableViewDragger.git", :tag => s.version.to_s }
  s.source_files  = "TableViewDragger/**/*.{h,swift}"
  s.requires_arc = true
  s.frameworks = "UIKit"
end
