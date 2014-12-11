Pod::Spec.new do |s|
  s.name         = "yajl-objc-lowmem"
  s.version      = "0.2.25"
  s.summary      = "Objective-C bindings for YAJL (Yet Another JSON Library) C library, modified to use less memory for large JSON files"
  s.homepage     = "http://lloyd.github.com/yajl"
  s.license      = 'MIT'
  s.author       = { "Gabriel Handford" => "gabrielh@gmail.com" }
  s.source       = { :git => "https://github.com/adamcohenrose/yajl-objc.git", :branch => "master" }
  s.source_files = 'Classes/*.{h,m}', 'Libraries/{GHKit,GTM}/*.{h,m}'
  s.dependency     'yajl', '~>1.0.11'
  s.requires_arc = false
end
