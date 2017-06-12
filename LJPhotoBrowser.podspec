Pod::Spec.new do |s|

  s.name         = "LJPhotoBrowser"
  s.version      = "1.0.0"
  s.summary      = "A simple iOS photo and video browser with grid view, captions and selections."

  s.homepage     = "https://github.com/liuliangju/LJPhotoBrowser"
  s.license      = "MIT"
  s.author       = { "liuliangju" => "liangjulliu@163.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/liuliangju/LJPhotoBrowser.git", :tag => s.version.to_s}
  s.source_files  = "LJPhotoBrowser/Classes/*"
  s.requires_arc = true

  s.dependency "DACircularProgress", "~> 2.3.1"
  s.dependency "MBProgressHUD", "~> 1.0.0"
  s.dependency "SDWebImage", "~> 4.0.0"
  s.dependency "SVProgressHUD", "~> 2.1.2"
  s.dependency "SDWebImage/GIF"

end
