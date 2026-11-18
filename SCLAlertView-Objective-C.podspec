Pod::Spec.new do |spec|
  spec.name         = "SCLAlertView-Objective-C"
  spec.version      = "1.4.3-fmh.1"
  spec.summary      = "Beautiful animated Alert View. Written in Swift but ported to Objective-C"
  spec.homepage     = "https://github.com/ey-veradigm/SCLAlertView-test-fork"
  spec.screenshots  = "https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot.png", "https://raw.githubusercontent.com/dogo/SCLAlertView/master/ScreenShots/ScreenShot2.png"

  spec.license            = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Diogo Autilio" => "diautilio@gmail.com" }
  spec.social_media_url   = "http://twitter.com/di_autilio"
  spec.platform           = :ios
  spec.frameworks         = "UIKit", "AudioToolbox", "Accelerate", "CoreGraphics"
  spec.ios.deployment_target = '12.0'
  spec.source             = { :git => "https://github.com/ey-veradigm/SCLAlertView-test-fork.git", :commit => "b4e1210090d101f8dec04e508fb409ad2481d337" }
  spec.source_files       = "SCLAlertView/*"
  spec.requires_arc       = true
end
